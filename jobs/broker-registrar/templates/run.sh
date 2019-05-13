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

set -eo pipefail

<% cf = nil; if_link("cf-admin-user") { |link| cf = link } -%>
CF_API_URL=<%= esc(cf ? cf.p("api_url") : p("cf.api_url")) %>
CF_ADMIN_USERNAME=<%= esc(cf ? cf.p("admin_username") : p("cf.username")) %>
CF_ADMIN_PASSWORD=<%= esc(cf ? cf.p("admin_password") : p("cf.password")) %>
<% if cf -%>
mkdir -p /var/vcap/sys/run
export SSL_CERT_FILE=/var/vcap/sys/run/cf.crt
cat > "${SSL_CERT_FILE}" <<END_OF_CERT
<%= cf.p("ca_cert") %>
END_OF_CERT
<% end -%>
CF_SKIP_SSL_VALIDATION=<%= esc(p("cf.skip_ssl_validation") ? "yes" : "") %>

<%
  broker_url = p("servicebroker.url", nil)
  broker_skip_ssl_validation = p("servicebroker.skip_ssl_validation", nil)
  broker_name = p("servicebroker.name", nil)
  broker_username = p("servicebroker.username", nil)
  broker_password = p("servicebroker.password", nil)
  unless broker_url
    broker = link("servicebroker")
    external_host = broker.p("external_host", "#{broker.instances.first.address}:#{broker.p("port")}")
    protocol      = broker.p("protocol", broker.p("ssl_enabled", false) ? "https" : "http")
    broker_url  ||= "#{protocol}://#{external_host}"
    broker_skip_ssl_validation ||= broker.p("skip_ssl_validation", false)
    broker_name ||= broker.p("name")
    broker_username ||= broker.p("username")
    broker_password ||= broker.p("password")
  end
%>
BROKER_NAME=<%= esc(broker_name) %>
BROKER_URL=<%= esc(broker_url) %>
BROKER_SKIP_SSL_VALIDATION=<%= esc(broker_skip_ssl_validation ? "yes" : "") %>
BROKER_USERNAME=<%= esc(broker_username) %>
BROKER_PASSWORD=<%= esc(broker_password) %>

function createOrUpdateServiceBroker() {
  local brokers_count
  brokers_count=$(cf curl "/v2/service_brokers?q=name:${BROKER_NAME}" \
      | jq -r .total_results)
  if [[ "${brokers_count}" == "0" ]]; then
    echo "Service broker '${BROKER_NAME}' does not exist - creating broker"
    cf create-service-broker "${BROKER_NAME}" "${BROKER_USERNAME}" "${BROKER_PASSWORD}" "${BROKER_URL}"
  else
    echo "Service broker '${BROKER_NAME}' already exists - updating broker"
    cf update-service-broker "${BROKER_NAME}" "${BROKER_USERNAME}" "${BROKER_PASSWORD}" "${BROKER_URL}"
  fi
}

echo "CF_API_URL=${CF_API_URL}"
echo "CF_SKIP_SSL_VALIDATION=${CF_SKIP_SSL_VALIDATION:-no}"
echo "CF_ADMIN_USERNAME=${CF_ADMIN_USERNAME}"
echo "BROKER_NAME=${BROKER_NAME}"
echo "BROKER_URL=${BROKER_URL}"
echo "BROKER_USERNAME=${BROKER_USERNAME}"

cf api "${CF_API_URL}" ${CF_SKIP_SSL_VALIDATION:+"--skip-ssl-validation"}

cf auth "${CF_ADMIN_USERNAME}" "${CF_ADMIN_PASSWORD}"

createOrUpdateServiceBroker

cf service-access

service_names=($(curl ${BROKER_SKIP_SSL_VALIDATION:+"-k"} -s -H "X-Broker-Api-Version: 2.10" -u "${BROKER_USERNAME}:${BROKER_PASSWORD}" "${BROKER_URL}/v2/catalog" | jq -r ".services[].name"))
for service_name in "${service_names[@]}"; do
  cf enable-service-access "${service_name}"
done

cf service-access
