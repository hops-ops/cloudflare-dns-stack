### What's changed in v0.1.1

* docs: add CHANGELOG.md so simple-release workflow can source release notes (by @patrickleet)

  The v0.1.0 GitHub Release was created manually because this file was
  missing; subsequent tags will pick notes from here.

* ci: enable automated version-and-tag on push to main (by @patrickleet)

  Adds the unbounded-tech/workflow-vnext-tag job after validate+test.
  Conventional commits on main now drive auto-tagging, which fires
  on-version-tagged → publish + simple-release.

  DEPLOY_KEY secret was provisioned via `vnext generate-deploy-key`.


See full diff: [v0.1.0...v0.1.1](https://github.com/hops-ops/cloudflare-dns-stack/compare/v0.1.0...v0.1.1)
