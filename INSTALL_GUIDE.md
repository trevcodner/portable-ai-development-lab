# Installation Guide

## Quick Start
1. Download the Portable AI Lab files
2. Open Terminal and navigate to the folder
3. Run: chmod +x automated_installer.sh
4. Run: ./automated_installer.sh
5. Verify: ./verify_installation.sh

## What Gets Installed
- Docker + Colima (lightweight container runtime)
- Ollama (local AI model runtime)
- LLaVA 7B (vision/image analysis model - 4.7GB)
- Qwen2.5-Coder 7B (code generation model - 4.7GB)
- Open WebUI (ChatGPT-like interface)
- N8N (workflow automation)
- Enhanced health dashboard with Neural Engine monitoring
- Photography integration tools
- Automated backup system

## After Installation
Your lab will be available at:
- Open WebUI: http://localhost:3000
- N8N: http://localhost:5678

## Quick Commands
```bash
cd ~/portable-lab
./dev-environment.sh start-dev
python3 enhanced-health-dashboard.py watch
```

## Troubleshooting
Run the verification script if you encounter issues:
```bash
./verify_installation.sh
```

---
Developed by: Claude AI & Trevor Codner

