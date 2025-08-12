# Claude Code Action CI Integration

## Overview

This document explains the integration of Claude Code Action with GitHub Actions CI in the just-a-map project. We've implemented a mechanism that automatically calls Claude Code to request problem fixes when CI fails.

## Background and Issues

### Initial Attempt: workflow_run Event

Initially, we tried to automatically trigger Claude Code Action when CI failed using GitHub Actions' `workflow_run` event.

```yaml
on:
  workflow_run:
    workflows: ["iOS build and test (macOS)"]
    types: [completed]
```

However, this approach faced the following issues:

1. **OIDC Authentication Error**: `Invalid OIDC token` error occurred
2. **Permission Inheritance Problem**: workflow_run events don't inherit permissions from the triggering workflow
3. **Unsolvable**: Despite trying various permission settings, the authentication problem with workflow_run was fundamentally unsolvable

### GitHub Actions Token Limitations

Next, we tried posting `@claude` comments to PRs when CI failed using regular GitHub Actions tokens (`GITHUB_TOKEN`).

However, new problems emerged:
- Comments appear from the `github-actions[bot]` user
- Claude Code Action ignores `@claude` mentions from bot users by design
- Label addition was also attempted, but `GITHUB_TOKEN` cannot trigger other workflows (security restriction)

## Solution: Using Personal Access Token (PAT)

Finally, we resolved all issues by using a Personal Access Token (PAT).

### Implementation Details

#### 1. Changes to ios-build.yml

```yaml
- name: Comment @claude on PR failure
  if: failure() && github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.GH_PAT }}  # Using PAT
    script: |
      const prNumber = context.issue.number;
      const workflowRun = `https://github.com/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`;
      
      const comment = `@claude The CI has failed on this PR. Please check the [workflow run](${workflowRun}) and help fix the issues.
      
      <details>
      <summary>Failed Workflow Details</summary>
      
      - **Workflow**: ${context.workflow}
      - **Run ID**: ${context.runId}
      - **Run Number**: ${context.runNumber}
      - **Event**: ${context.eventName}
      - **SHA**: ${context.sha}
      
      </details>`;
      
      await github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: prNumber,
        body: comment
      });
```

#### 2. Required Permission Settings

The workflow requires the following permissions:

```yaml
permissions:
  contents: read
  pull-requests: write  # Required for posting comments to PRs
```

### Advantages of Using PAT

1. **Actions from Real User Account**: Comments are posted from the configured user account when using PAT
2. **Proper Claude Code Action Activation**: Recognized as `@claude` mentions from real users, not bots
3. **Simple Implementation**: No need for complex mechanisms like labels or workflow_run

## Setup Instructions

### 1. Creating a Personal Access Token

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Click "Generate new token"
3. Select required scopes:
   - `repo` (full access)
4. Generate token and store it securely

### 2. Repository Secret Configuration

1. Go to repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Name: `GH_PAT`
4. Value: Generated Personal Access Token

### 3. Operation Verification

After setup, when CI fails on a PR:
1. `@claude` comment is automatically posted
2. Claude Code Action starts and begins analyzing and fixing the problem

## Security Considerations

- PAT has powerful permissions, so grant only the minimum required scopes
- Update PAT regularly
- Manage securely as repository secrets

## Troubleshooting

### Comments Not Being Posted

1. Check workflow permission settings (`pull-requests: write` required)
2. Verify `GH_PAT` secret is correctly configured
3. Check if PAT hasn't expired

### Claude Code Action Not Starting

1. Verify comment is posted from real user account
2. Check `@claude` mention is correctly included
3. Verify claude.yml configuration

## Future Improvement Ideas

- Custom messages based on error type
- Conditional Claude Code calling under specific conditions
- Prevention of duplicate comments for multiple failures

## Reference Links

- [GitHub Actions: Automatic token authentication](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [GitHub Actions: Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Claude Code Action Documentation](https://github.com/anthropics/claude-code-action)