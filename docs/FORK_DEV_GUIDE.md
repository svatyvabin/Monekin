# Fork 开发指南

在本 fork 中开发自定义功能的规则，目标是让合并上游的成本尽量低。

## 1. 仓库与分支

| 项目 | 约定 |
| --- | --- |
| `origin` | 本 fork |
| `upstream` | Monekin 原仓库 |
| `main` / `develop` | 分别是 `upstream/main` / `upstream/develop` 的镜像，不在上面开发 |
| `custom` | fork 主线：`develop` 加上自定义功能。构建和发布都来自这里 |
| 功能分支 | `my/feature-xxx`，从 `custom` 切出，并合并回 `custom` |
| 给上游的修复 | 从 `upstream/develop` 切出 `fix/XXXX` 分支，不要带入私有功能 |

```bash
git remote add upstream <上游地址>
git fetch upstream
git checkout develop && git merge --ff-only upstream/develop
git checkout custom && git merge develop
```

每次上游发版时同步一次，最长不超过 2-4 周。

## 2. 代码原则

1. 优先新增，少改动：自定义代码放在新文件或新目录中（`lib/app/<feature>/`、新的 `*_service.dart`）。
2. 对上游文件只做最小改动（注册路由、菜单入口、一处调用）。不做重构、不重新格式化、不调整 import 顺序。
3. 不要对整个仓库执行 `dart format .`，只格式化自己改过的文件。
4. 每处对上游文件的改动都标注 `// FORK: <原因>`，方便合并时查找。
5. 遵循现有模式：单例服务（`._()` + `static final instance`）、`lib/core/routes`、Drift 流、`ExpandingSegmentedTabs`、`Logger.printDebug`。

## 3. 生成文件

- 不要手改 `*.g.dart` / `*.freezed.dart`，也不要手工解决它们的冲突。
- 合并之后任选一方的版本，然后重新生成：
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  dart run slang
  ```
- 生成文件的变更与功能代码分开提交。
- `lib/i18n/generated/` 已被 `.gitignore` 忽略，不会出现在提交里，但每次改完 JSON 都要本地重新生成。

## 4. 数据库与迁移

- 上游迁移文件是 `assets/sql/migrations/vN.sql`，带有 schema 版本号。fork 自己新增 `vN+1` 会与上游的下一个版本冲突。
- 自定义数据放在**新表中，表名以 `x_` 开头**，不要改动上游表的列。
- 只在确有必要时才写迁移。写之前先确认上游当前的版本号；合并上游之后重新核对编号。
- 备份/恢复必须覆盖自定义表；并验证旧备份能导入到新版本。
- 如果必须写自定义迁移，请记录在 `docs/FORK.md`。

## 5. 翻译

- 只编辑 `lib/i18n/json/en.json`（以及需要的其他语言文件），最后一步再运行 `dart run slang`。
- 自定义词条放在 `fork.*` 命名空间下，避免与上游词条冲突。
- 不要硬编码面向用户的文字。
- JSON 里有些键本身带点号（例如 `"no-accounts"` 与 `"no-accounts.descr"` 是同级的两个键），写脚本批量改词条时不要按点号拆分路径。

### 5.1 简体中文（`zh-CN`）规范

目标是地道的中文，没有机器翻译的腔调。修改 `zh-CN.json` 时遵守下面的术语，保持全应用一致：

| 英文 | 统一用词 | 不要用 |
| --- | --- | --- |
| Category / Subcategory | 分类 / 子分类 | 类别、子类别（证券「分类」页里的资产类别、地区等属于另一套体系，保留「类别」） |
| Filter | 筛选 / 筛选器 | 过滤、过滤器 |
| Expense | 支出 | 开支、费用 |
| Amount / Value | 金额 | 数额 |
| Recurrent transaction | 周期交易 | 循环交易 |
| Holdings / Positions | 持仓 | 控股、职位、头寸、仓位 |
| Portfolio | 投资组合 | 文件夹（「文件夹」只用于真正的文件夹，如「查看文件夹」） |
| Net worth | 净资产 | 净值 |
| Account | 账户 | 帐户 |
| Pending | 待处理 | 待办 |
| Reconciled / Unreconciled | 已核对 / 未核对 | 已核实 |
| Movements | 交易 | 动作、运动 |
| Description | 备注 | 描述 |
| Other | 其他 | 其它 |

行文规则：

- 称呼用「你」，不用「您」。
- 不要逐词直译：英文被拼在句子里的片段（如 `GENERAL.of`、`BUDGETS.days-left`）要先看代码里怎么拼接，再选合适的译法。
- 保留所有占位符（`{{n}}`、`{{x}}`）和标签（`<b>`、`<a>`），名字与数量必须和英文一致。
- 新增英文词条时，同时补上 `zh-CN` 的对应词条，避免界面回退显示英文。
- 完成后用脚本对照 `en.json` 检查：键是否缺失、占位符是否一致、是否残留没有中文的值。

## 6. 应用标识（与官方应用共存）

- Android 的 `applicationId` 已改为 `com.weibin.monekin`（只改 `applicationId`；`namespace` 和 Kotlin 的 `package` 是代码内部的包名，保持 `com.monekin.app` 不变）。应用名称和图标目前还和官方一致。
- 包名不同意味着这是另一个应用：数据互不共享，首次安装是全新状态，需要用「设置 → 数据 → 恢复备份」导入数据。
- 在 `pubspec.yaml` 的版本号后加后缀，例如 `10.2.0+fork.1`。
- 不发起网络请求，不加遥测，不加广告。

## 7. 提交

- 遵循 `docs/COMMIT_MSG.md`（提交信息用英文，`type(scope): Summary`，Summary 首字母大写）。
- 一个提交只做一件事；生成文件、翻译和功能逻辑分开提交。
- 由 AI 协助完成的提交加上 trailer：`Includes-AI-Code: true`。
- 没有明确要求时不要创建提交，也不要推送到远程。

## 8. 提交前检查清单

- [ ] `flutter analyze` 无新增问题
- [ ] 只格式化了改动过的文件
- [ ] 代码生成是最新的
- [ ] `flutter test` 通过；新逻辑有测试
- [ ] 改动的页面已在 Android 或 Windows 上验证
- [ ] 涉及 schema 变更：已验证从旧数据库升级和备份恢复
- [ ] 对上游文件的改动是最小的，并标注了 `// FORK:`
- [ ] 已更新 `docs/FORK.md` 的变更记录（及相关表格）

