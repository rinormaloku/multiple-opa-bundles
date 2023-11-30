package apikeys.policy

import future.keywords.if

default allow := false

allow if {
    has_key(data.daily, api_key)
}

allow if {
    has_key(data.full, api_key)
}

api_key := input.http_request.headers["api-key"]

http_status := 200 if {
  allow
} else := 403

body := "Unauthorized Request"  if http_status == 403

headers["x-ext-auth-allow"] := "yes" if {
    allow
}

headers["x-validated-by"] := "security-checkpoint" if {
    allow
}

request_headers_to_remove := ["api-key"]

response_headers_to_add["x-response-header"] := "for-client-only"
response_headers_to_add["reject-reason"] := "unauthorized" if {
	not allow
}

dynamic_metadata["rateLimit"] := data.apikeys[api_key].metadata.rateLimit if {
	allow
}
dynamic_metadata["usagePlan"] := data.apikeys[api_key].metadata.usagePlan if {
	allow
}

# Helper function to check if a dictionary has a key
has_key(dict, k) {
    dict[k]
}
