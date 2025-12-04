# 🚀 Llama 3.1 (8B) Inference Benchmark on RTX 3090 — vLLM Performance Report

## ✨ Highlights
- 🧠 Model: **Llama 3.1 — 8B parameters**
- ⚙️ Engine: **vLLM (Fast LLM Inference Engine)**
- 🎮 GPU: **NVIDIA RTX 3090 — 24 GB VRAM**
- 🚀 Throughput: **~82 tokens/second**
- 📍 Platform: Linux + Ryzen 9 7900X + 64 GB RAM
- 🔁 Fully reproducible benchmark with scripts included

---

## 📊 Benchmark Summary

| GPU | Model | Tokens/s | Precision | Engine |
|------|--------|------------|------------|----------|
| **RTX 3090 (24 GB)** | Llama 3.1 (8B) | **~82 t/s** | INT4 | vLLM |



---

## 🖥️ Test Platform

### Hardware
- NVIDIA RTX 3090 (24 GB VRAM)
- AMD Ryzen 9 7900X
- 64 GB RAM
- 1 TB NVMe SSD
- Linux OS (Ubuntu recommended)

### Software
- CUDA 12.x
- NVIDIA Driver 5xx+
- Python 3.10+
- vLLM (latest)
- Tools: jq, bc

---

## 🔬 Why This Benchmark Matters

Local LLM inference is becoming essential for:
- 🔒 Data privacy & offline environments  
- 💸 Zero API usage costs  
- ⚡ Ultra-low latency  
- 🧩 Full model customization  
- 🏠 Running AI locally without cloud dependencies

This benchmark proves the RTX 3090 remains competitive for 8B-class models.



 📜 Benchmark Script - script.sh

 ├── README.md
├── prompt.txt
├── script.sh
├── results/
└── env/
# Benchmarking Llama 3.1 (8B) Inference Performance on NVIDIA RTX 3090 Using vLLM

## Abstract
This document presents a reproducible benchmark evaluating the inference throughput of the Llama 3.1 (8B) model executed on an NVIDIA RTX 3090 GPU. Using the vLLM high-efficiency inference engine, the benchmark measures average tokens-per-second performance under controlled conditions. Results indicate an average throughput of approximately 82 tokens per second, demonstrating that consumer-grade GPUs remain viable for local LLM workloads.

---

## 1. Introduction
Large Language Models (LLMs) require substantial compute resources for efficient inference. Evaluating their performance on consumer hardware is relevant for research, commercial deployments, and privacy-preserving local inference scenarios.

This study measures the inference throughput of Llama 3.1 (8B) using vLLM on an RTX 3090 GPU.

---

## 2. Experimental Setup

### 2.1 Hardware Configuration
- GPU: NVIDIA RTX 3090 (24 GB VRAM)  
- CPU: AMD Ryzen 9 7900X  
- RAM: 64 GB  
- Storage: NVMe SSD 1 TB  
- Environment: Linux (Ubuntu-based)

### 2.2 Software
- CUDA Toolkit 12.x  
- NVIDIA Driver 5xx+  
- vLLM (latest release)  
- Python 3.10+  
- Supporting tools: jq, bc  

### 2.3 Model Parameters
- Model: Llama 3.1 — 8B  
- Precision: INT4  
- Maximum new tokens: 1024  
- Sampling: temperature = 0 (deterministic)

---
## 3. Methodology

### 3.1 Measurement Procedure
1. A fixed prompt is used to ensure deterministic inference.  
2. Wall-clock time is recorded with millisecond precision.  
3. Generated token counts are extracted using JSON tools.  
4. Multiple measurements are taken; initial warm-up run is excluded.  
5. Mean throughput is computed as:  

\[
TPS = \frac{\text{generated tokens}}{\text{elapsed time (s)}}
\]
