#!/usr/bin/env python3
"""Does a single UDP flow survive past its first packets on this path? (WireGuard/KCP/QUIC viability)

Receiver (temporary echo, stop it afterwards):
    ssh RELAY 'systemd-run --unit=udpecho -p RuntimeMaxSec=300 /usr/bin/python3 - --serve 51999' < scripts/relay/udp_survival.py
Sender (from another in-country server, or from abroad to test that direction):
    ssh OTHER 'python3 - --probe RELAY_IP 51999' < scripts/relay/udp_survival.py

Prints echoes per 50-packet window. [50, 50, 50, 50, 50, 50] = the flow survives. A pattern like
[3, 0, 0, 0, 0, 0] is the per-flow UDP allowance: the first packets pass, then the flow is dropped.
A 3-packet "echo test" cannot tell these apart, which is why this sends 300 packets on one flow.
"""
import socket, sys, time

def serve(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("0.0.0.0", port))
    while True:
        d, a = s.recvfrom(2048)
        s.sendto(d, a)

def probe(host, port, count=300):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(0.05)
    s.bind(("0.0.0.0", 0))
    windows = [0] * ((count + 49) // 50)
    def drain(deadline):
        while time.time() < deadline:
            try:
                d, _ = s.recvfrom(2048)
                windows[int.from_bytes(d[:4], "big") // 50] += 1
            except socket.timeout:
                return
    for i in range(count):
        s.sendto(i.to_bytes(4, "big") + b"x" * 120, (host, port))
        drain(time.time() + 0.05)
    drain(time.time() + 1.0)
    print(f"{socket.gethostname()[:12]}: echoed per 50-packet window {windows}  total {sum(windows)}/{count}")

if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "--serve":
        serve(int(sys.argv[2]))
    elif len(sys.argv) >= 4 and sys.argv[1] == "--probe":
        probe(sys.argv[2], int(sys.argv[3]))
    else:
        print(__doc__)
