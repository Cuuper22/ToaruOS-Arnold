import struct

f = open('build/net.pcap', 'rb')
f.read(24)  # global header

for i in range(6):
    hdr = f.read(16)
    ts_sec, ts_usec, incl_len, orig_len = struct.unpack('<IIII', hdr)
    data = f.read(incl_len)
    
    if i >= 2:  # packets 3-6 (TCP)
        src_ip = data[26:30]
        dst_ip = data[30:34]
        tcp_start = 34
        tcp_len = len(data) - tcp_start
        
        tcp_data = bytearray(data[tcp_start:])
        stored_cksum = struct.unpack('!H', tcp_data[16:18])[0]
        tcp_data[16] = 0
        tcp_data[17] = 0
        
        pseudo = src_ip + dst_ip + b'\x00\x06' + struct.pack('!H', tcp_len)
        total = pseudo + bytes(tcp_data)
        if len(total) % 2:
            total += b'\x00'
        
        s = 0
        for j in range(0, len(total), 2):
            s += struct.unpack('!H', total[j:j+2])[0]
        while s >> 16:
            s = (s & 0xFFFF) + (s >> 16)
        computed = (~s) & 0xFFFF
        
        flags = data[47]
        flag_str = ""
        if flags & 0x02: flag_str += "SYN "
        if flags & 0x10: flag_str += "ACK "
        if flags & 0x08: flag_str += "PSH "
        
        src_port = struct.unpack('!H', data[34:36])[0]
        dst_port = struct.unpack('!H', data[36:38])[0]
        
        match = "OK" if stored_cksum == computed else "MISMATCH"
        print(f"Pkt {i+1}: {flag_str.strip()} stored={hex(stored_cksum)} computed={hex(computed)} {match}")
        
        # Also verify IP checksum
        ip_data = bytearray(data[14:34])
        stored_ip_cksum = struct.unpack('!H', ip_data[10:12])[0]
        ip_data[10] = 0
        ip_data[11] = 0
        s2 = 0
        for j in range(0, 20, 2):
            s2 += struct.unpack('!H', ip_data[j:j+2])[0]
        while s2 >> 16:
            s2 = (s2 & 0xFFFF) + (s2 >> 16)
        ip_computed = (~s2) & 0xFFFF
        ip_match = "OK" if stored_ip_cksum == ip_computed else "MISMATCH"
        print(f"       IP cksum: stored={hex(stored_ip_cksum)} computed={hex(ip_computed)} {ip_match}")

f.close()
