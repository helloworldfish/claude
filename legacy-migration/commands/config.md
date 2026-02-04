---
name: config
description: 简化的配置管理命令
usage: /config [options]
hidden: false
---

# 配置管理

简化的配置管理，支持基本的配置选项设置。

## 使用示例

```bash
# 查看当前配置
/config

# 设置阈值
/config set threshold 150000

# 设置策略
/config set strategy balanced

# 设置备份选项
/config set backup true

# 重置配置
/config reset
```

## 配置选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| threshold | 上下文阈值 | 150000 |
| strategy | 迁移策略 (conservative/balanced/aggressive) | balanced |
| backup | 启用备份 | true |
| validate | 启用验证 | true |
| verbose | 详细输出 | false |