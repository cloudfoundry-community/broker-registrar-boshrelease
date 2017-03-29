# Deployment

This BOSH release provides two errands:

* `broker-registrar`
* `broker-deregistrar`

There are two common use cases for this BOSH release:

* standalone deployment with links to another service broker deployment + cloud foundry
* patch the two errands into the service broker's own deployment manifest

## Standalone deployment

```
export BROKER_DEPLOYMENT=docker-broker
export BOSH_DEPLOYMENT=broker-registrar-$BROKER_DEPLOYMENT
bosh2 deploy manifests/broker-registrar.yml \
  -v servicebroker_deployment=$BROKER_DEPLOYMENT \
  -v cf_api_url=... \
  -v cf_skip_ssl_validation=false \
  -v cf_admin_username=admin \
  -v cf_admin_password=...
```

This standalone deployment will require that the targeted deployment (e.g. `docker-broker` in example above) is sharing its `servicebroker` link. This is done in its own deployment manifest.

For example, the relevant parts of an `instance_groups/jobs` item is the `provides:` section below.

```yaml
instance_groups:
- name: docker-broker
  jobs:
  - name: docker
    release: docker
  - name: cf-containers-broker
    release: docker
    provides:
      cf-containers-broker:
        as: servicebroker
        shared: true
```

The `cf-containers-broker` key is the deployment's internal name of the link.

This BOSH release/deployment assumes that the link is shared as `servicebroker`.

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
