# Link to Cloud Foundry admin user

This release includes an experiment to allow a deployment to discover a Cloud Foundry admin user via BOSH links, rather than require explicit `cf-api-url`, `cf-admin-username`, etc

Currently no Cloud Foundry release includes any links to expose the URL + admin credentials. So, I've created a new job https://github.com/cloudfoundry-community/collection-of-pullrequests-boshrelease/tree/master/jobs/cf-admin-user that you can add to your CF api instance group:

```
- type: replace
  path: /instance_groups/name=api/jobs/-
  value:
    name: cf-admin-user
    release: collection-of-pullrequests
    provides:
      cf-admin-user:
        as: cf-admin-user
        shared: true
    properties:
      api_url: "https://api.((system_domain))"
      ca_cert: "((router_ssl.certificate))"
      admin_username: admin
      admin_password: "((cf_admin_password))"

- type: replace
  path: /releases/-
  value:
    name: collection-of-pullrequests
    version: 1.1.0
    url: https://github.com/cloudfoundry-community/collection-of-pullrequests-boshrelease/releases/download/v1.1.0/collection-of-pullrequests-1.1.0.tgz
    sha1: 8cd9950a3d7c2f51a363a1ce41b930e6851611aa
```

After updating your CF deployment, a link `cf-admin-user` will be available to all other deployments.

To use this `cf-admin-user` link, you can use the new `-o manifests/operators/cf-admin-user.yml` operator file.
