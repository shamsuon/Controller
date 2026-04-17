#!/usr/bin/env python3
import argparse
import signal
import socket
import subprocess
import sys
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


class SppDeviceEmulator:
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

    def start(self) -> None:
        self.server_sock = self._create_server_socket()

        channel = self.server_sock.getsockname()[1]
        self._register_spp_service(channel)

        print(f"[SPP] Service: {self.service_name}")
        print(f"[SPP] UUID:    {SPP_UUID}")
        print(f"[SPP] Channel: {channel}")
        print("[SPP] Waiting for one client only...")

        try:
            self.client_sock, client_info = self.server_sock.accept()
        except OSError:
            return

        print(f"[SPP] Client connected: {client_info}")
        try:
            if self.send_ready:
                self._send_line("READY")
            self._client_loop()
        except OSError as exc:
            print(f"[SPP] Client session error: {exc}")
        finally:
            self._close_client()
            self.stop()
            print("[SPP] Client disconnected. Server stopped (single-client mode).")

    def _create_server_socket(self):
        bind_addr = self.adapter_addr if self.adapter_addr else "00:00:00:00:00:00"
        bind_channel = PORT_ANY if self.channel <= 0 else self.channel

        # Prefer Linux native RFCOMM socket; pybluez send() can fail with EFAULT
        # on some stacks while recv() still works.
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

        # Fallback to pybluez socket when native RFCOMM is unavailable.
        pyb = BluetoothSocket(RFCOMM)
        pyb.bind((bind_addr, bind_channel))
        pyb.listen(1)
        print("[SPP] Data socket: pybluez RFCOMM")
        return pyb

    def _register_spp_service(self, channel: int) -> None:
        # advertise_service works only with pybluez socket objects.
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

        # Fallback for systems where pybluez advertisement fails.
        # This requires bluez tools and usually root permissions.
        # FIRST: Try to clear any existing serial port record to avoid conflicts
        subprocess.run(["sdptool", "del", "SP"], capture_output=True, check=False)
        
        result = subprocess.run(
            ["sdptool", "add", f"--channel={channel}", "SP"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            # Some BlueZ builds reject --channel=... syntax; retry without it.
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

    def stop(self) -> None:
        self._running = False
        self._close_client()
        if self.server_sock:
            try:
                self.server_sock.close()
            except OSError:
                pass
            self.server_sock = None

    def _close_client(self) -> None:
        if self.client_sock:
            try:
                self.client_sock.close()
            except OSError:
                pass
            self.client_sock = None

    def _client_loop(self) -> None:
        if not self.client_sock:
            return

        while self._running:
            try:
                data = self.client_sock.recv(1024)
            except OSError as exc:
                print(f"[SPP] Socket error: {exc}")
                return

            if not data:
                return

            decoded = data.decode("utf-8", errors="ignore")
            commands = [token.strip() for token in decoded.replace("\r", "\n").split("\n") if token.strip()]
            if not commands:
                # Fallback for single-token packets that do not include separators.
                compact = decoded.strip()
                if compact:
                    commands = [compact]

            for cmd in commands:
                print(f"[RX] {cmd}")
                response = self._inverse_response(cmd)
                self._delayed_send(response, 5)

    def _send_line(self, text: str) -> bool:
        if not self.client_sock:
            return False
        payload = f"{text}\n".encode("utf-8")
        try:
            self.client_sock.sendall(payload)
            return True
        except OSError as exc:
            print(f"[SPP] Send failed: {exc}")
            return False

    def _delayed_send(self, response: str, delay_seconds: int) -> None:
        time.sleep(delay_seconds)
        if not self._running or not self.client_sock:
            return
        sent = self._send_line(response)
        if sent:
            print(f"[TX +{delay_seconds}s] {response}")
        else:
            print(f"[SPP] Dropped delayed response: {response}")

    @staticmethod
    def _inverse_response(cmd: str) -> str:
        table = {
            "A": "L1_OFF",
            "a": "L1_ON",
            "B": "L2_OFF",
            "b": "L2_ON",
            "C": "L3_OFF",
            "c": "L3_ON",
            "D": "L4_OFF",
            "d": "L4_ON",
            "F": "FAN_OFF",
            "f": "FAN_ON",
            "R0": "RACK_90",
            "R1": "RACK_180",
            "R2": "RACK_0",
            "O": "DOOR_OPEN",
            "X": "DOOR_CLOSE",
            
        }
        return table.get(cmd, f"UNKNOWN:{cmd}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bluetooth Classic SPP test server.")
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
    parser.add_argument(
        "--native",
        action="store_true",
        help="Use native Linux RFCOMM socket instead of pybluez (requires sudo for SDP).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server = SppDeviceEmulator(
        service_name=args.name,
        adapter_addr=args.adapter,
        channel=args.channel,
        send_ready=not args.no_ready,
    )

    def handle_signal(_sig: int, _frame: object) -> None:
        print("\n[SPP] Stopping server...")
        server.stop()

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    try:
        server.start()
    except (socket.error, OSError) as exc:
        print(f"[SPP] Failed to start: {exc}")
        return 1
    finally:
        server.stop()

    return 0


if __name__ == "__main__":
    sys.exit(main())
