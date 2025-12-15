---
applyTo: "**"
---

## 目的

このシステムは、Template Repository に置かれている **指定されたファイル/ディレクトリ**を、すでに Template から作成済みのリポジトリへ **継続的に取り込む（同期 PR を作る）**ための仕組みを提供する。

- 現在の Template Repository 正式名称：`template-repository-test`
  - ※これは動作確認用のダミーで、完成版では `TEMPLATE-REPOSITORY` に置き換える予定

## 対象リポジトリ（重要）

同期の対象は **`template-repository-test`（将来 `TEMPLATE-REPOSITORY`）から作成されたリポジトリのみ**。

- この Template から作成されたリポジトリには、同期用 workflow があらかじめ含まれている
- 各継承先リポジトリで同期 workflow が実行されると、この Template リポジトリを参照して同期 PR を作成する

## 同期対象（Template から取り込みたいもの）

同期対象は、Template リポジトリの **`.github/sync-config.yml`** で管理する。

### 設定ファイルの形式

`.github/sync-config.yml` の例：

```yaml
sync_targets:
  - path: .githooks
    type: directory
    delete_if_missing: true
  - path: install-hooks.sh
    type: file
    delete_if_missing: false
```

- `path`: 同期対象のパス（Template リポジトリのルートからの相対パス）
- `type`: `file` または `directory`
- `delete_if_missing`: Template に存在しない場合、継承先で削除するかどうか

### 設定のオーバーライド

継承先リポジトリで同期対象をカスタマイズしたい場合、継承先リポジトリに **`.github/sync-config.override.yml`** を配置することでオーバーライドできる。

- オーバーライドファイルが存在する場合：継承先の設定を優先して使用
- オーバーライドファイルが存在しない場合：Template の設定をそのまま使用
- オーバーライドファイルの形式は `.github/sync-config.yml` と同じ

これにより、各リポジトリで同期対象を柔軟にカスタマイズできる（例：特定のディレクトリだけ同期しない、削除検知を無効にする、など）。

**注意**: `.github/sync-config.yml` 自体は同期対象に含めない（継承先は常に Template の設定を参照するため）。

### 初期設定

現在の同期対象（初期値）：

- `.githooks/**`（ディレクトリ、削除検知あり）
- `install-hooks.sh`（ファイル、削除検知なし）

※ hooks の中身の仕様そのものは、すでに実装済みのものを利用する前提とする（ここでは仕様定義はしない）。

## 期待する動作（完成形）

### 各継承先リポジトリでの動作（同期 PR の作成）

継承先リポジトリ内の同期用 workflow が実行されたら、以下を行う：

1. 同期設定を読み込む：
   - 継承先リポジトリに `.github/sync-config.override.yml` が存在する場合：それを使用
   - 存在しない場合：Template Repository の `.github/sync-config.yml` を読み込む
2. 同期対象のファイル/ディレクトリを GitHub API を使って Template から取得する
   - ディレクトリの場合は再帰的にすべてのファイルを取得
3. 継承先リポジトリの同名パスへ反映する（同期対象"だけ"を更新する）
4. `delete_if_missing: true` の対象について、Template に存在しないが継承先に存在するファイルは削除する
5. 変更がある場合のみ、以下の処理を行う：

#### 既存 PR の検出

- ブランチ名プレフィックス `chore/sync-from-template` で始まる**オープン状態の PR**を検索する
- 該当する PR が存在する場合：その PR のブランチを更新する（新しいコミットを追加）
- 該当する PR が存在しない場合：新しいブランチと PR を作成する

#### ブランチ名の規則

- 新規作成時：`chore/sync-from-template-YYYYMMDD-HHMMSS`（同期日時を後ろに付ける）
- 既存 PR 更新時：既存のブランチ名をそのまま使用

#### 変更がない場合

- 何もしない（PR は作らない/更新しない）
- 変更検知はファイル内容の比較で行う（メタデータは検知しない）
- 初回実行時に既にファイルが存在する場合も、内容が同じなら変更なしとみなす

#### マージ後の動作

- 同期 PR がマージされた後、次回の同期実行時は新しい PR を作成する
- マージされたブランチは削除しない

#### PR の仕様

##### 新規作成時

- **タイトル**：固定（例：「Template からファイルを同期」）
- **本文**：
  - 同期元のコミットハッシュ（Template リポジトリの `main` ブランチの HEAD）
  - 同期日時（初回）
  - 同期対象の一覧

##### 既存 PR 更新時

- **タイトル**：変更しない
- **本文**：以下を追記する形で更新
  - 最新の同期元コミットハッシュ（Template リポジトリの `main` ブランチの HEAD）
  - 最終更新日時
  - 同期対象の一覧

方針：

- **direct push はしない**
- **PR 作成（または更新）のみ**を行う
- 1 つの継承先リポジトリに対して、同期 PR は常に 1 つのみ存在する

#### 同期 workflow のトリガー

- **手動実行**（`workflow_dispatch`）
- **定期実行**（週に 1 回、毎週月曜日 09:00 JST）

#### 同期 workflow の配置

- 同期用 workflow ファイル（`.github/workflows/sync-from-template.yml`）は、この Template リポジトリに含まれている
- 同期設定ファイル（`.github/sync-config.yml`）も、この Template リポジトリに含まれている
- Template から新規リポジトリを作成すると、同期 workflow と設定ファイルも自動的に含まれる

## 設定値（将来の置き換え前提）

Template 名が `template-repository-test` → `TEMPLATE-REPOSITORY` に切り替わることを見越し、実装では Template 情報を固定値に埋め込まず、置き換えやすい形にする。

Template の参照先ブランチは `main` 固定とする。

例（いずれか）：

- workflow の `env` に `TEMPLATE_REPO` / `TEMPLATE_BRANCH` を置く
- 設定ファイル（例：`config.yml`）に Template 情報を集約する

## 実装の詳細

### PR の作成

- PR は作成のみ行う（レビュアーのアサイン、ラベルの付与は不要）

## 権限 / Secrets（最小限）

### 継承先リポジトリでの同期 workflow

- 継承先リポジトリ内の workflow で PR を作成するため、GitHub Actions が自動的に提供する`GITHUB_TOKEN`を使用する
- 必要な権限：`contents: write`と`pull-requests: write`
- この Template リポジトリは public なので、継承先リポジトリ（private でも）から追加の認証なしで参照できる
- `GITHUB_TOKEN`で作成した PR は他の workflow をトリガーしないが、同期の用途には十分

## エラーハンドリング

### 同期 workflow（継承先リポジトリで実行）

- Template Repository へのアクセスに失敗した場合：**エラーとして停止**
- 同期対象のファイル取得中にエラーが発生した場合：**ロールバックして停止**（中途半端な状態でPRを作成しない）
- PR 作成に失敗した場合：**エラーとして停止**

## 完了条件（Acceptance Criteria）

- `.github/sync-config.yml` で指定されたファイル/ディレクトリが更新された後、継承先リポジトリで同期 workflow を動かすと **同期 PR が作成または更新**される
- PR の変更差分は `.github/sync-config.yml` で指定された対象のみに限定される
- オープン状態の同期 PR が既に存在する場合、新しい PR を作らず既存の PR を更新する
- PR 本文に同期元のコミットハッシュと同期日時が記載される
- Template 名を将来 `TEMPLATE-REPOSITORY` に置き換えられる構造になっている
- 同期 workflow と設定ファイルは Template に含まれており、Template から作成したリポジトリで即座に利用可能
- 設定ファイルを編集することで、将来的に他のディレクトリも同期対象に追加できる
