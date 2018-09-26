#!/bin/bash

<%
  require "shellwords"

  def esc(x)
      Shellwords.shellescape(x)
  end
%>

exec 2>&1

export PATH=$PATH:/var/vcap/packages/jq/bin
export PATH=$PATH:/var/vcap/packages/cf-cli/bin

set -eo pipefail -u

<% cf = nil; if_link("cf-admin-user") { |link| cf = link } -%>
CF_API_URL=<%= esc(cf ? cf.p("api_url") : p("cf.api_url")) %>
CF_ADMIN_USERNAME=<%= esc(cf ? cf.p("admin_username") : p("cf.username")) %>
CF_ADMIN_PASSWORD=<%= esc(cf ? cf.p("admin_password") : p("cf.password")) %>
<% if cf -%>
mkdir -p /var/vcap/sys/run
cat > /var/vcap/sys/run/cf.crt <<END_OF_CERT
<%= cf.p("ca_cert") %>
END_OF_CERT
export SSL_CERT_FILE=/var/vcap/sys/run/cf.crt
<% end -%>
CF_SKIP_SSL_VALIDATION=<%= esc(p("cf.skip_ssl_validation")) %>

<%
  servicebroker_name = p("servicebroker.name", nil)
  servicebroker_name ||= link("servicebroker").p("name")
%>
BROKER_NAME=<%= esc(servicebroker_name) %>

echo "CF_API_URL=${CF_API_URL}"
echo "CF_SKIP_SSL_VALIDATION=${CF_SKIP_SSL_VALIDATION}"
echo "CF_ADMIN_USERNAME=${CF_ADMIN_USERNAME}"
echo "BROKER_NAME=${BROKER_NAME}"

if [[ ${CF_SKIP_SSL_VALIDATION} == "true" ]]; then
  cf api "${CF_API_URL}" --skip-ssl-validation
else
  cf api "${CF_API_URL}"
fi

cf auth "${CF_ADMIN_USERNAME}" "${CF_ADMIN_PASSWORD}"

BROKER_GUID=$(cf curl "/v2/service_brokers?q=name:${BROKER_NAME}" | jq -r ".resources[0].metadata.guid")
SERVICE_NAMES=($(cf curl "/v2/services?q=service_broker_guid:${BROKER_GUID}" | jq -r ".resources[].entity.label"))

for service_name in "${SERVICE_NAMES[@]}"; do
  cf purge-service-offering "${service_name}" -f
done

cf delete-service-broker "${BROKER_NAME}" -f
