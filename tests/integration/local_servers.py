#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Loopback-only DNS and LDAPS integration fixtures for native dig/ldapsearch.

This is deliberately a minimal protocol fixture, NOT a production DNS/LDAP server.
It accepts no credentials and stores no directory data. It is not shipped by make install.
"""
import argparse
import ipaddress
import socket
import socketserver
import ssl
import struct
import threading


def dns_reply(packet):
    """Reply to one standard A/AAAA IN question. Malformed packets get no reply."""
    if len(packet) < 12 or packet[2] & 0x80 or packet[4:6] != b'\x00\x01':
        return None
    pos = 12
    labels = []
    for _ in range(128):
        if pos >= len(packet):
            return None
        size = packet[pos]
        pos += 1
        if size == 0:
            break
        if size > 63 or pos + size > len(packet):
            return None
        labels.append(packet[pos:pos + size].decode('ascii', errors='replace').lower())
        pos += size
    else:
        return None
    if pos + 4 > len(packet):
        return None
    question = packet[12:pos + 4]
    qtype, qclass = struct.unpack('!HH', packet[pos:pos + 4])
    name = '.'.join(labels)
    nxdomain = name == 'missing.test'
    address = None
    if name == 'good.test' and qclass == 1:
        if qtype == 1:
            address = socket.inet_aton('127.0.0.42')
        elif qtype == 28:
            address = ipaddress.IPv6Address('::1').packed
    # The QR and RA flags are set; use NXDOMAIN only for missing.test.
    flags = 0x8183 if nxdomain else 0x8180
    header = packet[:2] + struct.pack('!HHHHH', flags, 1, 1 if address else 0, 0, 0)
    response = header + question
    if address is not None:
        response += b'\xc0\x0c' + struct.pack('!HHIH', qtype, 1, 60, len(address)) + address
    return response


class DNSHandler(socketserver.BaseRequestHandler):
    def handle(self):
        packet, sock = self.request
        reply = dns_reply(packet)
        if reply is not None:
            sock.sendto(reply, self.client_address)


def tlv(tag, value):
    if len(value) < 128:
        length = bytes([len(value)])
    else:
        raw = len(value).to_bytes((len(value).bit_length() + 7) // 8, 'big')
        length = bytes([0x80 | len(raw)]) + raw
    return bytes([tag]) + length + value


def octet(value):
    return tlv(0x04, value)


def integer(value):
    return tlv(0x02, value.to_bytes(4, 'big').lstrip(b'\x00') or b'\x00')


def ldap_message(message_id, operation, content):
    return tlv(0x30, integer(message_id) + tlv(operation, content))


def ldap_result():
    return b'\x0a\x01\x00' + octet(b'') + octet(b'')


def recv_exact(sock, count):
    data = b''
    while len(data) < count:
        block = sock.recv(count - len(data))
        if not block:
            raise EOFError('peer closed connection')
        data += block
    return data


def read_length(data, offset):
    first = data[offset]
    offset += 1
    if first < 128:
        return first, offset
    count = first & 0x7f
    if count == 0 or count > 4 or offset + count > len(data):
        raise ValueError('invalid BER length')
    return int.from_bytes(data[offset:offset + count], 'big'), offset + count


def read_ldap_request(sock):
    """Extract LDAP message id and application tag; bound packet size."""
    header = recv_exact(sock, 2)
    if header[0] != 0x30:
        raise ValueError('expected LDAP SEQUENCE')
    if header[1] < 0x80:
        size = header[1]
    else:
        count = header[1] & 0x7f
        if not 1 <= count <= 3:
            raise ValueError('unsupported LDAP packet length')
        size = int.from_bytes(recv_exact(sock, count), 'big')
    if size > 65536:
        raise ValueError('LDAP packet too large')
    data = recv_exact(sock, size)
    if len(data) < 4 or data[0] != 0x02:
        raise ValueError('missing LDAP message id')
    length, pos = read_length(data, 1)
    if length < 1 or length > 4 or pos + length >= len(data):
        raise ValueError('invalid LDAP message id')
    message_id = int.from_bytes(data[pos:pos + length], 'big')
    operation_offset = pos + length
    operation = data[operation_offset]
    operation_size, value_offset = read_length(data, operation_offset + 1)
    if value_offset + operation_size != len(data):
        raise ValueError('malformed LDAP operation')
    return message_id, operation, data[value_offset:]


class LDAPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            with self.server.tls_context.wrap_socket(self.request, server_side=True) as client:
                client.settimeout(5)
                for _ in range(8):
                    mid, operation, request = read_ldap_request(client)
                    if operation == 0x60:  # BindRequest [APPLICATION 0]
                        # LDAPv3, empty bind DN and empty simple password only.
                        if request != b'\x02\x01\x03\x04\x00\x80\x00':
                            # Reject authentication attempts; no credentials are accepted.
                            client.sendall(ldap_message(mid, 0x61,
                                b'\x0a\x01\x31' + octet(b'') + octet(b'')))
                            return
                        client.sendall(ldap_message(mid, 0x61, ldap_result()))
                    elif operation == 0x63:  # SearchRequest [APPLICATION 3]
                        # Empty base DN and base scope are mandatory for root DSE.
                        if not request.startswith(b'\x04\x00\x0a\x01\x00'):
                            client.sendall(ldap_message(mid, 0x65,
                                b'\x0a\x01\x35' + octet(b'') + octet(b'')))
                            return
                        # Only the root DSE is exposed. Fixed synthetic metadata.
                        attrs = []
                        for key, value in ((b'supportedLDAPVersion', b'3'),
                                           (b'namingContexts', b'dc=example,dc=test')):
                            attrs.append(tlv(0x30, octet(key) + tlv(0x31, octet(value))))
                        entry = octet(b'') + tlv(0x30, b''.join(attrs))
                        client.sendall(ldap_message(mid, 0x64, entry))
                        client.sendall(ldap_message(mid, 0x65, ldap_result()))
                    elif operation == 0x42:  # UnbindRequest
                        return
                    else:
                        return
        except (OSError, ValueError, EOFError, ssl.SSLError):
            return


class ThreadedDNS(socketserver.ThreadingMixIn, socketserver.UDPServer):
    daemon_threads = True
    allow_reuse_address = False


class ThreadedLDAP(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cert', help='Temporary TLS certificate for LDAPS fixture')
    parser.add_argument('--key', help='Temporary TLS key for LDAPS fixture')
    options = parser.parse_args()
    if bool(options.cert) != bool(options.key):
        parser.error('--cert and --key are required together')
    dns = ThreadedDNS(('127.0.0.1', 0), DNSHandler)
    ldap = None
    if options.cert:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(options.cert, options.key)
        ldap = ThreadedLDAP(('127.0.0.1', 0), LDAPHandler)
        ldap.tls_context = context
    threading.Thread(target=dns.serve_forever, daemon=True).start()
    if ldap is not None:
        threading.Thread(target=ldap.serve_forever, daemon=True).start()
    print('DNS_PORT=%d LDAP_PORT=%d' % (dns.server_address[1], ldap.server_address[1] if ldap else 0), flush=True)
    # Parent test owns lifecycle. Wait for EOF; no background daemon is left behind.
    try:
        while input() != 'quit':
            pass
    except EOFError:
        pass
    finally:
        dns.server_close()
        if ldap:
            ldap.server_close()


if __name__ == '__main__':
    main()
