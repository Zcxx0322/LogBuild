---
title: 本地部署DeepSeek-R1
date: 2025-03-11 09:35:51
tags: DeepSeek
categories: DeepSeek
---

# 1. DeepSeek 模型规格表
| 模型版本          | 参数量   | 显存需求（FP16） | 推荐 GPU（单卡）              | 多卡支持 | 量化支持 | 适用场景                                                                 |
|--------------------|----------|------------------|-------------------------------|----------|----------|--------------------------------------------------------------------------|
| DeepSeek-R1-1.5B   | 15亿     | 3GB              | GTX 1650（4GB显存）          | 无需     | 支持     | 低资源设备部署（树莓派、旧款笔记本）、实时文本生成、嵌入式系统           |
| DeepSeek-R1-7B     | 70亿     | 14GB             | RTX 3070/4060（8GB显存）     | 可选     | 支持     | 中等复杂度任务（文本摘要、翻译）、轻量级多轮对话系统                     |
| DeepSeek-R1-8B     | 80亿     | 16GB             | RTX 4070（12GB显存）         | 可选     | 支持     | 需更高精度的轻量级任务（代码生成、逻辑推理）                             |
| DeepSeek-R1-14B    | 140亿    | 32GB             | RTX 4090/A5000（16GB显存）   | 推荐     | 支持     | 企业级复杂任务（合同分析、报告生成）、长文本理解与生成                   |
| DeepSeek-R1-32B    | 320亿    | 64GB             | A100 40GB（24GB显存）        | 推荐     | 支持     | 高精度专业领域任务（医疗/法律咨询）、多模态任务预处理                    |
| DeepSeek-R1-70B    | 700亿    | 140GB            | 2x A100 80GB/4x RTX 4090     | 必需     | 支持     | 科研机构/大型企业（金融预测、大规模数据分析）、高复杂度生成任务          |
| DeepSeek-671B      | 6710亿   | 512GB+           | 8x A100/H100（服务器集群）    | 必需     | 支持     | 国家级/超大规模 AI 研究（气候建模、基因组分析）、通用人工智能（AGI）探索 |

## 说明
- **显存需求**基于FP16精度估算，实际使用可能因框架优化差异略有波动。
- ​**多卡支持**标注为"推荐"的型号在单卡运行时可能面临显存限制。
- ​**量化支持**包含4bit/8bit等主流量化方案，可降低约30-70%显存占用。
- 700B+级超大模型建议通过API调用方式使用，本地部署需专业运维团队支持。

# 2. 教程演示硬件配置如下

    OS: Arch Linux x86_64 
    Host: Z3 Air Series GK5MP5O 
    Kernel: 6.12.17-1-lts 
    Uptime: 14 mins 
    Packages: 840 (pacman) 
    Shell: bash 5.2.37 
    Resolution: 1920x1080 
    DE: GNOME 47.5 
    WM: Mutter 
    WM Theme: Adwaita 
    Theme: Adwaita [GTK2/3] 
    Icons: Adwaita [GTK2/3] 
    Terminal: gnome-terminal 
    CPU: Intel i5-10200H (8) @ 4.100GHz 
    GPU: NVIDIA GeForce GTX 1650 Mobile / Max-Q 
    GPU: Intel Comet Lake-H GT1 [UHD Graphics 610] 
    Memory: 4201MiB / 15829MiB

# 3. 部署过程

## 3.1. 下载安装Ollama
Ollama目前已支持MacOS,Linux,Windows，[Ollama官方下载地址](https://ollama.com/download)

---------------------------------
Archlinux可以直接使用pacman命令安装。
```bash
sudo pacman -S ollama
```

## 3.2. 检测Ollama是否成功安装
执行ollama -v如果返回版本号则安装成功。
```bash
ollama -v
```

## 3.3. 通过Ollama拉取DeepSeek模型

结合我的配置考虑，这里我选择是的1.5b，整个模型大小1.1 GB。

更多版本可以在这里查看：https://ollama.com/library/deepseek-r1 。

```bash
ollama run deepseek-r1:1.5b
```

*终端输出*
```terminal
[zcx@archlinux Downloads]$ ollama run deepseek-r1:1.5b
pulling manifest 
pulling aabd4debf0c8... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████▏ 1.1 GB                         
pulling 369ca498f347... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████▏  387 B                         
pulling 6e4c38e1172f... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████▏ 1.1 KB                         
pulling f4d24e9138dd... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████▏  148 B                         
pulling a85fe2a2e58e... 100% ▕██████████████████████████████████████████████████████████████████████████████████████████████▏  487 B                         
verifying sha256 digest 
writing manifest 
success 
>>> Send a message (/? for help)
```

看到success字样，代表成功安装DeepSeek-R1，然后就可以与DeepSeek对话了！








