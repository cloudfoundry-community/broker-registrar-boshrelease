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

## Collocated deployment

You can modify your service broker's deployment to include the two errands using the `manifests/op-add-errands.yml` operator patch file.

For example, within your broker's release repo:

```
bosh2 deploy manifests/my-broker.yml \
  -o ../broker-registrar-boshrelease/manifests/op-add-errands.yml
  -v cf_api_url=... \
  -v cf_admin_username=... \
  -v cf_admin_password=... \
  -v cf_skip_ssl_validation=...
```

Alternately, copy/rename `op-add-errands.yml` into the broker's `manifests/` folder for its convenience.
