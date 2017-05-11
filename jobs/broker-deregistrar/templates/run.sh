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
  broker_name = p("servicebroker.name", nil)
  unless broker_name
    broker = link("servicebroker")
    broker_name = broker.p("name")
  end
-%>
BROKER_NAME='<%= broker_name %>'

echo "CF_API_URL=${CF_API_URL}"
echo "CF_SKIP_SSL_VALIDATION=${CF_SKIP_SSL_VALIDATION}"
echo "CF_ADMIN_USERNAME=${CF_ADMIN_USERNAME}"
echo "BROKER_NAME=${BROKER_NAME}"

if [[ ${CF_SKIP_SSL_VALIDATION} == "true" ]]; then
  cf api ${CF_API_URL} --skip-ssl-validation
else
  cf api ${CF_API_URL}
fi

cf auth \
  ${CF_ADMIN_USERNAME} \
  ${CF_ADMIN_PASSWORD}

BROKER_GUID=$(cf curl /v2/service_brokers\?q=name:${BROKER_NAME} | jq -r ".resources[0].metadata.guid")
SERVICE_NAMES=($(cf curl /v2/services\?q=service_broker_guid:${BROKER_GUID} | jq -r ".resources[].entity.label"))

for service_name in "${SERVICE_NAMES[@]}"; do
  cf purge-service-offering $service_name -f
done

cf delete-service-broker \
  ${BROKER_NAME} \
  -f
