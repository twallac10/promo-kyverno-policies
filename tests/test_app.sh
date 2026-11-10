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

test_host_path_exempts_local_path_provisioner() {
  # kind's volume provisioner creates helper pods with hostPath mounts in local-path-storage;
  # without this exception no volume can be provisioned where the policy is Enforce (prd).
  for t in $TIERS; do
    conds=$(render "$t" | yq -o json -I0 'select(.metadata.name=="disallow-host-path") | .spec.matchConditions // []')
    echo "$conds" | jq -e '[.[] | select(.expression | test("local-path-storage"))] | length == 1' >/dev/null \
      || fail "$t: disallow-host-path must exempt namespace local-path-storage: $conds"
    others=$(render "$t" | yq 'select(.kind=="ValidatingPolicy" and .metadata.name!="disallow-host-path") | .spec.matchConditions[]?.expression' | grep -c local-path-storage || true)
    [ "$others" = 0 ] || fail "$t: only disallow-host-path may exempt local-path-storage"
  done
}
