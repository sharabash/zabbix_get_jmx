#!/usr/bin/env python3
# vim: set ai ts=2 sw=2 expandtab :
# Author: Nour Sharabash <nour.sharabash@gmail.com>

import argparse, sys, json, re, socket

args = None
def parse_args():
  global args
  parser = argparse.ArgumentParser()
  parser.add_argument("--java-gateway-host")
  parser.add_argument("--java-gateway-port")
  parser.add_argument("--jmx-server")
  parser.add_argument("--jmx-port")
  parser.add_argument("--key")
  parser.add_argument("--jmx-user")
  parser.add_argument("--jmx-pass")
  parser.add_argument("--new-protocol", default=False, action='store_true')
  args = parser.parse_args(sys.argv[1:])

def main():
  parse_args()
  query = { 'request': 'java gateway jmx',
             'conn': args.jmx_server, 'port': int(args.jmx_port),
             'keys': [args.key] }
  if args.jmx_user and args.jmx_pass:
    query['username'] = args.jmx_user
    query['password'] = args.jmx_pass
  if args.new_protocol:
    conn = query.pop('conn')
    port = query.pop('port')
    query['jmx_endpoint'] = 'service:jmx:rmi:///jndi/rmi://%s:%s/jmxrmi' % (conn, port)


  query_str = json.dumps(query)
  query_len = len(query_str)
  query_len_hex = '%.16x' % query_len
  query_len_bin = re.sub(r'^(..)(..)(..)(..)(..)(..)(..)(..)', '\\x\\8\\x\\7\\x\\6\\x\\5\\x\\4\\x\\3\\x\\2\\x\\1', query_len_hex)
  query_bin = "ZBXD\\x01%s" % (query_len_bin)
  query_bin = query_bin.encode('latin-1').decode('unicode_escape')
  query_bin += query_str

  with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((args.java_gateway_host, int(args.java_gateway_port)))
    s.send(bytes(query_bin, 'latin-1'))
    size = 1024
    data = s.recv(size)
    full = ''
    started = False
    while len(data):
      data = str(data, 'latin-1')
      if not started:
        if '{' in data:
          data = data[data.index('{'):]
          started = True
        else:
          data = ''
      if started:
        full += data
      data = s.recv(size)
    print(full)

if __name__ == '__main__': main()
