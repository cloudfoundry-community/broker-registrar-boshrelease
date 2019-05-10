Thanks @bgandon for all the fixes in this release.

* Implement a new 'servicebroker.skip_ssl_validation' property
* Fix the 'SERVICE_NAMES[@]: unbound variable' error when running the 'broker-deregistrar' errand twice
* Remove '-u' Bash option + Simplify & factor code
* Factor value of `SSL_CERT_FILE` variable
* Simplify 'cf api' code
* Escape BOSH properties for shell syntax
* Fix potential quoting issues + Adopt the 'pipefail' option
