# ListCalc

複数の計算リストを並べ、途中経過やメモを残しながら計算できるiOSアプリです。Swift / SwiftUIによる個人開発アプリとして、App Storeで公開しています。

[App Storeで見る](https://apps.apple.com/app/id6758515306)

## 開発背景

複数の計算を行き来するときも、計算過程と用途をひとつの画面で確認できる電卓を目指して開発しました。一般的な電卓操作に加え、リスト単位の保存・再利用やメモ、端末に応じたレイアウトを備えています。

## 主な機能

- 複数の計算リストを並行して編集
- 計算履歴の行追加・削除とメモ登録
- Undo / Redo、リストのコピー・貼り付け、ドラッグ＆ドロップ
- 数字キーの長押しショートカット
- 計算状態の保存・読み込み・編集・削除
- Firestoreを利用した共有URLの生成とカスタムURLスキームによる取り込み
- 上下2段でリストを扱うモバイルモード
- 配色、キーパッド位置、表示ボタンの設定

## 使用技術

- Swift / SwiftUI
- SwiftData
- Firebase Core / Cloud Firestore / Remote Config
- Google Mobile Ads SDK
- Swift Package Manager
- UserDefaults / Codable
- UIKit連携（共有シート、Safari、広告表示）

## 技術的に工夫した点

- `Decimal`と`NumberFormatter`を使い、桁区切りや小数入力を維持しながら計算
- 計算状態のスナップショットを保持し、Undo / Redoを実装
- iPhone・iPad、縦横画面、利き手設定に応じてレイアウトを切り替え
- `Codable`で計算状態を永続化し、Firestore共有と端末内保存で同じデータ構造を利用
- FirestoreのドキュメントIDとカスタムURLスキームを組み合わせて共有データを復元

## 動作環境

- iOS 17.0以降
- XcodeのiOS Simulatorまたは実機

## ビルド手順

1. このリポジトリをクローンします。
2. Firebase Consoleから自分のiOSアプリ用`GoogleService-Info.plist`を取得します。
3. 取得したファイルを`list-calc/GoogleService-Info.plist`に配置します。キー構成は`list-calc/GoogleService-Info.example.plist`を参照してください。
4. `list-calc.xcodeproj`をXcodeで開きます。
5. Swift Package Managerの依存関係の解決後、iOS 17.0以降のSimulatorまたは実機を選択してビルドします。

`GoogleService-Info.plist`の実ファイルは公開リポジトリには含めていません。Firestore共有やRemote Configを利用する場合は、自分のFirebaseプロジェクトの設定ファイルが必要です。
