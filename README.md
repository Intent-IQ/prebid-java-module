# IntentIQ Identity module for Prebid Server Java

Adds IntentIQ ids to `user.eids` of every auction, and reports the winning bids to IntentIQ.

## Install (Prebid Server Java 4.0 or later)

```bash
git clone --depth 1 -b v1.0.0 https://github.com/Intent-IQ/prebid-java-module.git iiq
iiq/install.sh <your-pbs-repo>
cd <your-pbs-repo> && mvn clean package --file extra/pom.xml   # builds target/prebid-server-bundle.jar
```

`install.sh` copies the module into `extra/modules/intentiq-identity` and adds it to `extra/modules/pom.xml`
and `extra/bundle/pom.xml`. Running it again replaces the module (use it to upgrade).

## Config

See [`sample-config.yaml`](sample-config.yaml) for the config to add and
[`intentiq-identity/README.md`](intentiq-identity/README.md) for every parameter, caching (Redis, Valkey or
Aerospike) and metrics. Your `partner-id` is provided by IntentIQ.

## License

Apache License 2.0, see [LICENSE](LICENSE).
