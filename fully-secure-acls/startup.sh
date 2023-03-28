#!/usr/bin/env bash
unset CONSUL_HTTP_ADDR
consul leave
pkill consul
sleep 5

workdir=$(pwd)

echo "deleteing ${workdir}/data/*"
rm -rf "${workdir}/data/*"
rm -rf data/*


management_token="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "This is linux"
    management_token=$(uuid)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "This is Mac OS"
    management_token=$(uuidgen)
fi

export CONSUL_HTTP_TOKEN=$management_token

echo "######################"
echo "Configuring Consul"
echo "######################"

cat <<EOF > "${workdir}/config/config.hcl"
data_dir = "${workdir}/data/"
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
    initial_management = "${management_token}"
  }
}
EOF

cat <<EOF > "${workdir}/config/init-acl.hcl"
acl = {
  tokens {
    initial_management = "${management_token}"
  }
}
EOF

echo "######################"
echo "Starting Consul"
echo "######################"

consul agent -config-dir="${workdir}/config/" &

sleep 5




echo "######################"
echo "Updating policies"
echo "######################"

consul acl policy create -name "read-only" \
                        -description "Read-Only Policy" \
                        -rules @acl/policies/read-only.hcl

consul acl token update -id "anonymous" \
                        -append-policy-name="read-only"


consul acl policy create -name "agent" \
                        -description "Agent Policy" \
                        -rules @acl/policies/agent.hcl

agent_token=$(consul acl token create -format json -description "agent token" -policy-name agent | jq -r .SecretID)

consul acl set-agent-token agent $agent_token 

consul acl policy create -name "default" \
                        -description "Default Policy" \
                        -rules @acl/policies/default.hcl

default_token=$(consul acl token create -format json -description "default token" -policy-name default| jq -r .SecretID)

consul acl set-agent-token default $default_token

curl \
   --request PUT \
   --header 'X-Consul-Token: BA71A44A-8C8F-4BAF-891A-3BFF2A187B22' \
   --data @services/ssh.json \
   http://127.0.0.1:8500/v1/agent/service/register

rm -f config/init-acl.hcl
consul reload