## 9. Fork 台账

`docs/FORK.md` 要保持最新，包含：变更记录、自定义功能、修改过的上游文件、自定义表/迁移，以及与上游的行为差异。

**规则：** 每一次功能变更（新功能、行为变更、修复、schema 变更）都要在**同一个提交**里把它记入 `docs/FORK.md` 的「变更记录」。台账没更新，这项改动就不算完成。

台账的章节名与 `AGENTS.md` 里英文名称的对应关系：

| `AGENTS.md` 中的名称 | `docs/FORK.md` 中的章节 |
| --- | --- |
| Change log | 变更记录 |
| Custom features | 自定义功能 |
| Modified upstream files | 修改过的上游文件 |
| Custom tables / migrations | 自定义表与迁移 |

## 10. 本地 Android 测试

本机的 Android 环境放在 `/media/ubuntu/sys/project/android-env/`，使用前先 `source env.sh`（里面设置了 JDK 21、Flutter、Android SDK、Gradle 缓存和代理）。

### 10.1 构建

```bash
bash /media/ubuntu/sys/project/android-env/build-apk.sh
```

脚本会重试最多 6 次（Gradle 会缓存已下载的内容），产物是 `build/app/outputs/flutter-apk/app-debug.apk`，只包含 x64，用于模拟器。构建时出现 Gradle、AGP、Kotlin 版本即将被 Flutter 弃用的警告，不影响构建。

### 10.2 模拟器（AVD）

AVD 名称 `monekin_api35`。**必须用 `-gpu host`**，在后台任务里启动：

```bash
emulator -avd monekin_api35 -no-window -no-audio -no-boot-anim \
  -gpu host -no-snapshot -no-metrics
```

