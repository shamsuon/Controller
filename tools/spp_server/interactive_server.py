#!/usr/bin/env python3
"""
Interactive Bluetooth SPP Mock Server
Allows operator to send messages to Flutter app in real-time
Receives and logs all commands from the app
"""
import argparse
import signal
import socket
import subprocess
import sys
import threading
from typing import Optional

try:
    from bluetooth import (
        BluetoothSocket,
        RFCOMM,
        PORT_ANY,
        advertise_service,
        SERIAL_PORT_CLASS,
        SERIAL_PORT_PROFILE,
    )
except ImportError as exc:
    raise SystemExit(
        "Missing dependency: pybluez2\nInstall with: pip install pybluez2\n"
        f"Details: {exc}"
    )

SPP_UUID = "00001101-0000-1000-8000-00805F9B34FB"


class InteractiveSppServer:
    def __init__(
        self,
        service_name: str,
        adapter_addr: Optional[str] = None,
        channel: int = 1,
        send_ready: bool = True,
        force_pybluez: bool = True,
    ):
        self.service_name = service_name
        self.adapter_addr = adapter_addr
        self.channel = channel
        self.send_ready = send_ready
        self.force_pybluez = force_pybluez
        self.server_sock: Optional[BluetoothSocket] = None
        self.client_sock: Optional[BluetoothSocket] = None
        self._running = True
        self._send_lock = threading.Lock()
        self._client_connected = False

    def start(self) -> None:
        """Start the interactive server"""
        while self._running:
            try:
                self.server_sock = self._create_server_socket()
                channel = self.server_sock.getsockname()[1]
                self._register_spp_service(channel)

                print(f"\n{'='*70}")
                print(f"[SPP] Service: {self.service_name}")
                print(f"[SPP] UUID:    {SPP_UUID}")
                print(f"[SPP] Channel: {channel}")
                print(f"[SPP] Waiting for client connection...")
                print(f"{'='*70}\n")

                try:
                    self.client_sock, client_info = self.server_sock.accept()
                    self._client_connected = True
                    self._handle_client(client_info)
                except OSError as e:
                    print(f"[SPP] Accept error: {e}")
                    self._close_resources()
                    if self._running:
                        print("[SPP] Waiting for next client...\n")

            except Exception as e:
                print(f"[SPP] Server error: {e}")
                self._close_resources()
                if self._running:
                    continue

    def _create_server_socket(self):
        """Create RFCOMM socket"""
        bind_addr = self.adapter_addr if self.adapter_addr else ""
        bind_channel = PORT_ANY if self.channel <= 0 else self.channel

        if not self.force_pybluez and hasattr(socket, "AF_BLUETOOTH"):
            try:
                native_addr = self.adapter_addr if self.adapter_addr else "00:00:00:00:00:00"
                native = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
                native.bind((native_addr, bind_channel))
                native.listen(1)
                print("[SPP] Socket: native RFCOMM")
                return native
            except Exception:
                pass

        pyb = BluetoothSocket(RFCOMM)
        pyb.bind((bind_addr, bind_channel))
        pyb.listen(1)
        print("[SPP] Socket: pybluez RFCOMM")
        return pyb

    def _register_spp_service(self, channel: int) -> None:
        """Register SPP service"""
        if hasattr(self.server_sock, "_sock"):
            try:
                advertise_service(
                    self.server_sock,
                    self.service_name,
                    service_id=SPP_UUID,
                    service_classes=[SPP_UUID, SERIAL_PORT_CLASS],
                    profiles=[SERIAL_PORT_PROFILE],
                )
                print("[SPP] Service registered: advertise_service")
                return
            except OSError:
                pass

        try:
            subprocess.run(["sdptool", "del", "SP"], capture_output=True, timeout=5, check=False)
            subprocess.run(["sdptool", "add", f"--channel={channel}", "SP"], capture_output=True, timeout=5, check=False)
            print("[SPP] Service registered: sdptool")
        except Exception:
            print("[SPP] Warning: Service registration may have failed")

    def _handle_client(self, client_info) -> None:
        """Handle a connected client"""
        print(f"\n[SPP] 📱 Client connected: {client_info}")
        
        if self.send_ready:
            self._send_message("READY")

        print(f"\n{'='*70}")
        print("🎮 INTERACTIVE MODE ACTIVE")
        print("Type messages to send to the app. Commands from app appear below.")
        print("Type 'quit' or 'exit' to disconnect and wait for new client.")
        print(f"{'='*70}\n")

        # Start receiver thread
        rx_thread = threading.Thread(target=self._receive_from_client, daemon=True)
        rx_thread.start()

        # Main thread: interactive sender
        self._interactive_sender()

    def _receive_from_client(self) -> None:
        """Continuously receive and print messages from client"""
        if not self.client_sock:
            return

        while self._running and self._client_connected:
            try:
                data = self.client_sock.recv(1024)
                if not data:
                    self._client_connected = False
                    print("\n[SPP] 📴 Client disconnected\n")
                    return

                decoded = data.decode("utf-8", errors="ignore").strip()
                if decoded:
                    commands = [c.strip() for c in decoded.split('\n') if c.strip()]
                    for cmd in commands:
                        if cmd:
                            print(f"📨 [RECEIVED] {cmd}")
            except OSError:
                self._client_connected = False
                print("\n[SPP] 📴 Client disconnected (socket error)\n")
                return

    def _interactive_sender(self) -> None:
        """Interactively send messages to the client"""
        while self._running and self._client_connected:
            try:
                message = input("📤 [SEND] ").strip()

                if not message:
                    continue

                if message.lower() in ['quit', 'exit', 'q']:
                    print("\n[SPP] Disconnecting client...")
                    self._client_connected = False
                    self._close_client()
                    break

                if self._send_message(message):
                    print(f"✅ Sent: {message}")
                else:
                    print(f"❌ Failed to send: {message}")
                    self._client_connected = False
                    break

            except KeyboardInterrupt:
                print("\n\n[SPP] 🛑 Server stopped")
                self.stop()
                break
            except EOFError:
                break

    def _send_message(self, text: str) -> bool:
        """Send a message to the client"""
        if not self.client_sock:
            return False

        payload = f"{text}\n".encode("utf-8")
        try:
            with self._send_lock:
                self.client_sock.sendall(payload)
            return True
        except OSError as e:
            print(f"❌ Send error: {e}")
            return False

    def _close_client(self) -> None:
        """Close client connection"""
        if self.client_sock:
            try:
                self.client_sock.close()
            except OSError:
                pass
            self.client_sock = None
        self._client_connected = False

    def _close_resources(self) -> None:
        """Close all resources"""
        self._close_client()
        if self.server_sock:
            try:
                self.server_sock.close()
            except OSError:
                pass
            self.server_sock = None

    def stop(self) -> None:
        """Stop the server"""
        self._running = False
        self._close_resources()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Interactive Bluetooth SPP Server - Send messages in real-time"
    )
    parser.add_argument("--name", default="SmartHome-SPP-Test", help="Service name")
    parser.add_argument("--adapter", default=None, help="Bluetooth adapter address")
    parser.add_argument("--channel", type=int, default=1, help="RFCOMM channel")
    parser.add_argument("--native", action="store_true", help="Use native socket")
    parser.add_argument("--no-ready", action="store_true", help="Don't send READY")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server = InteractiveSppServer(
        service_name=args.name,
        adapter_addr=args.adapter,
        channel=args.channel,
        send_ready=not args.no_ready,
        force_pybluez=not args.native,
    )

    def handle_signal(_sig: int, _frame: object) -> None:
        print("\n\n[SPP] 🛑 Shutting down...")
        server.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    try:
        server.start()
    except Exception as e:
        print(f"[SPP] Fatal error: {e}")
        return 1
    finally:
        server.stop()

    return 0


if __name__ == "__main__":
    sys.exit(main())
