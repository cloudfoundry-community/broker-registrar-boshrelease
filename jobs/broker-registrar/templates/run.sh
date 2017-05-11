#!/bin/bash

exec 2>&1

export PATH=$PATH:/var/vcap/packages/jq/bin
export PATH=$PATH:/var/vcap/packages/cf-cli/bin

set -eu

CF_API_URL='<%= p("cf.api_url") %>'
CF_ADMIN_USERNAME='<%= p("cf.username") %>'
CF_ADMIN_PASSWORD='<%= p("cf.password") %>'
CF_SKIP_SSL_VALIDATION='<%= p("cf.skip_ssl_validation") %>'

<%
  broker_url = p("servicebroker.url", nil)
  broker_name = p("servicebroker.name", nil)
  broker_username = p("servicebroker.username", nil)
  broker_password = p("servicebroker.password", nil)
  unless broker_url
    broker = link("servicebroker")
    external_host = broker.p("external_host", "#{broker.instances.first.address}:#{broker.p("port")}")
    protocol      = broker.p("protocol", broker.p("ssl_enabled", false) ? "https" : "http")
    broker_url  = "#{protocol}://#{external_host}"
    broker_name = broker.p("name")
    broker_username = broker.p("username")
    broker_password = broker.p("password")
  end
-%>
BROKER_NAME='<%= broker_name %>'
BROKER_URL='<%= broker_url %>'
BROKER_USERNAME='<%= broker_username %>'
BROKER_PASSWORD='<%= broker_password %>'

function createOrUpdateServiceBroker() {
  if [[ "$(cf curl /v2/service_brokers\?q=name:${BROKER_NAME} | jq -r .total_results)" == "0" ]]; then
    echo "Service broker '${BROKER_NAME}' does not exist - creating broker"
    cf create-service-broker ${BROKER_NAME} ${BROKER_USERNAME} ${BROKER_PASSWORD} ${BROKER_URL}
  else
    echo "Service broker '${BROKER_NAME}' already exists - updating broker"
    cf update-service-broker ${BROKER_NAME} ${BROKER_USERNAME} ${BROKER_PASSWORD} ${BROKER_URL}
  fi
}

echo "CF_API_URL=${CF_API_URL}"
echo "CF_SKIP_SSL_VALIDATION=${CF_SKIP_SSL_VALIDATION}"
echo "CF_ADMIN_USERNAME=${CF_ADMIN_USERNAME}"
echo "BROKER_NAME=${BROKER_NAME}"
echo "BROKER_URL=${BROKER_URL}"
echo "BROKER_USERNAME=${BROKER_USERNAME}"

if [[ ${CF_SKIP_SSL_VALIDATION} == "true" ]]; then
  cf api ${CF_API_URL} --skip-ssl-validation
else
  cf api ${CF_API_URL}
fi

cf auth \
  ${CF_ADMIN_USERNAME} \
  ${CF_ADMIN_PASSWORD}

createOrUpdateServiceBroker

cf service-access

service_names=($(curl -s -H "X-Broker-Api-Version: 2.10" -u ${BROKER_USERNAME}:${BROKER_PASSWORD} ${BROKER_URL}/v2/catalog | jq -r ".services[].name"))
for service_name in "${service_names[@]}"; do
  cf enable-service-access $service_name
done

cf service-access
