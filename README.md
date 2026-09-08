# BiggerSpeed

一个给 Garmin Edge 码表用的 Connect IQ 数据字段（Data Field），用「左右分栏」的大字速度显示 + 「热到冷」的速度分区变色，让你一眼看清实时速度和所处速度区间。

支持设备：**Edge 840 / Edge 540**（均为 246×322 分辨率）。

## 显示布局

| 位置 | 内容 |
|------|------|
| 左半 | 实时速度整数（个位十位），超大显示，右对齐贴中线 |
| 右上 | 平均速度（无单位） |
| 右下 | 实时速度小数位 + 单位（如 `.5 km/h`） |

## 颜色分区（热到冷）

整格背景随当前速度区间变色，默认 7 档：

| 区间 (km/h) | 颜色 |
|------|------|
| 0-10 | 红 |
| 10-20 | 橙 |
| 20-30 | 黄 |
| 30-40 | 绿 |
| 40-50 | 青 |
| 50-60 | 蓝 |
| 60+ | 紫 |

文字颜色自适应：浅色背景用深字、深色背景用白字，任何区间都清晰可读。

## 技术要点

- 语言：Monkey C（Garmin Connect IQ SDK）
- 类型：`WatchUi.DataField`（复杂数据字段，自定义 `onUpdate` 绘制）
- 单位自适应：公制 `km/h`，英制 `mph`
- 整数/小数拆分：`find(".")` + `substring`（Monkey C 无 `split`）
- 底部对齐：`Graphics.getFontAscent/Descent` 按 baseline 对齐

## 项目结构

```
BiggerSpeed/
├── manifest.xml              # 应用清单（声明 Edge 840 / 540）
├── monkey.jungle             # 编译入口
├── source/
│   ├── App.mc                # 应用入口
│   └── View.mc               # 核心逻辑与绘制
├── resources/
│   ├── drawables/            # 图标
│   └── strings/              # 应用名等字符串
└── make_test_fit.py          # 生成测试 FIT（7 档各 10 秒递增）
```

## 编译

### 前置条件

1. 安装 Connect IQ SDK（本仓库基于 9.2.0）
2. 通过 SDK Manager 下载 Edge 840 / 540 设备数据
3. 生成开发者密钥 `developer_key.der`（VS Code Monkey C 插件生成）

### 编译命令

```bash
monkeyc -o BiggerSpeed-edge840.prg -y ~/Garmin/developer_key -f monkey.jungle -d edge840 -w
monkeyc -o BiggerSpeed-edge540.prg -y ~/Garmin/developer_key -f monkey.jungle -d edge540 -w
```

## 测试

生成 7 档速度递增的测试 FIT（每档 10 秒，5→65 km/h）：

```bash
python3 make_test_fit.py
```

在模拟器里回放该 FIT，即可看到背景依次走过红橙黄绿青蓝紫 7 档。

## 安装到码表

1. 码表 USB 连电脑（Edge 840 是 MTP 设备，Mac 需 OpenMTP / Android File Transfer 等工具）
2. 将对应设备的 `.prg` 复制到 `GARMIN/Apps/`
3. 断开 USB 重启码表
4. 骑行活动 → 数据页 → 添加数据字段 → Connect IQ → 选 BiggerSpeed

## License

MIT
