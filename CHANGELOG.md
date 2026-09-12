### What's changed in v0.7.3

* chore: migrate workflows-crossplane to hops-ops@v3.2.0 (by @renovate[bot])

  * chore(deps): update unbounded-tech/workflows-crossplane action to v3

  * chore: migrate workflows-crossplane to hops-ops@v3.2.0

  ---------

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>
  Co-authored-by: Patrick Lee Scott <pat@patscott.io>

* chore(deps): update unbounded-tech/workflow-vnext-tag action to v1.22.3 (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* fix(deps): adopt external-dns 1.22.0 with alpha annotationPrefix (#13) (by @patrickleet)

  1.22 / app 0.22 defaults to GA annotation prefix with no alpha fallback,
  which can delete DNS for workloads still using alpha annotations.
  Pin annotationPrefix to alpha and bump chart; policy already upsert-only.
  Supersedes Renovate #12 once green.


See full diff: [v0.7.2...v0.7.3](https://github.com/hops-ops/cloudflare-dns-stack/compare/v0.7.2...v0.7.3)
