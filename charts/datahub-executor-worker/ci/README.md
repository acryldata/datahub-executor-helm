# CI values files

Each `*-values.yaml` here is an extra values combination the chart is
lint/rendered with on every PR — the `ct lint` run in the `lint-test` workflow
picks these up automatically (a [chart-testing
convention](https://github.com/helm/chart-testing/blob/main/doc/ct_lint.md)).
Defaults-only rendering misses bugs that need features combined — e.g. two
blocks emitting list items under `volumes:` at different indentation is invalid
YAML only when both render.

When adding a chart feature that emits volumes, volumeMounts, or env entries,
add it to `feature-combo-values.yaml` (one file combining everything) rather
than creating a per-feature file — the combinations are what need coverage.
