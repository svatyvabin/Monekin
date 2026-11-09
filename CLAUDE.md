# CLAUDE.md

这是 Monekin 的个人 fork。本文件是 Claude Code 的入口，规定语言、工作方式，并关联项目文档。

## 语言

- **默认使用中文**：与用户的沟通、方案说明、总结汇报、项目文档（`docs/FORK.md`、`docs/FORK_DEV_GUIDE.md` 等）都用中文。
- 面向上游或 GitHub 的内容保持英文，遵循 `AGENTS.md`：提交信息（`type(scope): Summary`，Summary 首字母大写，见 `docs/COMMIT_MSG.md`）、PR 和 issue。
- 代码里的标识符和注释跟随周围代码的风格（英文）。面向用户的文字走翻译文件，不要硬编码。
- 修改中文词条前先读 `docs/FORK_DEV_GUIDE.md` 的「简体中文（`zh-CN`）规范」，术语和称呼要保持一致。

## 环境目录

- 本机的 Android / Flutter 环境默认使用 `../android-env/`（即 `/media/ubuntu/sys/project/android-env/`），不在仓库里。
- 使用前先 `source ../android-env/env.sh`（JDK 21、Flutter、Android SDK、Gradle 缓存、代理）；构建用 `../android-env/build-apk.sh`；测试备份库、模拟器日志、截图也都在这个目录。
- 这里用普通路径引用，不用 `@` 导入：它是目录，不是文档，导入会出错或把无关内容塞进上下文。

## 相关文档

@AGENTS.md
@docs/FORK_DEV_GUIDE.md
@docs/FORK.md

| 文档 | 内容 |
| --- | --- |
| `AGENTS.md` | 上游的 AI 代理指南（英文）：行为准则、架构、常用任务流程。末尾的「Fork Rules」是本 fork 的覆盖规则 |
| `docs/FORK_DEV_GUIDE.md` | Fork 开发指南：分支、代码原则、翻译与中文规范、本地 Android 测试、CI |
| `docs/FORK.md` | Fork 台账：变更记录、自定义功能、修改过的上游文件、自定义表与迁移 |
| `docs/COMMIT_MSG.md`、`docs/GIT_BRANCHES_WORKFLOW.md`、`docs/CODE_CONTRIBUTING.md` | 上游的提交、分支和贡献规范（英文） |

`AGENTS.md` 里提到的台账章节名是英文，对应 `docs/FORK.md` 里的中文章节：Change log = 变更记录，Custom features = 自定义功能，Modified upstream files = 修改过的上游文件，Custom tables / migrations = 自定义表与迁移。

## 工作方式（要点）

- 在 `custom` 的功能分支（`my/feature-xxx`）上开发，不要在 `main`、`develop` 上改。
- 每一次功能变更（新功能、行为变更、修复、schema 变更）都要在同一个提交里更新 `docs/FORK.md`，台账没更新就不算完成。
- 对上游文件只做最小改动，并标注 `// FORK: <原因>`；只格式化改动过的文件，不要对整个仓库执行 `dart format .`。
- 翻译最后做：先把代码定稿，再改 JSON，最后运行 `dart run slang`。
- 没有明确要求时，不要创建提交，也不要推送到远程。
- 不要创建数据库迁移或提升 schema 版本，除非明确要求。
- 在设备上验证时，测试数据通过应用自带的「恢复备份」导入，不要直接替换数据库文件；模拟器必须用 `-gpu host`，细节见 `docs/FORK_DEV_GUIDE.md` 第 10 节。
- 改完先自查：`flutter analyze`、`flutter test`、受影响的页面在设备上看过，没验证过的要如实说明。