- 不要用 `-gpu swiftshader_indirect`：SwiftShader 软件渲染器会在渲染某一帧时读越界，`RenderThread` 段错误，导致模拟器静默退出（退出码 1，日志里没有任何报错）。这类崩溃能在内核日志里看到：`journalctl -k | grep RenderThread`。崩溃时没落盘的安装和数据会一起丢失。
- 改用 `-gpu host`（本机是 AMD Radeon 680M，Mesa）之后，反复覆盖安装、强停、重启和长时间操作都没有再崩溃。
- 关闭用 `adb emu kill`。不要用 `pkill -f emulator`，它会匹配到你自己的 shell 命令行并把它一起杀掉。
- 本机交换区长期接近用满，内存紧张时可能触发系统 OOM。

### 10.3 导入测试数据

测试用的备份库是 `android-env/monekin-20261109-162214.db`（6760 笔交易，schema v13，首次打开会自动迁移到当前版本）。

**必须通过应用自带的导入功能导入，不要直接替换 `app_flutter/database.db`**：把文件 `adb push` 到 `/sdcard/Download/`，然后在应用里「设置 → 数据 → 恢复备份」中选择它。直接替换文件绕过了导入功能本身，不能代表真实的使用流程。

### 10.4 验证中文界面

```bash
adb shell pm clear com.weibin.monekin
adb shell cmd locale set-app-locales com.weibin.monekin --locales zh-CN
```

清空数据后启动，应用会直接显示中文，用来验证「首次安装跟随系统语言」。

### 10.5 其他提示

- 设备屏幕是 1080x2400。截图显示为 900x2000 时，坐标要乘以 1.2。
- 分类选择器的长按拖拽，需要用 `adb shell input motionevent` 分步操作（按下 → 停留约 1 秒 → 逐步移动 → 抬起）；`input draganddrop` 不会触发长按。

## 11. CI（GitHub Actions）

`.github/workflows/build-apk.yml`（来自 `claude/relaxed-fermat-kzr28j` 分支）：构建 release APK，并作为产物 `monekin-apk` 上传。

- 触发方式：向 `custom` 分支推送，或手动触发（`workflow_dispatch`）。Flutter 版本固定为 `3.47.x`，与 `flutter-checks.yml` 一致（`pubspec.yaml` 里的版本现在是范围，`flutter-version-file` 读不了）。
- 签名：配置了 `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD` 这四个 secret 时用它们签名；没配置时用一次性密钥签名，APK 可以安装，但每次的签名都不同，不能用来覆盖升级。
- 本机的签名密钥在 `~/.android-keys/monekin/`（`monekin-release.jks`、`ANDROID_KEYSTORE_BASE64.txt`、`secrets.txt`，权限 600），不在仓库里，也不要提交（`.gitignore` 已忽略 `*.jks`）。项目内还有一份副本：`android/keys/monekin-release.jks` 与 `android/keys/key.properties`（`storeFile=../keys/monekin-release.jks`，相对于 `android/app`），均被 `android/.gitignore` 忽略，不会提交；有它们时 `flutter build apk --release` 直接用这把密钥签名，可覆盖安装手机上的版本。别名 `monekin`，证书 SHA-256 指纹 `67b86a5e…519a`（完整值：`67:b8:6a:5e:b4:68:18:e6:28:ec:51:24:9e:2f:f3:d6:41:d1:bb:5a:b1:79:41:bb:ef:26:02:c9:52:8e:51:9a`）。**这把密钥和密码一旦丢失，已安装的应用就无法再覆盖升级**，请另外备份到安全的地方。
- 签名核对：工作流会在注解里输出签名证书的 SHA-256，并说明用的是仓库密钥还是一次性密钥。已验证 Actions 产物与本地用同一把密钥打的 release 包指纹一致（`67b86a5e…519a`），可以互相覆盖安装（前提是包名相同）。
- 产物里的包名取决于 `custom` 上的代码：功能分支（含 `com.weibin.monekin`）合并进 `custom` 之前，产物仍是 `com.monekin.app`。
- 已知限制：GitHub 要求 `workflow_dispatch` 的工作流文件必须存在于**默认分支**上才能从 Actions 页面手动触发，而本 fork 的默认分支是 `main`（上游镜像，不在上面开发）。目前靠推送 `custom` 触发，不受影响。
