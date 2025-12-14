# TEMPLATE-REPOSITORY

## セットアップ

```bash
./install-hooks.sh
```

このスクリプトは以下のGit Hooksをインストールします:

- **commit-msg**: コミットメッセージのプレフィックスをチェック（`feat:`, `fix:` など）
- **pre-push**: 保護ブランチへの直接プッシュを防止

設定ファイル:
- `.git-hooks/conf.d/commit_prefixes.yml` - 許可するコミットプレフィックス
- `.git-hooks/conf.d/protected_branches.yml` - 保護するブランチ名

**注意**: `yq` コマンドが必要です。
