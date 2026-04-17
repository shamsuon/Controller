#!/usr/bin/env python3
"""
Interactive Bluetooth SPP Mock Server with Threading
- Passive receiving: auto-print incoming commands
- Active sending: operator types input at any time
- Both modes run concurrently via threading
"""
import argparse
import signal
import socket
import subprocess
import sys
import threading
import time
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
        "Missing dependency: pybluez2\n"
        "Install with: pip install pybluez2\n"
        f"Details: {exc}"
    )


SPP_UUID = "00001101-0000-1000-8000-00805F9B34FB"


class InteractiveSppServer:
    def __init__(
        self,
        service_name: str,
        adapter_addr: Optional[str],
        channel: int,
        send_ready: bool = True,
    ) -> None:
        self.service_name = service_name
        self.adapter_addr = adapter_addr
        self.channel = channel
        self.send_ready = send_ready
        self.server_sock: Optional[BluetoothSocket] = None
        self.client_sock: Optional[BluetoothSocket] = None
        self._running = True
        self._client_connected_event = threading.Event()

    def start(self) -> None:
        """Start server and accept connections indefinitely"""
        self.server_sock = self._create_server_socket()
        channel = self.server_sock.getsockname()[1]
        self._register_spp_service(channel)

        print(f"[SPP] Service: {self.service_name}")
        print(f"[SPP] UUID:    {SPP_UUID}")
        print(f"[SPP] Channel: {channel}")
        print("[SPP] Listening for client connections (interactive mode)...")

        while self._running:
            try:
                self.client_sock, client_info = self.server_sock.accept()
                print(f"\n[SPP] Client connected: {client_info}")
                
                if self.send_ready:
                    self._send_line("READY")
                
                # Set event to signal client is connected
                self._client_connected_event.set()
                
                # Start receive thread for this client
                receive_thread = threading.Thread(
                    target=self._receive_loop,
                    daemon=True,
                    name="ReceiveThread"
                )
                receive_thread.start()
                
                # Wait for client disconnection
                receive_thread.join()
                
            except OSError as exc:
                if self._running:
                    print(f"[SPP] Accept error: {exc}")
                    time.sleep(1)  # Brief pause before retry
            finally:
                self._client_connected_event.clear()
                self._close_client()

    def _create_server_socket(self):
        """Create and configure Bluetooth RFCOMM socket"""
        bind_addr = self.adapter_addr if self.adapter_addr else "00:00:00:00:00:00"
        bind_channel = PORT_ANY if self.channel <= 0 else self.channel

        if hasattr(socket, "AF_BLUETOOTH") and hasattr(socket, "BTPROTO_RFCOMM"):
            native = socket.socket(
                socket.AF_BLUETOOTH,
                socket.SOCK_STREAM,
                socket.BTPROTO_RFCOMM,
            )
            native.bind((bind_addr, bind_channel))
            native.listen(1)
            print("[SPP] Data socket: native RFCOMM")
            return native

        pyb = BluetoothSocket(RFCOMM)
        pyb.bind((bind_addr, bind_channel))
        pyb.listen(1)
        print("[SPP] Data socket: pybluez RFCOMM")
        return pyb

    def _register_spp_service(self, channel: int) -> None:
        """Register SPP service via pybluez or sdptool"""
        if hasattr(self.server_sock, "_sock"):
            try:
                advertise_service(
                    self.server_sock,
                    self.service_name,
                    service_id=SPP_UUID,
                    service_classes=[SPP_UUID, SERIAL_PORT_CLASS],
                    profiles=[SERIAL_PORT_PROFILE],
                )
                print("[SPP] Service registration: pybluez advertise_service")
                return
            except OSError as exc:
                print(f"[SPP] advertise_service failed: {exc}")
                print("[SPP] Trying BlueZ fallback: sdptool add SP ...")
        else:
            print("[SPP] Service registration: native socket detected, using sdptool")

        subprocess.run(["sdptool", "del", "SP"], capture_output=True, check=False)
        
        result = subprocess.run(
            ["sdptool", "add", f"--channel={channel}", "SP"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            retry = subprocess.run(
                ["sdptool", "add", "SP"],
                capture_output=True,
                text=True,
                check=False,
            )
            if retry.returncode != 0:
                stderr = (retry.stderr or result.stderr or "").strip()
                stdout = (retry.stdout or result.stdout or "").strip()
                raise OSError(
                    "Unable to register SPP service via pybluez or sdptool. "
                    f"sdptool rc={retry.returncode}, stdout='{stdout}', stderr='{stderr}'"
                )

        print("[SPP] Service registration: sdptool fallback")

    def _receive_loop(self) -> None:
        """PASSIVE MODE: Receive and print incoming commands"""
        if not self.client_sock:
            return

        while self._running and self._client_connected_event.is_set():
            try:
                data = self.client_sock.recv(1024)
                if not data:
                    print("[SPP] Client disconnected (recv returned empty)")
                    break

                decoded = data.decode("utf-8", errors="ignore").strip()
                if decoded:
                    # Parse multiple commands separated by newlines
                    commands = [cmd.strip() for cmd in decoded.split("\n") if cmd.strip()]
                    for cmd in commands:
                        print(f"[RECEIVED]: {cmd}")

            except OSError as exc:
                if self._running:
                    print(f"[SPP] Receive error: {exc}")
                break

    def _input_loop(self) -> None:
        """ACTIVE MODE: Operator type commands and send immediately"""
        print("\n[SPP] === INTERACTIVE MODE ===")
        print("[SPP] Type commands and press Enter to send.")
        print("[SPP] Type 'quit' to stop.\n")

        while self._running:
            try:
                message = input()
                
                if message.lower() in ["quit", "exit", "q"]:
                    print("[SPP] Stopping server...")
                    self._running = False
                    break

                if self._client_connected_event.is_set():
                    if self._send_line(message):
                        print(f"[SENT]: {message}")
                    # else send_line already printed error
                else:
                    print("[SPP] No client connected. Waiting for connection...")

            except KeyboardInterrupt:
                print("\n[SPP] Interrupt received. Stopping...")
                self._running = False
                break
            except EOFError:
                # Happens when stdin is closed
                break

    def _send_line(self, text: str) -> bool:
        """Send line to connected client"""
        if not self.client_sock or not self._client_connected_event.is_set():
            print("[SPP] No client connected. Message not sent.")
            return False

        payload = f"{text}\n".encode("utf-8")
        try:
            self.client_sock.sendall(payload)
            return True
        except OSError as exc:
            print(f"[SPP] Send failed: {exc}")
            return False

    def _close_client(self) -> None:
        """Close client socket"""
        if self.client_sock:
            try:
                self.client_sock.close()
            except OSError:
                pass
            self.client_sock = None

    def stop(self) -> None:
        """Stop server"""
        self._running = False
        self._client_connected_event.clear()
        self._close_client()
        if self.server_sock:
            try:
                self.server_sock.close()
            except OSError:
                pass
            self.server_sock = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Interactive Bluetooth Classic SPP mock server."
    )
    parser.add_argument(
        "--name",
        default="SmartHome-SPP-Test",
        help="Advertised Bluetooth service name.",
    )
    parser.add_argument(
        "--adapter",
        default=None,
        help="Optional local adapter address (example: 11:22:33:44:55:66).",
    )
    parser.add_argument(
        "--channel",
        type=int,
        default=1,
        help="RFCOMM channel to bind (default: 1). Use 0 for auto.",
    )
    parser.add_argument(
        "--no-ready",
        action="store_true",
        help="Do not send initial READY message after client connects.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server = InteractiveSppServer(
        service_name=args.name,
        adapter_addr=args.adapter,
        channel=args.channel,
        send_ready=not args.no_ready,
    )

    def handle_signal(_sig: int, _frame: object) -> None:
        print("\n[SPP] Signal received. Stopping server...")
        server.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    try:
        # Start input thread
        input_thread = threading.Thread(
            target=server._input_loop,
            daemon=False,
            name="InputThread"
        )
        input_thread.start()

        # Main thread handles connections
        server.start()
        
        # Wait for input thread to finish
        input_thread.join(timeout=1)

    except (socket.error, OSError) as exc:
        print(f"[SPP] Failed to start: {exc}")
        return 1
    finally:
        server.stop()

    return 0


if __name__ == "__main__":
    sys.exit(main())
