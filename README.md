# Sticky Comment

A GitHub Action that creates or updates a PR/issue comment, using a hidden marker to identify it across workflow runs. Wraps [peter-evans/find-comment](https://github.com/peter-evans/find-comment) and [peter-evans/create-or-update-comment](https://github.com/peter-evans/create-or-update-comment).

## Usage

```yaml
- uses: brc-dd/sticky-comment@v1
  with:
    id: release-notes
    body: |
      ### Release notes draft
      - Adds team-level billing alerts
      - Fixes CSV export for filtered results
```

On the first run, a new comment is created. On subsequent runs with the same `id`, the existing comment is updated instead of posting a duplicate. If no PR or issue context is detected, the action is silently skipped.

## Permissions

The workflow (or job) must grant write access so the action can read and post comments:

```yaml
permissions:
  pull-requests: write # for pull request comments
  issues: write # for issue comments (if used on issues)
```

## Inputs

| Input | Description | Default |
| --- | --- | --- |
| `token` | GitHub token with `issues: write` / `pull-requests: write` permission. | `${{ github.token }}` |
| `repository` | Full repository name (`owner/repo`). | `${{ github.repository }}` |
| `issue-number` | Issue or pull request number. | Current PR/issue number |
| `comment-author` | Filter comments by author (GitHub username) when searching. | `github-actions[bot]` |
| `id` | Unique marker to identify the comment. | **required** |
| `body` | Comment body (Markdown). Mutually exclusive with `body-path`. | |
| `body-path` | Path to a file containing the body. Mutually exclusive with `body`. | |

## Outputs

| Output | Description |
| --- | --- |
| `comment-id` | ID of the created or updated comment. |
| `comment-node-id` | GraphQL node ID of the matched comment (empty if newly created). |
| `comment-body` | Body of the matched comment before update (empty if newly created). |
| `comment-author` | Author of the matched comment (empty if newly created). |

## Examples

### Keep a preview deployment comment up to date

Rerunning the workflow updates the same PR comment with the latest preview URL instead of posting a new comment on every push.

```yaml
name: Preview Deploy
on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Deploy preview environment
        id: deploy
        run: |
          url=$(./scripts/deploy-preview.sh)
          expires_at=$(date -u -d '+7 days' '+%Y-%m-%d %H:%M UTC')
          echo "url=$url" >> "$GITHUB_OUTPUT"
          echo "expires_at=$expires_at" >> "$GITHUB_OUTPUT"

      - uses: brc-dd/sticky-comment@v1
        with:
          id: deploy-preview
          body: |
            ### Preview environment
            - URL: ${{ steps.deploy.outputs.url }}
            - Commit: `${{ github.sha }}`
            - Expires: ${{ steps.deploy.outputs.expires_at }}
```

### Post a CI summary from a generated Markdown file

This pattern is useful when a step already produces a Markdown report, or when you want to post a summary even if the main job fails.

```yaml
name: Test Report
on: pull_request

permissions:
  pull-requests: write

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Run tests
        id: test
        continue-on-error: true
        run: npm test -- --reporter=json > test-report.json

      - name: Render PR comment
        if: always()
        run: node scripts/render-test-comment.mjs test-report.json > test-report.md

      - uses: brc-dd/sticky-comment@v1
        if: always()
        with:
          id: ci-test-summary
          body-path: test-report.md

      - name: Fail job if tests failed
        if: steps.test.outcome == 'failure'
        run: exit 1
```

### Comment on a specific issue when there is no issue or PR context

If the workflow is triggered manually, or otherwise runs without an issue or pull request event, pass `issue-number` explicitly. Otherwise the action will skip because there is no current PR or issue to comment on.

```yaml
name: Nightly Benchmark
on:
  workflow_dispatch:
    inputs:
      issue_number:
        description: Tracking issue to update
        required: true
        type: number

permissions:
  issues: write

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - name: Run benchmarks
        id: benchmark
        run: |
          echo "p95_ms=412" >> "$GITHUB_OUTPUT"
          echo "change=+18%" >> "$GITHUB_OUTPUT"

      - uses: brc-dd/sticky-comment@v1
        with:
          issue-number: ${{ inputs.issue_number }}
          id: nightly-benchmark
          body: |
            ### Nightly benchmark
            - P95 latency: `${{ steps.benchmark.outputs.p95_ms }} ms`
            - Change vs baseline: `${{ steps.benchmark.outputs.change }}`
            - Run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

### Multiple independent comments on the same PR

Use different `id` values to maintain separate comments on the same PR:

```yaml
- uses: brc-dd/sticky-comment@v1
  with:
    id: deploy-preview
    body: |
      ### Preview environment
      https://staging.example.com/pr-${{ github.event.pull_request.number }}

- uses: brc-dd/sticky-comment@v1
  with:
    id: lighthouse
    body: |
      ### Lighthouse
      - Performance: 96
      - Accessibility: 100
      - Best Practices: 100
```

## How it works

The action embeds a hidden HTML comment (`<!-- sticky-comment-id: <id> -->`) at the top of the comment body. On each run it searches for a comment containing that marker. If found, the comment is updated; otherwise a new one is created.

## License

[MIT](LICENSE)
