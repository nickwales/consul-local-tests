data_dir = "/Users/nwales/checkouts/github.com/nickwales/consul-local-tests/fully-secure-acls/data/"
log_level = "INFO"
server = true
bootstrap_expect = 1
advertise_addr = "{{ GetDefaultInterfaces | exclude \"type\" \"IPv6\" | attr \"address\" }}"
client_addr = "0.0.0.0"
ui = true

ports = {
  serf_wan = -1
  grpc = 8502
}
acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  tokens {
    initial_management = "786CF141-688E-455D-8814-31FC5423E3A1"
  }
}
