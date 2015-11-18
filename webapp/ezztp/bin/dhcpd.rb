#!/usr/bin/env ruby

' Copyright (c) 2015, Kazuki Shimizu
 All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Kazuki Shimizu nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY Kazuki Shimizu ``AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL Kazuki Shimizu BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 The original code of this program was wrote by Tony Ivanov. (https://gist.github.com/telamon/984041)
 Here is the original copyright notice:

 Copyright (c) 2007, Tony Ivanov
 All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Tony Ivanov nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY Tony Ivanov ``AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL Tony Ivanov BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

require 'ipaddr'

class EzDHCPd

  #Message types
  # http://www.iana.org/assignments/bootp-dhcp-parameters
  DHCPDISCOVER = 1
  DHCPOFFER=2
  DHCPREQUEST=3
  DHCPDECLINE=4
  DHCPACK=5
  DHCPNAK=6
  DHCPRELEASE=7
  DHCPINFORM=8
  DHCPFORCERENEW=9
  DHCPLEASEQUERY=10
  DHCPLEASEUNASSIGNED=11
  DHCPLEASEUNKNOWN=12
  DHCPLEASEACTIVE=13

  # other settings.
  HPORT = 67
  CPORT = 68
  MAXRECVLEN  = 1500

  class BootpPacket
    attr_accessor :op,:htype,:hlen,:hops,:xid,:secs,:flags,:ciaddr,:yiaddr,:nsiaddr,:radder,:macaddr,:cookie,:options
    def parse(d)
      @op,@htype,@hlen,@hops,@xid,@secs,@flags,@ciaddr,@yiaddr,@nsiaddr,@radder,@macaddr,@cookie,tmpOptions  = d.unpack("C4NnnN4a6x202Na*")
      @options={}
      offset =0 
      while offset != -1    
        oid,len=tmpOptions.unpack("@"+ offset.to_s + "C2")
        break if oid == 0xff

        value=tmpOptions.unpack("@" + (offset+2).to_s + "a" + len.to_s)
        value = value[0]
        offset += len+2
        case oid
          when 0xff 
            offset = -1
          when 12
            @options[:hostname] = value
          when 53
            @options[:message_type] = value.unpack("C")[0]
          when 61
            #i'm ignoring this option for now, i assumed it's a dupe of macaddr and htype.
            @options[:htype_mac] = value
          when 55
            @options[:requests] = value.unpack("C*")
          when 50
            @options[:address_request] = value.unpack("CCCC")
          when 51
            # lease_time
          when 54
            @options[:dhcp_server] = value.unpack("CCCC")
          when 56 
            # It's a message!! =D
            logger.info "DHCPD: MSG: " + value
          when 60
            @options[:vendor_class_identifier] = value
          when 82
            @options[:agent_information] = {}
            soffset = 0
            while soffset != -1
              soid, slen = value.unpack("@" + soffset.to_s + "C2")
              svalue = value.unpack("@" + (soffset + 2).to_s + "a" + slen.to_s)[0]
              case soid
                when 1
                  @options[:agent_information][:agent_circuit_id] = svalue
                when 2
                  @options[:agent_information][:agent_remote_id] = svalue
                when 6
                  @options[:agent_information][:subscriber_id] = svalue
                else logger.warn "DHCPD: Unknown dhcp suboption of Agent Information:" + soid.to_s + " value: " + svalue.inspect
              end
              soffset += slen + 2
              break if soffset >= len
            end
          else logger.warn "DHCPD: Unkown dhcp option! Id:"+ oid.to_s + " value: " + value.inspect
        end
      end 
    end

    def ipstr_to_ary(str)
      str.to_s.split('.').map{|i|i.to_i}
    end

    def new()
    end

    def macf
      @macaddr.unpack("HXhHXhHXhHXhHXhHXh").join.gsub(/([0-9a-f][0-9a-f])/i,':\1').sub(":","")
    end

    def toPacket()
      ret = [@op,@htype,@hlen,@hops,@xid,@secs,@flags,@ciaddr,@yiaddr,@nsiaddr,@radder,@macaddr,@cookie].pack("C4NnnN4a6x202N")
      @options.each do |key|
        case key[0]
          when :message_type          
            ret+= [53,1,key[1]].pack("CCC")
          when :subnet_mask
            tmp = ipstr_to_ary key[1]
            ret+= [1,4].pack("CC")
            ret+= tmp.pack("CCCC")
          when :router
            tmp = ipstr_to_ary key[1]
            ret+= [3,4].pack("CC")
            ret+= tmp.pack("CCCC") 
          when :lease_time
            ret+= [51,4,key[1]].pack("CCN")
          when :dhcp_server
            tmp = ipstr_to_ary key[1]
            ret+= [54,4].pack("CC")
            ret+= tmp.pack("CCCC") 
          when :dns_server
            tmp = ipstr_to_ary key[1]
            ret+= [6,4].pack("CC")
            ret+= tmp.pack("CCCC") 
          when :tftp_server
            tmp = ipstr_to_ary key[1]
            ret+= [150,4].pack("CC")
            ret+= tmp.pack("CCCC") 
          when :juniper_ztp
            tmp = ""
            key[1].each{|k|
              tmp += [k[0], k[1].length].pack("CC")
              tmp += [k[1]].pack("a*")
            }
            ret += [43, tmp.length].pack("CC")
            ret += tmp
          else logger.warn "DHCPD: Unknown Option: " + key[0].to_s
        end
      end
      ret + [255].pack("C")
    end
  end

  def ipstr_to_ary(str)
    str.to_s.split('.').map{|i|i.to_i}
  end

  def get_addr(num)
    start = IPAddr.new(@lease_start, Socket::AF_INET)
    start = IPAddr.new(start.to_i + num, Socket::AF_INET)
    start.to_s
  end

  def get_num(_ip)
    ip = IPAddr.new(_ip, Socket::AF_INET)
    start = IPAddr.new(@lease_start, Socket::AF_INET)
    ip.to_i - start.to_i
  end

  def whois(mac)
    (0..@lease_max_addr).each do |i| 
      if @database[i] == mac
        return i
      end
    end
    nil
  end

  def whois_ip(_ip)
    return @database[get_num(_ip)]
  end

  def get_lease_ip(ip, mac)
    num = get_num(ip)
    if @database[num].nil?
      @database[num] = mac
      return num
    else
      return false
    end
  end

  def get_lease(mac)   
    if @database.member?(mac)
      return whois(mac)
    end
    (0..@lease_max_addr).each do |i| 
      if @database[i] == nil
        @database[i] = mac
        return i
      end
    end
    nil
  end

  def juniper_ztp_option_gen(packet)
    if (!packet.options[:agent_information].nil? && 
        !packet.options[:agent_information][:subscriber_id].nil? && 
        !packet.options[:agent_information][:agent_circuit_id].nil? && 
        !packet.options[:vendor_class_identifier].nil? )

      juniper_identifier = ""
      juniper_identifier += packet.macf.gsub(':','') + '!'
      juniper_identifier += packet.options[:agent_information][:subscriber_id] + "!"
      juniper_identifier += packet.options[:agent_information][:agent_circuit_id].split(':')[0] + "!"
      juniper_identifier += packet.options[:vendor_class_identifier].gsub("\0",'').gsub('Juniper-','') + "!"
      juniper_identifier += packet.options[:hostname] unless packet.options[:hostname].nil?

      file_name = 'i?p=' + juniper_identifier + '!/i.tgz'
      config_name =  'c?p=' + juniper_identifier + '!/c'

      return [[0, file_name], [1, config_name], [3, 'http']]
    else
      err = 'DHCPD: packet is not match for criteria to generate ztp options.'
      err += "agent_information: #{(!packet.options[:agent_information].nil?).to_s}"
      err += "  subscriber_id: #{(!packet.options[:agent_information][:subscriber_id].nil?).to_s}" unless packet.options[:agent_information].nil?
      err += "  agent_circuit_id: #{(!packet.options[:agent_information][:agent_circuit_id].nil?).to_s}" unless packet.options[:agent_information].nil?
      err += "  vendor_class_identifier: #{(!packet.options[:vendor_class_identifier].nil?).to_s}"
      logger.error err
      return nil
    end
  end

  def main
    Dir.chdir(File.dirname(__FILE__)+'/..')

    if_name = GlobalConfiguration.find_by(name: 'dhcp_server_interface').value.to_s
    interface = GlobalConfiguration.find_by(name: 'ztp_server_address').value.to_s
    management_segment = GlobalConfiguration.find_by(name: 'management_segment').value.to_s 
    mask = IPAddr.new('255.255.255.255').mask(management_segment.split('/')[1].to_i).to_s
    gateway = GlobalConfiguration.find_by(name: 'management_default_gateway').value.to_s
    dns = GlobalConfiguration.find_by(name: 'management_dns_server').value.to_s
    leasetime = 60*30 # 30 min

    @lease_start = GlobalConfiguration.find_by(name: 'dhcp_lease_start').value.to_s
    @lease_end = GlobalConfiguration.find_by(name: 'dhcp_lease_end').value.to_s

    #calculate network/broadcast
    #
    _ipaddr = IPAddr.new(interface+'/'+mask, Socket::AF_INET)

    network = ipstr_to_ary(_ipaddr)
    broadcast = '255.255.255.255'
    logger.info "DHCPD: Network: " + network.join('.')
    logger.info "DHCPD: Broadcast: " + broadcast

    _ipaddr = nil

    _ipaddr_s = IPAddr.new(@lease_start, Socket::AF_INET)
    _ipaddr_e = IPAddr.new(@lease_end, Socket::AF_INET)

    @lease_max_addr = _ipaddr_e.to_i - _ipaddr_s.to_i

    _ipaddr_s = nil
    _ipaddr_e = nil

    @database = []

    # program start.
    require 'socket'
    soc = UDPSocket.new
    soc.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR | Socket::SO_BROADCAST, 1 ) 
    soc.setsockopt( Socket::SOL_SOCKET, Socket::SO_BINDTODEVICE, if_name)
    logger.info "DHCPD: binding: ...." + soc.bind('0.0.0.0',HPORT).to_s
    loop do
      data,meta = soc.recvfrom(MAXRECVLEN)
      packet = BootpPacket.new
      packet.parse(data)
      logger.info "DHCPD: received #{packet.options[:message_type]} packet"
      case packet.options[:message_type]
      when DHCPDISCOVER 
        logger.info "DHCPD: Got DHCP-Discover from " + packet.macf + "/"+  packet.options[:hostname].to_s
        reply = packet.clone
        reply.op = 2
        #if packet.options[:address_request] != nil
        lease = ipstr_to_ary(get_addr(get_lease(packet.macf)))
        reply.yiaddr = lease.pack("CCCC").unpack("N")[0]
        reply.nsiaddr = ipstr_to_ary(interface).pack("CCCC").unpack("N")[0]
        reply.options = {:message_type=>DHCPOFFER}
        reply.options[:subnet_mask] =  mask
        reply.options[:router] = gateway
        reply.options[:lease_time] = leasetime
        reply.options[:dhcp_server] = interface
        reply.options[:dns_server] = dns
        juniper_ztp = juniper_ztp_option_gen(packet)
        reply.options[:juniper_ztp] = juniper_ztp unless juniper_ztp.nil?
        reply.options[:tftp_server] = interface unless juniper_ztp.nil?
        soc.send(reply.toPacket, 0, broadcast, CPORT)
        logger.info "DHCPD: Sending Offer " + lease.join(".") 
      when DHCPREQUEST
        logger.info "DHCPD: Got DHCP-Request from " + packet.macf + "/"+  packet.options[:hostname].to_s
        reply = packet.clone
        reply.op = 2    
        lease = whois(packet.macf)
        if lease.nil? 
          logger.info "DHCPD: got DHCPRequest with not offered address!!"
          if !packet.options[:address_request].nil?
            rmac = whois_ip(packet.options[:address_request].join('.'))
            if (rmac.nil? || rmac == packet.macf)
              logger.info "DHCPD: offered address is free. will be reserved it."
              lease = ipstr_to_ary(get_addr(get_lease_ip(packet.options[:address_request].join('.'), packet.macf)))
            end
          end
        else
          lease = ipstr_to_ary(get_addr(lease))
        end

        if lease.nil?
          logger.info "DHCPD: got DHCPRequest but the owner is missing in the database"
          next
        end

        reply.yiaddr = lease.pack("CCCC").unpack("N")[0]
        reply.nsiaddr = ipstr_to_ary(interface).pack("CCCC").unpack("N")[0]
        reply.options = {:message_type=>DHCPACK}
        reply.options[:subnet_mask] =  mask
        reply.options[:router] = gateway
        reply.options[:lease_time] = leasetime
        reply.options[:dhcp_server] = interface
        reply.options[:dns_server] = dns 
        juniper_ztp = juniper_ztp_option_gen(packet)
        reply.options[:juniper_ztp] = juniper_ztp unless juniper_ztp.nil?
        reply.options[:tftp_server] = interface unless juniper_ztp.nil?
        
        soc.send(reply.toPacket, 0, broadcast, CPORT)
        logger.info "DHCPD: ACK sent."
      when DHCPRELEASE
        n = whois(packet.macf)
        if n != nil
          @database[n] = nil      
          logger.info "DHCPD: Got release from " + packet.macf + ", freeing up " + n.to_s + "!"
        else
          logger.info "DHCPD: Got release from " + packet.macf + ", ignored! Bastard isn't even in the database."
        end
      when DHCPDECLINE
        n = whois(packet.macf)
        if n != nil
          @database[n] = nil      
          logger.info "DHCPD: Got decline from " + packet.macf + ", freeing up " + n.to_s + "!"
        else
          logger.info "DHCPD: Got decline from " + packet.macf + ", ignored! Bastard isn't even in the database."
        end
      when nil
        logger.error "DHCPD: Packet Has no message_type"
      else logger.error "DHCPD: Unknown message type "+ packet.options[:message_type].inspect
      end
    end
  end

end


if !defined? Padrino or Padrino.env.nil?
  puts 'This program should run under Padrino Environment. Please run with "padrino runner".'
  exit(-1)
end



EzDHCPd.new.main
