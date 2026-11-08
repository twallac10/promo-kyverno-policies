test_validation_failure_action() {
  for t in $TIERS; do
    case $t in prd) want=Enforce;; *) want=Audit;; esac
    got=$(build_tier "$t" | yq 'select(.kind=="HelmRelease") | .spec.values."kyverno-policies".validationFailureAction')
    [ "$got" = "$want" ] || fail "$t: validationFailureAction=$got, want $want"
    [ "$(yq 'select(.kind=="HelmRelease") | .spec.values."kyverno-policies".validationFailureAction' "$ROOT/tiers/$t/release.yaml")" = null ] \
      || fail "$t: validationFailureAction must not be in release.yaml (it would be promoted)"
    # And the rendered policies actually use it.
    acts=$(render "$t" | yq 'select(.kind=="ValidatingPolicy") | .spec.validationActions | join(",")' | grep -v -- '---' | sort -u | tr '\n' ' ')
    [ "$acts" = "$( [ $want = Enforce ] && echo 'Deny ' || echo 'Audit ')" ] || fail "$t: rendered validationActions: $acts"
  done
}
