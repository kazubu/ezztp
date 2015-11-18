#!/usr/bin/env ruby
require 'ipaddr'

THIRD_OFFSET = 0
FOURTH_OFFSET = 0

def usage
  puts "Usage: getaddr.rb [BASEADDR] [IFD]"
  puts "ex) getaddr.rb ge-7/0/2"
  exit -1
end

def get_addr(base, fpc,port)
  base_addr = IPAddr.new(base, Socket::AF_INET)

  add_addr = (fpc*48) + port + 1
  # third = (((fpc*48) + port + 1)/256).to_i
  # fourth = (((fpc*48) + port + 1)%256).to_i

  return IPAddr.new(base_addr.to_i + add_addr, Socket::AF_INET)
end

def main(argv)
  usage if argv.length != 2
  argv[1] =~ /[gx]e-(\d+)\/(\d+)\/(\d+).*/
  fpc,pic,port = $1.to_i,$2.to_i,$3.to_i

  addr = get_addr(argv[0], fpc, port)
  puts addr.to_s
end

main ARGV
