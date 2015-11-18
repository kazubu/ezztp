#!/usr/bin/env ruby

require 'erb'
require 'ipaddr'
require 'rubygems/user_interaction'
include Gem::UserInteraction

def usage
  puts 'Usage: generate-system-configurations.rb [-s|-f]'
  exit -1
end

def need_root
  if Process::UID.eid != 0
    puts 'This script needs root privilege if write to file.'
    exit -2
  end
end

@interfaces = {}
@output = nil

puts 'Initial Setup for EzZTP'

if ARGV.length == 1
  if ARGV[0] == '-s'
    @output = :stdout
  elsif ARGV[0] == '-f'
    @output = :file
  end
end

usage if @output.nil?
need_root if @output == :file

puts 'Network Configuration:'
puts 'Interface mapping: eth0 is Public network. eth1 is ZTP network.'
puts 'Please ask following questions.'

intf = 'eth0'
if_type = nil
if_address = nil
if_netmask = nil

while(true)
  if_type = ui.ask("#{intf} type? (dhcp/static) :")
  if (if_type == 'dhcp' || if_type == 'static')
    if_type = if_type.to_sym
    break
  else
    puts 'Input is invalid.'
  end
end
@interfaces[intf] = {}
@interfaces[intf][:type] = if_type

if if_type == :static
  while(true)
    if_addr = ui.ask("#{intf} address? (x.x.x.x) :")
    begin
      raise 'err' if if_addr.index('/')
      ipaddr = IPAddr.new(if_addr, Socket::AF_INET)
      if_addr = ipaddr.to_s
      break
    rescue
      puts 'Input is invalid.'
    end
  end
  @interfaces[intf][:address] = if_addr
  while(true)
    if_netmask = ui.ask("#{intf} netmask? (x.x.x.x) :")
    begin
      ipaddr = IPAddr.new(if_addr+'/'+if_netmask, Socket::AF_INET)
      raise 'err' if(ipaddr.to_s == if_addr)
      break
    rescue
      puts 'Input is invalid.'
    end
  end
  @interfaces[intf][:netmask] = if_netmask
end

intf = 'eth1'
if_type = :static
if_address = nil
if_netmask = nil

puts 'Interface mode of eth1 is static only...'
@interfaces[intf] = {}
@interfaces[intf][:type] = if_type

if if_type == :static
  while(true)
    if_addr = ui.ask("#{intf} address? (x.x.x.x) :")
    begin
      raise 'err' if if_addr.index('/')
      ipaddr = IPAddr.new(if_addr, Socket::AF_INET)
      if_addr = ipaddr.to_s
      break
    rescue
      puts 'Input is invalid.'
    end
  end
  @interfaces[intf][:address] = if_addr
  while(true)
    if_netmask = ui.ask("#{intf} netmask? (x.x.x.x) :")
    begin
      ipaddr = IPAddr.new(if_addr+'/'+if_netmask, Socket::AF_INET)
      raise 'err' if(ipaddr.to_s == if_addr)
      break
    rescue
      puts 'Input is invalid.'
    end
  end
  @interfaces[intf][:netmask] = if_netmask
end

@ztp_ifname = 'eth1'
@ztp_server_ip = @interfaces[@ztp_ifname][:address]
@netmask = @interfaces[@ztp_ifname][:netmask]
@prefixlen = IPAddr.new(@netmask).to_i.to_s(2).count("1")
@network = IPAddr.new(@ztp_server_ip+"/"+@netmask, Socket::AF_INET).to_s

@pool_range = []
@default_router = nil

while(true)
  @pool_range[0] = ui.ask("DHCP Temporary pool Start IP? (x.x.x.x) :")
  @pool_range[1] = ui.ask("DHCP Temporary pool End IP? (x.x.x.x) :")

  begin
    r1 = IPAddr.new(@pool_range[0], Socket::AF_INET)
    r2 = IPAddr.new(@pool_range[1], Socket::AF_INET)
    subnet = IPAddr.new(@network+'/'+@netmask, Socket::AF_INET) 
    raise 'err' if r1 >= r2
    raise 'err' if !(subnet.include?(r1) && subnet.include?(r2))
    @pool_range[0] = r1.to_s
    @pool_range[1] = r2.to_s
    break
  rescue
    puts 'Input is invalid.'
  end
end

while(true)
  @default_router = ui.ask("Default router of ZTP network? (x.x.x.x) :")
  begin
    raise 'err' if @default_router.index('/')
    ipaddr = IPAddr.new(@default_router, Socket::AF_INET)
    subnet = IPAddr.new(@network+'/'+@netmask, Socket::AF_INET) 
    raise 'err' if !subnet.include?(ipaddr)
    @default_router = ipaddr.to_s
    break
  rescue
    puts 'Input is invalid.'
  end
end

while(true)
  @dns_server = ui.ask("DNS Server of ZTP network? (x.x.x.x) :")
  begin
    raise 'err' if @dns_server.index('/')
    ipaddr = IPAddr.new(@dns_server, Socket::AF_INET)
    @dns_server = ipaddr.to_s
    break
  rescue
    puts 'Input is invalid.'
  end
end

ezztp_default_config_tmpl = File.read('ezztp_default_config.erb')
ezztp_default_config = ERB.new(ezztp_default_config_tmpl, nil, '%').result(binding)

interfaces_config_tmpl = File.read('interfaces.erb')
interfaces_config = ERB.new(interfaces_config_tmpl, nil, '%').result(binding)

if @output == :file
  File.write("/home/ezztp/ezztp/config/ezztp_default_config.rb", ezztp_default_config)
  File.write("/etc/network/interfaces", interfaces_config)
elsif @output == :stdout
  puts 'ezztp_default_config.rb:'
  puts ezztp_default_config
  puts
  puts 'interfaces:'
  puts interfaces_config
end


