# Fork 台账

规则见 [FORK_DEV_GUIDE.md](FORK_DEV_GUIDE.md)。

## 变更记录

每一次功能变更都要在同一个提交里记录到这里，最新的在最上面。

| 日期 | 类型（feat/fix/change/schema） | 摘要 | 文件 / 模块 | 分支 / 提交 |
| --- | --- | --- | --- | --- |
| 2026-11-09 | change | 文档：`FORK.md`、`FORK_DEV_GUIDE.md` 改为中文，并补充中文翻译规范、本地 Android 测试和 CI 说明；新增项目根目录 `CLAUDE.md`，默认使用中文并关联相关文档 | `CLAUDE.md`、`docs/FORK.md`、`docs/FORK_DEV_GUIDE.md` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | CI：合并 `claude/relaxed-fermat-kzr28j`，新增构建 release APK 的 GitHub Actions 工作流（手动触发；配置 secret 时用正式密钥签名，否则用一次性密钥） | `.github/workflows/build-apk.yml` | `custom`（合并提交 `3484cd0b`） |
| 2026-11-09 | change | 简体中文（`zh-CN`）润色：用词地道，「您」改「你」，统一术语（分类/筛选/支出/周期交易/持仓），修正误译（如「风俗」「手术」「文件夹」），翻译遗留的英文，补齐 25 条缺失词条，修复使用条款链接 | `lib/i18n/json/zh-CN.json` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 首页：去掉左上角的用户信息（头像、问候语、用户名），右上角的隐私模式按钮保留 | `lib/app/home/dashboard.page.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 首页「我的账户」：隐藏账户余额和分组合计，保留周期涨跌 | `lib/app/home/widgets/dashboard_account_list.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 首页：去掉总余额卡片和吸顶余额栏，保留周期选择按钮 | `lib/app/home/dashboard.page.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 交易页：月份切换器（`‹ 月份 ›`），汇总显示当月的收入 / 支出 / 余额；设置了日期筛选或正在搜索时不可用 | `lib/app/transactions/list/transactions.page.dart`、`lib/app/transactions/list/widgets/month_switcher.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | feat | 分类选择器：长按并拖到另一个分类上即可调整顺序，顺序保存在 `displayOrder` | `lib/app/categories/selectors/category_picker.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | fix | 交易表单：金额框按「下一步」只跳转一次，直接到标题框，标题框使用文字键盘 | `lib/app/transactions/form/widgets/transaction_form_amount_block.dart`、`.../transaction_form_fields.dart` | `my/feature-ui-tweaks` |

## 自定义功能

| 功能 | 分支 | 位置 | 说明 |
| --- | --- | --- | --- |
| | | | |

## 修改过的上游文件（每次合并上游时都要检查）

| 文件 | 改动 | 标记 |
| --- | --- | --- |
| `lib/app/home/widgets/dashboard_account_list.dart` | 账户行去掉余额和分组合计 | `// FORK:` |
| `lib/app/home/dashboard.page.dart` | 去掉余额大卡片、吸顶栏和用户信息（`_buildWelcome`） | `// FORK:` |
| `lib/app/transactions/list/transactions.page.dart` | 月份模式（`_effectiveFilters`） | `// FORK:` |
| `lib/app/categories/selectors/category_picker.dart` | 拖拽排序，`reorderSubset` | `// FORK:` |
| `lib/app/transactions/form/widgets/transaction_form_amount_block.dart` | `onEditingComplete` 焦点处理 | `// FORK:` |
| `lib/app/transactions/form/widgets/transaction_form_fields.dart` | 标题框 `keyboardType` | `// FORK` |
| `lib/i18n/json/zh-CN.json` | 用词和术语调整、新增词条（JSON 没有注释，合并上游时要检查） | 无 |

## 自定义表与迁移

| 表 / 迁移 | 用途 | 基于的上游 schema 版本 |
| --- | --- | --- |
| | | |

## 与上游的行为差异

- 首页没有总余额卡片，「我的账户」里不显示余额，也没有左上角的用户信息。
- 交易页默认按月浏览；设置了日期筛选或正在搜索时，月份切换器不可用。
- 简体中文使用「你」称呼，术语与上游不同（见 `FORK_DEV_GUIDE.md` 的中文翻译规范）。

## 待处理

- `test/dashboard_refresh_test.dart` 依赖已删除的总余额卡片（`EvolutionCard`、`DashboardBalanceChart`），目前失败，需要改写或跳过。
- 构建 APK 的工作流还不能从 Actions 页面手动触发（工作流文件不在默认分支 `main` 上），见 `FORK_DEV_GUIDE.md` 第 11 节。
- `zh-TW.json` 尚未做同样的润色；`zh-Hant-HK` 这类繁体区域目前会被匹配到简体。
