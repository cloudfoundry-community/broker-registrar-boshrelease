# Registering Service Brokers with Cloud Foundry

The `broker-registrar-boshrelease` is a BOSH release aimed at providing a generic errands
for registering service brokers with Cloud Foundry via `broker-registrar` and `broker-deregistrar`
errands. While it can be deployed as a standalone deployment, it gains most power from being
added to existing service deployments, to provide a consistent way of registering/deregistering
service brokers.

## Usage

The basic usage is to run an errand to register/re-register a service broker:

```
bosh run-errand broker-registrar
```


Upload the release to your BOSH:

```
bosh upload-release https://bosh.io/d/github.com/cloudfoundry-community/broker-registrar-boshrelease
```

## Deregistering brokers

**CAUTION!!!** The `broker-deregistrar` job will issue a purge-service-offering command
to CloudFoundry, deleting all instances of services, app bindings, services, and broker data.
Only use it if you really mean it. If you need to update a service broker from a new URL or
with new data, use the `broker-registrar` job, as it is capable of safely updating brokers.
