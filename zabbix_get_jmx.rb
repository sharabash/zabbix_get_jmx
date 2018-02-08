#!/usr/bin/ruby
# vim: set ai ts=2 sw=2 expandtab ft=ruby syn=ruby :
# Author: Nour Sharabash <nour.sharabash@gmail.com>
require 'json'
require 'socket'
require 'getoptlong'

args = GetoptLong.new(
  [ '--java-gateway-host', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--java-gateway-port', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jmx-server', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jmx-port', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--key', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jmx-user', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jmx-pass', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--new-protocol', GetoptLong::OPTIONAL_ARGUMENT ]
)

query = {'request': 'java gateway jmx'}
gateway = {}
args.each do |opt, arg|
  case opt
    when '--java-gateway-host'
      gateway['host'] = arg
    when '--java-gateway-port'
      gateway['port'] = arg.to_i
    when '--jmx-server'
      query['conn'] = arg
    when '--jmx-port'
      query['port'] = arg.to_i
    when '--key'
      query['keys'] = [arg]
    when '--jmx-user'
      query['username'] = arg
    when '--jmx-pass'
      query['password'] = arg
    when '--new-protocol'
      conn = query.delete 'conn'
      port = query.delete 'port'
      query['jmx_endpoint'] = "service:jmx:rmi:///jndi/rmi://#{conn}:#{port}/jmxrmi"
  end
end
query_str = JSON.dump(query)
query_len = query_str.length
query_len_hex = '%.16x' % query_len
query_len_bin = query_len_hex.gsub(/^(..)(..)(..)(..)(..)(..)(..)(..)/, '\\x\8\\x\7\\x\6\\x\5\\x\4\\x\3\\x\2\\x\1')
query_bin = eval('"'+ "ZBXD\\x01#{query_len_bin}" '"').bytes.pack('C*') + query_str

s = TCPSocket.new(gateway['host'], gateway['port'])
s.write query_bin
size = 1024
data = s.read(size)
full = ''
started = false
while data and data.length
  if not started
    if data.index('{')
      data = data[data.index('{'), data.length]
      started = true
    else
      data = ''
    end
  end
  if started
    full += data
  end
  data = s.read(size)
end
s.close
puts full
