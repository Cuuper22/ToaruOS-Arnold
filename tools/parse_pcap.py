import struct, sys

f = open('build/net.pcap', 'rb')
magic, vmaj, vmin, tz, sigfigs, snaplen, linktype = struct.unpack('<IHHiIII', f.read(24))
print(f'PCAP: magic={hex(magic)}, link={linktype}')

pkt_num = 0
while True:
    hdr = f.read(16)
    if len(hdr) < 16:
        break
    ts_sec, ts_usec, incl_len, orig_len = struct.unpack('<IIII', hdr)
    data = f.read(incl_len)
    pkt_num += 1
    
    dst_mac = ':'.join(f'{b:02x}' for b in data[0:6])
    src_mac = ':'.join(f'{b:02x}' for b in data[6:12])
    ethertype = struct.unpack('!H', data[12:14])[0]
    
    if ethertype == 0x0806:
        arp_op = struct.unpack('!H', data[20:22])[0]
        op_str = "Request" if arp_op == 1 else "Reply"
        print(f'Pkt {pkt_num}: ARP {op_str} len={orig_len}')
    elif ethertype == 0x0800:
        proto = data[23]
        src_ip = '.'.join(str(b) for b in data[26:30])
        dst_ip = '.'.join(str(b) for b in data[30:34])
        ip_total = struct.unpack('!H', data[16:18])[0]
        
        if proto == 6:
            src_port = struct.unpack('!H', data[34:36])[0]
            dst_port = struct.unpack('!H', data[36:38])[0]
            seq = struct.unpack('!I', data[38:42])[0]
            ack_num = struct.unpack('!I', data[42:46])[0]
            data_offset = (data[46] >> 4) * 4
            flags = data[47]
            tcp_cksum = struct.unpack('!H', data[50:52])[0]
            
            flag_list = []
            if flags & 0x02: flag_list.append('SYN')
            if flags & 0x10: flag_list.append('ACK')
            if flags & 0x08: flag_list.append('PSH')
            if flags & 0x01: flag_list.append('FIN')
            if flags & 0x04: flag_list.append('RST')
            
            payload_start = 14 + 20 + data_offset
            payload_len = len(data) - payload_start if payload_start < len(data) else 0
            
            direction = ">>>" if src_ip == "10.0.2.15" else "<<<"
            flag_str = "|".join(flag_list)
            print(f'Pkt {pkt_num} {direction}: TCP {src_ip}:{src_port} -> {dst_ip}:{dst_port} [{flag_str}] seq={seq} ack={ack_num} doff={data_offset} payload={payload_len} cksum={hex(tcp_cksum)}')
            
            if payload_len > 0:
                payload = data[payload_start:payload_start+min(payload_len, 80)]
                try:
                    print(f'         Data: {payload.decode("ascii", errors="replace")[:80]}')
                except:
                    print(f'         Data: {payload.hex()[:80]}')
        else:
            print(f'Pkt {pkt_num}: IPv4 proto={proto} {src_ip} -> {dst_ip}')
    else:
        print(f'Pkt {pkt_num}: EtherType={hex(ethertype)} len={orig_len}')

f.close()
print(f'\nTotal packets: {pkt_num}')
