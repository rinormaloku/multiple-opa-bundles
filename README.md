# Demo: Multiple OPA Bundles
This repo demostrates how to use multiple OPA Bundles with a single policy.

## Build all three bundles
```
opa build -b policy -o policy.tar.gz
opa build -b full -o full.tar.gz
opa build -b daily -o daily.tar.gz
```

## Run the bundle server WITHOUT THE DAILY BUNDLE

```
mkdir server
cp policy.tar.gz server/
cp full.tar.gz server/
cd server
python3 -m http.server 8981
```

## Run OPA Server to read the bundles

```
docker run --add-host=host.docker.internal:host-gateway -p 8181:8181  -i openpolicyagent/opa:0.57.1 run --server --config-file=/dev/stdin <<EOF
services:
  - name: hostedbundle
    url: http://host.docker.internal:8981/

bundles:
  policy:
    service: hostedbundle
    resource: policy.tar.gz
    polling:
      min_delay_seconds: 10
      max_delay_seconds: 120
  full:
    service: hostedbundle
    resource: full.tar.gz
    polling:
      min_delay_seconds: 10
      max_delay_seconds: 600
  daily:
    service: hostedbundle
    resource: daily.tar.gz
    polling:
      min_delay_seconds: 5
      max_delay_seconds: 10
EOF
```

## Validate the setup

Make a curl request with the API Key present in the "full" bundle: **SUCCESS**.
```
curl -X POST \
     -H "Content-Type: application/json" \
     --data '{"input":{"http_request":{"headers":{"api-key":"05df9055-04b4-44f0-ae2b-d4543df64d88"}}}}' \
     'http://localhost:8181/v1/data/apikeys/policy' | jq
```

Make a curl request with the API Key present in the "daily" bundle: **FAILURE**.
The request failed because this bundle is not loaded.
```
curl -X POST \
     -H "Content-Type: application/json" \
     --data '{"input":{"http_request":{"headers":{"api-key":"15as2231-17b7-6963-hj7b-d45488d3df64"}}}}' \
     'http://localhost:8181/v1/data/apikeys/policy' | jq
```

Copy the daily bundle to the server directory so that it will be served and picked up by OPA

```
cp daily.tar.gz server/
```

Make a curl request once more after 10 seconds pass: SUCCESS
```
curl -X POST \
     -H "Content-Type: application/json" \
     --data '{"input":{"http_request":{"headers":{"api-key":"15as2231-17b7-6963-hj7b-d45488d3df64"}}}}' \
     'http://localhost:8181/v1/data/apikeys/policy' | jq
```
