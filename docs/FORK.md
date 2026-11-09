# Fork 台账

规则见 [FORK_DEV_GUIDE.md](FORK_DEV_GUIDE.md)。

## 变更记录

每一次功能变更都要在同一个提交里记录到这里，最新的在最上面。

| 日期 | 类型（feat/fix/change/schema） | 摘要 | 文件 / 模块 | 分支 / 提交 |
| --- | --- | --- | --- | --- |
| 2026-11-09 | feat | 默认隐藏收入：收入金额默认模糊，点一下任意被模糊的数字即可在本次会话显示全部收入；应用切到后台或重启后恢复遮挡。遮挡范围：首页/账户详情的收入卡片、交易页汇总的收入与余额、交易列表和详情里的收入交易金额、统计页的现金流（余额、收入、占比条）与按周期图表、分类图的「收入」标签。支出不受影响 | `lib/core/services/income_privacy_service.dart`、`lib/core/presentation/widgets/income_mask.dart`、`test/income_mask_test.dart`，以及下方「修改过的上游文件」 | `my/feature-hide-income`（`0e05b8bb`，合并提交 `b8903a5a`） |
| 2026-11-09 | change | 本地签名：release 密钥副本放入 `android/keys/`（已被 git 忽略），配置 `key.properties`，本地 release 包与 Actions 产物签名一致，可覆盖安装 | `android/keys/`（不入库）、`docs/FORK_DEV_GUIDE.md` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 文档：`CLAUDE.md` 增加「环境目录」，说明默认使用 `../android-env/` | `CLAUDE.md` | `my/feature-ui-tweaks` |
| 2026-11-09 | fix | 交易表单：金额框跳到标题框时先取消焦点、下一帧再聚焦，让输入法重新读取标题框的文字键盘类型（此前仍显示数字键盘） | `lib/app/transactions/form/widgets/transaction_form_amount_block.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | CI：构建 APK 的工作流改为推送 `custom` 时运行，Flutter 版本固定为 `3.47.x`，并在注解中输出签名证书指纹用于核对；已配置 4 个签名 Secrets，Actions 产物与本地 release 包签名一致 | `.github/workflows/build-apk.yml` | `custom`（`f71fa3c5`、`9465c9f5`） |
| 2026-11-09 | change | Android 包名改为 `com.weibin.monekin`（只改 `applicationId`），可与官方应用共存；这是另一个应用，数据不共享，首次安装需用「恢复备份」导入 | `android/app/build.gradle` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 文档：`FORK.md`、`FORK_DEV_GUIDE.md` 改为中文，并补充中文翻译规范、本地 Android 测试和 CI 说明；新增项目根目录 `CLAUDE.md`，默认使用中文并关联相关文档 | `CLAUDE.md`、`docs/FORK.md`、`docs/FORK_DEV_GUIDE.md` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | CI：合并 `claude/relaxed-fermat-kzr28j`，新增构建 release APK 的 GitHub Actions 工作流（手动触发；配置 secret 时用正式密钥签名，否则用一次性密钥） | `.github/workflows/build-apk.yml` | `custom`（合并提交 `3484cd0b`） |
| 2026-11-09 | change | 简体中文（`zh-CN`）润色：用词地道，「您」改「你」，统一术语（分类/筛选/支出/周期交易/持仓），修正误译（如「风俗」「手术」「文件夹」），翻译遗留的英文，补齐 25 条缺失词条，修复使用条款链接 | `lib/core/presentation/widgets/income_expense_flow_card.dart` | 收入卡片的金额和趋势包 `IncomeMask` | `// FORK:` |
| `lib/app/transactions/list/transactions.page.dart` | 汇总条的收入、余额、选中合计包 `IncomeMask` | `// FORK:` |
| `lib/app/transactions/list/widgets/transaction_list_tile.dart` | 收入交易的金额包 `IncomeMask` | `// FORK:` |
| `lib/app/transactions/details/transaction_details.page.dart` | 收入交易的金额（含换算金额）包 `IncomeMask` | `// FORK:` |
| `lib/app/stats/widgets/income_expense_comparason.dart` | 余额、收入金额和占比条包 `IncomeMask` | `// FORK:` |
| `lib/app/stats/stats_page.dart` | 「按周期」图表包 `IncomeMask` | `// FORK:` |
| `lib/app/stats/widgets/movements_distribution/pie_chart_by_categories.dart` | 选中「收入」标签时图表和列表包 `IncomeMask` | `// FORK:` |
| `lib/i18n/json/zh-CN.json` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 首页：去掉左上角的用户信息（头像、问候语、用户名），右上角的隐私模式按钮保留 | `lib/app/home/dashboard.page.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 首页「我的账户」：隐藏账户余额和分组合计，保留周期涨跌 | `lib/app/home/widgets/dashboard_account_list.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 首页：去掉总余额卡片和吸顶余额栏，保留周期选择按钮 | `lib/app/home/dashboard.page.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | change | 交易页：月份切换器（`‹ 月份 ›`），汇总显示当月的收入 / 支出 / 余额；设置了日期筛选或正在搜索时不可用 | `lib/app/transactions/list/transactions.page.dart`、`lib/app/transactions/list/widgets/month_switcher.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | feat | 分类选择器：长按并拖到另一个分类上即可调整顺序，顺序保存在 `displayOrder` | `lib/app/categories/selectors/category_picker.dart` | `my/feature-ui-tweaks` |
| 2026-11-09 | fix | 交易表单：金额框按「下一步」只跳转一次，直接到标题框，标题框使用文字键盘 | `lib/app/transactions/form/widgets/transaction_form_amount_block.dart`、`.../transaction_form_fields.dart` | `my/feature-ui-tweaks` |

## 自定义功能

| 功能 | 分支 | 位置 | 说明 |
| --- | --- | --- | --- |
| 默认隐藏收入 | `my/feature-hide-income` | `IncomePrivacyService`、`IncomeMask` | 状态只在内存里，不持久化、无设置项；与「隐私模式」互相独立 |

## 修改过的上游文件（每次合并上游时都要检查）

| 文件 | 改动 | 标记 |
| --- | --- | --- |
| `android/app/build.gradle` | `applicationId` 改为 `com.weibin.monekin` | `// FORK:` |
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

- 安装包名是 `com.weibin.monekin`，与官方的 `com.monekin.app` 不同，两者可以并存。
- 首页没有总余额卡片，「我的账户」里不显示余额，也没有左上角的用户信息。
- 交易页默认按月浏览；设置了日期筛选或正在搜索时，月份切换器不可用。
- 收入金额默认模糊，点一下可显示；切到后台或重启后恢复遮挡。余额类数字（交易页汇总、统计页现金流）因为能推算出收入，也一起遮挡。
- 简体中文使用「你」称呼，术语与上游不同（见 `FORK_DEV_GUIDE.md` 的中文翻译规范）。

## 待处理

- `test/dashboard_refresh_test.dart` 依赖已删除的总余额卡片（`EvolutionCard`、`DashboardBalanceChart`），目前失败，需要改写或跳过。
- 构建 APK 的工作流目前靠推送 `custom` 触发；要从 Actions 页面手动运行，工作流文件还得放到默认分支 `main` 上，见 `FORK_DEV_GUIDE.md` 第 11 节。
- `zh-TW.json` 尚未做同样的润色；`zh-Hant-HK` 这类繁体区域目前会被匹配到简体。
