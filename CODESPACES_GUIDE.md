# GitHub Codespaces 配置指南

## 📖 概述

本项目已配置完整的 GitHub Codespaces 和 CI/CD 流程，支持：
- **一键开发环境**: 在浏览器中直接打开完整的 Flutter 开发环境
- **自动编译测试**: 每次 push 或 PR 自动触发 CI 构建
- **APK 产物输出**: 自动生成 Debug 和 Release 版本的 APK

---

## 🚀 使用 GitHub Codespaces

### 1. 启用 Codespaces

1. 进入 GitHub 仓库页面
2. 点击 **Code** 按钮（绿色按钮）
3. 切换到 **Codespaces** 标签
4. 点击 **Create codespace on main**（或当前分支）

### 2. 等待环境初始化

首次创建需要 3-5 分钟，系统将自动：
- 拉取 Flutter Docker 镜像（包含 Flutter SDK、Dart、Android SDK）
- 安装 Java JDK 17
- 配置 Android SDK 和构建工具
- 安装 VS Code 扩展（Flutter、Dart、GitHub Copilot）
- 进入 `smart_cam` 目录并执行 `flutter pub get` 安装依赖
- 运行 `flutter doctor` 验证环境

### 3. 开始开发

环境就绪后，你可以：
- ✅ 直接在浏览器中编辑代码（VS Code Web）
- ✅ 使用终端运行 Flutter 命令
- ✅ 连接 Android 模拟器或真机调试
- ✅ 使用 GitHub Copilot 辅助编程

### 4. 常用命令

```bash
# 查看 Flutter 环境
flutter doctor -v

# 运行应用（需要连接设备）
flutter run

# 构建 Debug APK
flutter build apk --debug

# 构建 Release APK
flutter build apk --release

# 运行测试
flutter test

# 代码格式化
dart format lib/

# 静态分析
flutter analyze
```

---

## 🔧 CI/CD 自动化流程

### 工作流程说明

CI 配置文件位于 `.github/workflows/ci.yml`，包含两个 Job：

#### Job 1: `build-and-test`
**触发条件**: 
- Push 到 `main` 或 `develop` 分支
- 创建 Pull Request

**执行步骤**:
1. Checkout 代码
2. 设置 Flutter 3.19.0 (stable)
3. 安装依赖 (`flutter pub get`)
4. 代码分析 (`flutter analyze`)
5. 运行测试 (`flutter test`)
6. 构建 Debug APK
7. 上传 Debug APK 为 Artifact（保留 7 天）
8. （仅 main 分支）构建 Release APK
9. （仅 main 分支）上传 Release APK（保留 30 天）

#### Job 2: `code-quality`
**触发条件**: 同上

**执行步骤**:
1. Checkout 代码
2. 设置 Flutter 环境
3. 安装依赖
4. 检查代码格式（未格式化则失败）
5. 静态分析（发现 Info/Warning 级别问题则失败）

### 查看构建结果

1. 进入 GitHub 仓库 → **Actions** 标签
2. 选择对应的工作流运行
3. 查看详细日志和输出
4. 下载构建产物（Artifacts）

### 下载 APK

构建成功后：
1. 在 Actions 页面找到对应的运行记录
2. 滚动到页面底部 **Artifacts** 区域
3. 点击 `app-debug-apk` 或 `app-release-apk`
4. 下载 ZIP 文件并解压获取 APK

---

## ⚙️ 自定义配置

### 修改 Flutter 版本

编辑 `.github/workflows/ci.yml`:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.22.0'  # 修改版本号
    channel: 'stable'
```

编辑 `.devcontainer/devcontainer.json`:
```json
{
  "image": "ghcr.io/cirruslabs/flutter:3.22.0"  // 修改镜像标签
}
```

### 添加更多测试

在 `smart_cam/test/` 目录下创建测试文件，CI 会自动运行所有 `*_test.dart` 文件。

### 配置签名（Release 构建）

1. 在 GitHub Secrets 中添加：
   - `ANDROID_KEYSTORE_BASE64`: keystore 文件的 Base64 编码
   - `KEY_ALIAS`: 密钥别名
   - `KEY_PASSWORD`: 密钥密码
   - `STORE_PASSWORD`: 仓库密码

2. 创建 `android/key.properties`（需自行管理，不提交到 Git）

3. 修改 CI 工作流添加签名步骤

---

## 🐛 故障排查

### Codespaces 启动失败

**问题**: 容器初始化超时或失败

**解决方案**:
1. 删除失败的 Codespace
2. 检查 `.devcontainer/devcontainer.json` 配置
3. 尝试使用不同的镜像版本
4. 联系 GitHub Support

### CI 构建失败

**常见问题**:

1. **依赖安装失败**
   ```bash
   # 本地复现
   flutter clean
   flutter pub get
   ```

2. **分析错误**
   ```bash
   # 查看详细错误
   flutter analyze --fatal-infos
   ```

3. **内存不足**
   - Codespaces: 升级到更高配置（32GB RAM）
   - CI: 使用更大的 Runner（需付费）

### APK 构建失败

**检查项**:
- Android SDK 版本是否匹配
- `pubspec.yaml` 依赖是否兼容
- 是否有平台特定代码错误

---

## 📊 资源用量

### Codespaces 配额

- **免费用户**: 每月 120 core-hours（2-core 机器可用 60 小时）
- **Pro 用户**: 每月 180 core-hours
- **企业用户**: 可自定义配额

**建议**: 开发完成后及时停止 Codespace 以节省配额。

### GitHub Actions 配额

- **公共仓库**: 免费无限使用（2000 分钟/月）
- **私有仓库**: 
  - Free: 2000 分钟/月
  - Pro: 3000 分钟/月
  - Team: 3000 分钟/月
  - Enterprise: 50000 分钟/月

---

## 🔐 安全最佳实践

1. **不要提交敏感信息**
   - API Key、密码等放入 GitHub Secrets
   - 使用 `.gitignore` 排除敏感文件

2. **限制 Artifact 访问**
   - 私有仓库的 Artifact 仅仓库成员可下载
   - 公共仓库建议设置访问控制

3. **定期更新依赖**
   - 使用 `dependabot` 自动更新
   - 审查第三方包的安全性

---

## 📚 相关资源

- [GitHub Codespaces 文档](https://docs.github.com/en/codespaces)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)
- [Dev Containers 规范](https://containers.dev/)

---

## ✅ 检查清单

使用本配置前，请确认：

- [ ] 已启用 GitHub Actions（仓库 Settings → Actions）
- [ ] 已配置必要的 Secrets（如后端 API Key）
- [ ] 了解 Codespaces 配额限制
- [ ] 测试过本地 `flutter build apk` 能成功
- [ ] 阅读过 CI 工作流配置文件

---

**下一步**: 点击 **Code** → **Codespaces** → **Create codespace** 开始开发！
