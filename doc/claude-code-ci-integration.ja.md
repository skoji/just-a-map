# Claude Code Action CI統合

## 概要

このドキュメントでは、just-a-mapプロジェクトにおけるClaude Code ActionとGitHub Actions CIの統合について説明します。CI失敗時に自動的にClaude Codeを呼び出し、問題の修正を依頼する仕組みを実装しています。

## 背景と課題

### 当初の試み：workflow_runイベント

最初は、GitHub Actionsの`workflow_run`イベントを使用して、CI失敗時に自動的にClaude Code Actionを起動しようとしました。

```yaml
on:
  workflow_run:
    workflows: ["iOS build and test (macOS)"]
    types: [completed]
```

しかし、この方法では以下の問題に直面しました：

1. **OIDC認証エラー**: `Invalid OIDC token`エラーが発生
2. **権限の継承問題**: workflow_runイベントは、トリガー元のワークフローから権限を継承しない
3. **解決不可能**: 様々な権限設定を試みたが、根本的にworkflow_runでの認証問題は解決できなかった

### GitHub Actionsのトークン制限

次に、通常のGitHub Actionsトークン（`GITHUB_TOKEN`）を使用して、CI失敗時にPRに`@claude`コメントを投稿する方法を試みました。

しかし、新たな問題が発生：
- `github-actions[bot]`ユーザーからのコメントとなる
- Claude Code Actionは、botユーザーからの`@claude`メンションを無視する仕様
- ラベル付与も試みたが、`GITHUB_TOKEN`では他のワークフローをトリガーできない（セキュリティ制限）

## 解決策：Personal Access Token (PAT)の使用

最終的に、Personal Access Token（PAT）を使用することで、すべての問題を解決しました。

### 実装の詳細

#### 1. ios-build.ymlの変更

```yaml
- name: Comment @claude on PR failure
  if: failure() && github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.GH_PAT }}  # PATを使用
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

#### 2. 必要な権限設定

ワークフローには以下の権限が必要です：

```yaml
permissions:
  contents: read
  pull-requests: write  # PRへのコメント投稿に必要
```

### PATを使用する利点

1. **実際のユーザーアカウントからのアクション**: PATを使用することで、コメントは設定したユーザーのアカウントから投稿される
2. **Claude Code Actionの正常な起動**: botではなく実際のユーザーからの`@claude`メンションとして認識される
3. **シンプルな実装**: ラベルやworkflow_runなどの複雑な仕組みが不要

## セットアップ手順

### 1. Personal Access Tokenの作成

1. GitHubの Settings > Developer settings > Personal access tokens へアクセス
2. 「Generate new token」をクリック
3. 必要なスコープを選択：
   - `repo`（フルアクセス）
4. トークンを生成し、安全に保管

### 2. リポジトリシークレットの設定

1. リポジトリの Settings > Secrets and variables > Actions へアクセス
2. 「New repository secret」をクリック
3. 名前：`GH_PAT`
4. 値：生成したPersonal Access Token

### 3. 動作確認

設定後、PRでCIが失敗すると：
1. 自動的に`@claude`コメントが投稿される
2. Claude Code Actionが起動し、問題の分析と修正を開始する

## セキュリティ考慮事項

- PATは強力な権限を持つため、最小限の必要なスコープのみを付与する
- PATは定期的に更新する
- リポジトリシークレットとして安全に管理する

## トラブルシューティング

### コメントが投稿されない場合

1. ワークフローの権限設定を確認（`pull-requests: write`が必要）
2. `GH_PAT`シークレットが正しく設定されているか確認
3. PATの有効期限が切れていないか確認

### Claude Code Actionが起動しない場合

1. コメントが実際のユーザーアカウントから投稿されているか確認
2. `@claude`メンションが正しく含まれているか確認
3. claude.ymlの設定を確認

## 今後の改善案

- エラーの種類に応じたカスタムメッセージ
- 特定の条件下でのみClaude Codeを呼び出す設定
- 複数の失敗に対する重複コメントの防止

## 参考リンク

- [GitHub Actions: Automatic token authentication](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [GitHub Actions: Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Claude Code Action Documentation](https://github.com/anthropics/claude-code-action)