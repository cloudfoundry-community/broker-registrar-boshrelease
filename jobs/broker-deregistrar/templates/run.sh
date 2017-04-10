#!/bin/bash

exec 2>&1

export PATH=$PATH:/var/vcap/packages/jq/bin
export PATH=$PATH:/var/vcap/packages/cf-cli/bin

set -eu

CF_API_URL='<%= p("cf.api_url") %>'
CF_ADMIN_USERNAME='<%= p("cf.username") %>'
CF_ADMIN_PASSWORD='<%= p("cf.password") %>'
CF_SKIP_SSL_VALIDATION='<%= p("cf.skip_ssl_validation") %>'

<% broker = link("servicebroker") -%>
BROKER_NAME='<%= broker.p("name") %>'

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

# broker.p("services") is a JSON array from servicebroker link
<% broker.p("services").each do |service| -%>
cf purge-service-offering <%= service["name"] %> -f
<% end -%>

cf delete-service-broker \
  ${BROKER_NAME} \
  -f
