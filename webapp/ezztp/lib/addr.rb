def get_addr(base, plen, fpc,port)
  base_addr = IPAddr.new(base)

  add_addr = (fpc*48) + port
  add_addr += 1 if IPAddr.new(base).to_i == IPAddr.new(base+'/'+plen).to_i
  # third = (((fpc*48) + port + 1)/256).to_i
  # fourth = (((fpc*48) + port + 1)%256).to_i

  return IPAddr.new(base_addr.to_i + add_addr, Socket::AF_INET).to_s + '/' + plen
end

