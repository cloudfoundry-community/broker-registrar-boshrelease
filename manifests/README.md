# Deployment

This BOSH release provides two errands:

* `broker-registrar`
* `broker-deregistrar`

There are two common use cases for this BOSH release:

* standalone deployment with links to another service broker deployment + cloud foundry
* patch the two errands into the service broker's own deployment manifest

## Standalone deployment

```
bosh2 deploy manifests/broker-registrar.yml \
  -v cf_api_url=... \
  -v cf_skip_ssl_validation=false \
  -v cf_admin_username=admin \
  -v cf_admin_password=... \
  -v servicebroker_deployment=docker-broker
```
