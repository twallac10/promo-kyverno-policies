test_policies_ready_test() {
  hooks=$(render dev | test_hooks)
  echo "$hooks" | yq -e 'select(.kind=="Pod" and .metadata.name=="kyverno-policies-test-ready")' >/dev/null || fail "no ready test pod"
  rules=$(render dev | yq -o json -I0 'select(.kind=="ClusterRole" and .metadata.name=="kyverno-policies-test") | .rules')
  echo "$rules" | jq -e '.[] | select(.apiGroups==["policies.kyverno.io"] and (.resources|index("validatingpolicies")) and (.verbs|index("list")))' >/dev/null \
    || fail "test ClusterRole cannot list validatingpolicies: $rules"
}

test_policies_are_validatingpolicies() {
  n=$(render dev | yq 'select(.kind=="ValidatingPolicy") | .metadata.name' | grep -vc -- '---' || true)
  [ "$n" -ge 1 ] || fail "no ValidatingPolicy rendered"
  [ "$(render dev | yq 'select(.kind=="ClusterPolicy") | .metadata.name' | grep -vc -- '---' || true)" = 0 ] || fail "unexpected ClusterPolicy"
}
