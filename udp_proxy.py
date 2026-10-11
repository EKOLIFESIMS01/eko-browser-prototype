"""One-client loopback UDP impairment relay. Python 3 standard library only.

Start Godot host on 7654. Start this tool on 7761. Join 127.0.0.1:7761.
Use a separate proxy/listen port for each additional client. This delays/drops
actual ENet datagrams, including synchronizer and spawner traffic.
"""
import argparse
import heapq
import itertools
import random
import select
import socket
import time

parser = argparse.ArgumentParser()
parser.add_argument('--listen', type=int, default=7761)
parser.add_argument('--target', type=int, default=7654)
parser.add_argument('--delay', type=float, default=100, help='one-way milliseconds')
parser.add_argument('--jitter', type=float, default=0)
parser.add_argument('--loss', type=float, default=0, help='percentage of datagrams')
parser.add_argument('--seed', type=int, default=42)
args = parser.parse_args()
if not 0 <= args.loss <= 100 or args.delay < 0 or args.jitter < 0:
    parser.error('Use loss 0..100 and nonnegative delay/jitter.')
rng = random.Random(args.seed)
client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client_socket.bind(('127.0.0.1', args.listen))
server_socket.bind(('127.0.0.1', 0))
client = None
pending = []
sequence = itertools.count()
counts = {'client_to_server': 0, 'server_to_client': 0, 'dropped': 0}
window_start = time.monotonic()
print(f'127.0.0.1:{args.listen} -> 127.0.0.1:{args.target}; Ctrl+C stops', flush=True)
try:
    while True:
        now = time.monotonic()
        for source in select.select([client_socket, server_socket], [], [], 0.005)[0]:
            payload, sender = source.recvfrom(65535)
            if source is client_socket:
                if client is not None and sender != client:
                    continue
                client = sender
                output, destination, key = server_socket, ('127.0.0.1', args.target), 'client_to_server'
            else:
                if client is None or sender != ('127.0.0.1', args.target):
                    continue
                output, destination, key = client_socket, client, 'server_to_client'
            if rng.random() * 100 < args.loss:
                counts['dropped'] += 1
                continue
            delay = max(0, args.delay + rng.uniform(-args.jitter, args.jitter)) / 1000
            heapq.heappush(pending, (now + delay, next(sequence), output, destination, payload, key))
        while pending and pending[0][0] <= time.monotonic():
            _, _, output, destination, payload, key = heapq.heappop(pending)
            output.sendto(payload, destination)
            counts[key] += len(payload)
        elapsed = time.monotonic() - window_start
        if elapsed >= 1:
            print('UDP payload B/s: client->server %.0f, server->client %.0f; dropped %d datagrams' %
                  (counts['client_to_server'] / elapsed, counts['server_to_client'] / elapsed, counts['dropped']), flush=True)
            counts = dict.fromkeys(counts, 0)
            window_start = time.monotonic()
except KeyboardInterrupt:
    pass
finally:
    client_socket.close()
    server_socket.close()
