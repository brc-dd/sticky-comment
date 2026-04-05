# Sticky Comment

A GitHub Action that creates or updates a PR/issue comment, using a hidden marker to identify it across workflow runs. Wraps [peter-evans/find-comment](https://github.com/peter-evans/find-comment) and [peter-evans/create-or-update-comment](https://github.com/peter-evans/create-or-update-comment).

## Usage

```yaml
- uses: brc-dd/sticky-comment@v1
  with:
    id: my-report
    body: |
      ### Build Report
      All checks passed.
```

On the first run, a new comment is created. On subsequent runs with the same `id`, the existing comment is updated instead of posting a duplicate. If no PR or issue context is detected, the action is silently skipped.

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

### Update a comment on every push

```yaml
name: CI
on: pull_request

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - run: echo "Build output here" > report.txt

      - uses: brc-dd/sticky-comment@v1
        with:
          id: build-report
          body-path: report.txt
```

### Multiple independent comments on the same PR

Use different `id` values to maintain separate comments:

```yaml
- uses: brc-dd/sticky-comment@v1
  with:
    id: lint-results
    body: "Lint: all good"

- uses: brc-dd/sticky-comment@v1
  with:
    id: test-results
    body: "Tests: 42 passed, 0 failed"
```

## How it works

The action embeds a hidden HTML comment (`<!-- sticky-comment-id: <id> -->`) at the top of the comment body. On each run it searches for a comment containing that marker. If found, the comment is updated; otherwise a new one is created.

## License

[MIT](LICENSE)
