# BOSH Release for broker-registrar

The `broker-registrar-boshrelease` is a BOSH release aimed at providing a generic errands
for registering CloudFoundry service brokers via `broker-registrar` and `broker-deregistrar`
errands. While it can be deployed as a standalone deployment, it gains most power from being
added to existing service deployments, to provide a consistent way of registering/deregistering
service brokers.

It leverages the [broker-registrar](https://github.com/pivotal-cf/broker-registrar) code for
handling the CloudFoundry communication, and is based almost entirely off the errands included in [docker-boshrelease](https://github.com/cloudfoundry-community/docker-boshrelease).

## Usage

The standard `templates/make_manifest` script can be used to create a generic
BOSH manifest. If you wish to colocate this release on another deployment,
simply include the content of `templates/jobs.yml` in your [spruce](https://github.com/geofffranks/spruce)
templates for your bosh manifest, and fill out the required parameters

Don't forget to upload the bosh release!

```
# Grab from bosh.io
bosh upload release https://bosh.io/d/github.com/cloudfoundry-community/broker-registrar-boshrelease

# Or alternatively, do it manually
bosh target BOSH_HOST
git clone https://github.com/cloudfoundry-community/broker-registrar-boshrelease.git
cd broker-registrar-boshrelease
bosh upload release releases/broker-registrar-1.yml

## Registering/Deregistering brokers

Once this release has been deployed, you can use `bosh run errand broker-registrar`
and `bosh run errand broker-deregistrar to register + deregister the service broker.

**CAUTION!!!** The `broker-deregistrar` job will issue a purge-service-offering command
to CloudFoundry, deleting all instances of services, app bindings, services, and broker data.
Only use it if you really mean it. If you need to update a service broker from a new URL or
with new data, use the `broker-registrar` job, as it is capable of safely updating brokers.

### Development

As a developer of this release, create new releases and upload them:

```
bosh create release --force && bosh -n upload release
```

To share final releases:

```
bosh create release --final
```
