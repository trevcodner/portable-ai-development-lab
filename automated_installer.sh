#!/bin/bash
# Portable AI Development Lab - Complete Automated Installer v2.1
# Includes ALL working components from live environment

set -e
LAB_DIR="$HOME/portable-lab"

echo "🚀 Complete Portable AI Development Lab Installer v2.1"
echo "===================================================="

# Check dependencies
if ! command -v brew &> /dev/null; then
    echo "❌ Please install Homebrew first"
    exit 1
fi

echo "📦 Installing dependencies..."
brew install docker docker-compose colima exiftool jq gh
pip3 install psutil requests

# Install Ollama
if ! command -v ollama; then
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# Start Colima
if ! colima status >/dev/null 2>&1; then
    colima start --cpu 2 --memory 4 --disk 20
fi

# Create directories
mkdir -p "$LAB_DIR"
mkdir -p "$LAB_DIR/tracker"
mkdir -p "$LAB_DIR/health-reports"

echo "📝 Creating all lab files..."
cat > "$LAB_DIR/docker-compose.yml" << 'COMPOSE_FILE'
version: '3.8'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
      - WEBUI_SECRET_KEY=$(openssl rand -hex 32)
    volumes:
      - open-webui:/app/backend/data
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped

  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - GENERIC_TIMEZONE=Europe/London
      - N8N_SECURE_COOKIE=false
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped

volumes:
  open-webui:
  n8n_data:
COMPOSE_FILE

cat > "$LAB_DIR/dev-environment.sh" << 'DEV_ENV_FILE'
#!/bin/bash
# Comprehensive Development Environment Manager

export PATH=/usr/local/bin:/opt/homebrew/bin:$PATH
LAB_DIR="$HOME/portable-lab"
cd "$LAB_DIR"

case "$1" in
    start-dev)
        echo "🚀 Starting Development Environment..."
        
        # Start dual Ollama instances
        echo "Starting Vision instance (LLaVA) on port 11434..."
        if ! pgrep -f "ollama.*11434" > /dev/null; then
            OLLAMA_HOST=localhost:11434 /usr/local/bin/ollama serve > /tmp/ollama-vision.log 2>&1 &
            echo "Vision Ollama PID: $!"
        fi
        
        echo "Starting Coding instance (Qwen2.5-Coder) on port 11435..."
        if ! pgrep -f "ollama.*11435" > /dev/null; then
            OLLAMA_HOST=localhost:11435 /usr/local/bin/ollama serve > /tmp/ollama-coding.log 2>&1 &
            echo "Coding Ollama PID: $!"
        fi
        
        sleep 5
        
        # Start web services
        /opt/homebrew/bin/docker-compose up -d
        
        echo ""
        echo "🎯 Development Environment Ready:"
        echo "   Open WebUI:     http://localhost:3000"
        echo "   N8N Workflows:  http://localhost:5678"
        echo "   Vision API:     http://localhost:11434 (LLaVA)"
        echo "   Coding API:     http://localhost:11435 (Qwen2.5-Coder)"
        echo ""
        echo "💻 Quick test commands available:"
        echo "   ./dev-environment.sh test-vision"
        echo "   ./dev-environment.sh test-coding"
        ;;
    
    stop-dev)
        echo "🛑 Stopping Development Environment..."
        /opt/homebrew/bin/docker-compose down
        pkill -f "ollama.*11434"
        pkill -f "ollama.*11435"
        echo "All services stopped."
        ;;
    
    status)
        echo "📊 Development Environment Status:"
        echo ""
        echo "Ollama Instances:"
        pgrep -f "ollama.*11434" > /dev/null && echo "  ✅ Vision (11434): Running" || echo "  ❌ Vision (11434): Stopped"
        pgrep -f "ollama.*11435" > /dev/null && echo "  ✅ Coding (11435): Running" || echo "  ❌ Coding (11435): Stopped"
        echo ""
        echo "Docker Services:"
        /opt/homebrew/bin/docker-compose ps
        ;;
    
    test-vision)
        echo "🔍 Testing Vision API..."
        curl -s http://localhost:11434/api/generate -d '{
            "model": "llava:7b",
            "prompt": "Hello, can you see this text?",
            "stream": false
        }' | jq -r '.response // "No response"'
        ;;
    
    test-coding)
        echo "💻 Testing Coding API..."
        curl -s http://localhost:11435/api/generate -d '{
            "model": "qwen2.5-coder:7b",
            "prompt": "Write a simple Python hello world function",
            "stream": false
        }' | jq -r '.response // "No response"'
        ;;
    
    *)
        echo "Usage: $0 {start-dev|stop-dev|status|test-vision|test-coding}"
        exit 1
        ;;
esac
DEV_ENV_FILE
chmod +x "$LAB_DIR/dev-environment.sh"

cat > "$LAB_DIR/enhanced-health-dashboard.py" << 'HEALTH_DASHBOARD_FILE'
#!/usr/bin/env python3
"""
Enhanced Lab Environment Health Dashboard with Neural Engine Monitoring
"""

import requests
import subprocess
import json
import time
import os
from datetime import datetime
import psutil

class EnhancedLabHealthMonitor:
    def __init__(self):
        self.services = {
            'vision_api': 'http://localhost:11434/api/tags',
            'coding_api': 'http://localhost:11435/api/tags', 
            'open_webui': 'http://localhost:3000',
            'n8n': 'http://localhost:5678'
        }
    
    def check_service_health(self, name, url):
        """Check if a service is responding"""
        try:
            response = requests.get(url, timeout=5)
            return {
                'name': name,
                'status': 'healthy' if response.status_code == 200 else 'unhealthy',
                'response_time': response.elapsed.total_seconds(),
                'status_code': response.status_code
            }
        except Exception as e:
            return {
                'name': name,
                'status': 'down',
                'error': str(e),
                'response_time': None
            }
    
    def get_system_resources(self):
        """Get system resource usage"""
        return {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent,
            'memory_available_gb': round(psutil.virtual_memory().available / (1024**3), 1),
            'disk_free_gb': round(psutil.disk_usage('/').free / (1024**3), 1)
        }
    
    def get_neural_engine_activity(self):
        """Get Neural Engine and AI model activity"""
        try:
            # Get Ollama processes specifically
            result = subprocess.run(['ps', 'aux'], capture_output=True, text=True, timeout=5)
            
            ollama_processes = []
            ml_processes = []
            total_ai_cpu = 0
            total_ai_memory = 0
            
            for line in result.stdout.split('\n'):
                parts = line.split()
                if len(parts) >= 11:
                    process_name = ' '.join(parts[10:])
                    
                    # Check for AI/ML related processes
                    if any(keyword in process_name.lower() for keyword in ['ollama', 'neural', 'coreml', 'mlcompute']):
                        try:
                            cpu_percent = float(parts[2])
                            memory_percent = float(parts[3])
                            total_ai_cpu += cpu_percent
                            total_ai_memory += memory_percent
                            
                            process_info = {
                                'name': process_name[:50],
                                'cpu': cpu_percent,
                                'memory': memory_percent,
                                'pid': parts[1]
                            }
                            
                            if 'ollama' in process_name.lower():
                                ollama_processes.append(process_info)
                            else:
                                ml_processes.append(process_info)
                                
                        except (ValueError, IndexError):
                            continue
            
            # Estimate Neural Engine load based on AI process activity
            # Neural Engine usage correlates with AI model inference
            neural_engine_load = min(total_ai_cpu / 2, 100)  # Rough estimate
            
            return {
                'neural_engine_load_estimate': neural_engine_load,
                'ollama_processes': len(ollama_processes),
                'ml_processes_total': len(ml_processes) + len(ollama_processes),
                'total_ai_cpu_usage': total_ai_cpu,
                'total_ai_memory_usage': total_ai_memory,
                'active_ollama': ollama_processes[:3],  # Top 3
                'active_ml': ml_processes[:2]  # Top 2
            }
            
        except Exception as e:
            return {'error': f'Neural engine monitoring failed: {str(e)}'}
    
    def get_gpu_metal_stats(self):
        """Get GPU and Metal performance stats"""
        try:
            # Check for GPU-related processes and Metal activity
            result = subprocess.run(['ps', 'aux'], capture_output=True, text=True, timeout=5)
            
            metal_activity = 0
            gpu_processes = 0
            
            for line in result.stdout.split('\n'):
                if any(keyword in line.lower() for keyword in ['metal', 'gpu', 'graphics', 'coregraphics']):
                    parts = line.split()
                    if len(parts) >= 3:
                        try:
                            metal_activity += float(parts[2])
                            gpu_processes += 1
                        except (ValueError, IndexError):
                            continue
            
            # Get GPU info
            gpu_result = subprocess.run([
                'system_profiler', 'SPDisplaysDataType', '-json'
            ], capture_output=True, text=True, timeout=10)
            
            gpu_name = 'Apple Silicon GPU'
            if gpu_result.returncode == 0:
                try:
                    data = json.loads(gpu_result.stdout)
                    displays = data.get('SPDisplaysDataType', [])
                    if displays:
                        gpu_name = displays[0].get('spdisplays_renderer', 'Apple Silicon GPU')
                except:
                    pass
            
            return {
                'gpu_name': gpu_name,
                'metal_cpu_usage': min(metal_activity, 100),
                'gpu_load_estimate': min(metal_activity / 4, 100),
                'gpu_processes': gpu_processes
            }
            
        except Exception as e:
            return {'error': f'GPU monitoring failed: {str(e)}'}
    
    def check_ollama_models(self):
        """Check loaded Ollama models with enhanced info"""
        models = {}
        for instance, url in [('vision', 'http://localhost:11434'), ('coding', 'http://localhost:11435')]:
            try:
                response = requests.get(f'{url}/api/tags', timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    models[instance] = {
                        'models': data.get('models', []),
                        'count': len(data.get('models', [])),
                        'status': 'loaded'
                    }
                else:
                    models[instance] = {'status': 'error', 'count': 0}
            except:
                models[instance] = {'status': 'offline', 'count': 0}
        return models
    
    def generate_enhanced_health_report(self):
        """Generate comprehensive health report with Neural Engine stats"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'services': {},
            'system': self.get_system_resources(),
            'neural_engine': self.get_neural_engine_activity(),
            'gpu_metal': self.get_gpu_metal_stats(),
            'models': self.check_ollama_models()
        }
        
        # Check all services
        for name, url in self.services.items():
            report['services'][name] = self.check_service_health(name, url)
        
        return report
    
    def print_enhanced_dashboard(self):
        """Print formatted enhanced dashboard"""
        report = self.generate_enhanced_health_report()
        
        print("\n" + "="*70)
        print(f"🏥 ENHANCED LAB HEALTH DASHBOARD - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("="*70)
        
        # Services Status
        print("\n🔧 SERVICES:")
        for name, status in report['services'].items():
            icon = "✅" if status['status'] == 'healthy' else "❌" if status['status'] == 'down' else "⚠️"
            print(f"  {icon} {name}: {status['status']}")
            if 'response_time' in status and status['response_time']:
                print(f"     Response: {status['response_time']:.3f}s")
        
        # Neural Engine & AI Activity
        neural = report['neural_engine']
        if 'error' not in neural:
            print(f"\n🧠 NEURAL ENGINE & AI ACTIVITY:")
            print(f"  🔥 Estimated Neural Engine Load: {neural['neural_engine_load_estimate']:.1f}%")
            print(f"  🤖 Ollama Instances: {neural['ollama_processes']}")
            print(f"  ⚡ Total ML Processes: {neural['ml_processes_total']}")
            print(f"  💻 AI CPU Usage: {neural['total_ai_cpu_usage']:.1f}%")
            print(f"  💾 AI Memory Usage: {neural['total_ai_memory_usage']:.1f}%")
            
            if neural['active_ollama']:
                print(f"\n  🎯 Active Ollama Processes:")
                for proc in neural['active_ollama']:
                    print(f"     • {proc['name'][:45]}... (CPU: {proc['cpu']:.1f}%)")
        
        # GPU & Metal Performance
        gpu = report['gpu_metal']
        if 'error' not in gpu:
            print(f"\n🎮 GPU & METAL PERFORMANCE:")
            print(f"  🖥️  GPU: {gpu['gpu_name']}")
            print(f"  ⚡ Estimated GPU Load: {gpu['gpu_load_estimate']:.1f}%")
            print(f"  🔧 Metal CPU Usage: {gpu['metal_cpu_usage']:.1f}%")
            print(f"  📊 GPU Processes: {gpu['gpu_processes']}")
        
        # System Resources
        print(f"\n💻 SYSTEM RESOURCES:")
        sys = report['system']
        cpu_icon = "🔥" if sys['cpu_percent'] > 80 else "⚡" if sys['cpu_percent'] > 50 else "✅"
        mem_icon = "🔥" if sys['memory_percent'] > 85 else "⚡" if sys['memory_percent'] > 70 else "✅"
        disk_icon = "🔥" if sys['disk_percent'] > 90 else "⚡" if sys['disk_percent'] > 80 else "✅"
        
        print(f"  {cpu_icon} CPU: {sys['cpu_percent']:.1f}%")
        print(f"  {mem_icon} Memory: {sys['memory_percent']:.1f}% ({sys['memory_available_gb']}GB free)")
        print(f"  {disk_icon} Disk: {sys['disk_percent']:.1f}% ({sys['disk_free_gb']}GB free)")
        
        # AI Models
        print(f"\n🤖 AI MODELS:")
        for instance, model_info in report['models'].items():
            if model_info['status'] == 'loaded':
                print(f"  ✅ {instance.title()}: {model_info['count']} model(s) loaded")
                for model in model_info.get('models', []):
                    size_gb = model.get('size', 0) / (1024**3)
                    print(f"     • {model.get('name', 'Unknown')} ({size_gb:.1f}GB)")
            else:
                icon = "❌" if model_info['status'] == 'offline' else "⚠️"
                print(f"  {icon} {instance.title()}: {model_info['status']}")
        
        # Health Score
        healthy_services = sum(1 for s in report['services'].values() if s['status'] == 'healthy')
        total_services = len(report['services'])
        health_score = int((healthy_services / total_services) * 100)
        
        neural_load = neural.get('neural_engine_load_estimate', 0) if 'error' not in neural else 0
        performance_indicator = "🚀" if neural_load > 20 else "💤" if neural_load < 5 else "⚡"
        
        print(f"\n🎯 OVERALL HEALTH: {health_score}% ({healthy_services}/{total_services} services)")
        print(f"🧠 AI PERFORMANCE: {performance_indicator} Neural Engine at {neural_load:.1f}% load")
        
        # Performance Tips
        if neural_load > 60:
            print("\n💡 TIP: High Neural Engine load - consider reducing concurrent AI tasks")
        elif neural_load < 5 and healthy_services == total_services:
            print("\n💡 TIP: Neural Engine ready - perfect time for AI-intensive tasks")
        
        print("\n" + "="*70)

def main():
    monitor = EnhancedLabHealthMonitor()
    
    if len(os.sys.argv) > 1:
        if os.sys.argv[1] == 'watch':
            try:
                while True:
                    os.system('clear')
                    monitor.print_enhanced_dashboard()
                    print("\nPress Ctrl+C to stop monitoring...")
                    time.sleep(15)  # Refresh every 15 seconds for Neural Engine monitoring
            except KeyboardInterrupt:
                print("\nMonitoring stopped.")
        elif os.sys.argv[1] == 'json':
            report = monitor.generate_enhanced_health_report()
            print(json.dumps(report, indent=2))
        else:
            monitor.print_enhanced_dashboard()
    else:
        monitor.print_enhanced_dashboard()

if __name__ == '__main__':
    main()
HEALTH_DASHBOARD_FILE
chmod +x "$LAB_DIR/enhanced-health-dashboard.py"

cat > "$LAB_DIR/lightroom-integration.py" << 'LIGHTROOM_FILE'
#!/usr/bin/env python3
"""Lightroom Integration for AI Photo Analysis"""

import os
import json
import base64
import requests
import subprocess
from pathlib import Path
from datetime import datetime

class LightroomAIIntegration:
    def __init__(self):
        self.vision_api = "http://localhost:11434/api/generate"
        self.exiftool_path = "/opt/homebrew/bin/exiftool"
        
    def analyze_photo_with_ai(self, image_path):
        """Analyze photo using LLaVA model"""
        
        if not Path(image_path).exists():
            return {"error": f"Image not found: {image_path}"}
        
        prompt = """Analyze this photograph for Adobe Lightroom metadata. Provide:
1. Main subject/content
2. Composition techniques used  
3. Lighting analysis
4. Mood/atmosphere
5. Suggested keywords (comma-separated)
6. Overall assessment"""
        
        try:
            with open(image_path, "rb") as img_file:
                img_base64 = base64.b64encode(img_file.read()).decode("utf-8")
            
            payload = {
                "model": "llava:7b",
                "prompt": prompt,
                "images": [img_base64],
                "stream": False
            }
            
            response = requests.post(self.vision_api, json=payload, timeout=120)
            result = response.json()
            
            return {
                "analysis": result.get("response", "No response"),
                "timestamp": datetime.now().isoformat(),
                "model": "llava:7b"
            }
            
        except Exception as e:
            return {"error": f"Analysis failed: {str(e)}"}

def main():
    integration = LightroomAIIntegration()
    
    if len(os.sys.argv) < 3:
        print("Usage: python lightroom-integration.py analyze /path/to/image.jpg")
        return
    
    command = os.sys.argv[1]
    image_path = os.sys.argv[2]
    
    if command == "analyze":
        result = integration.analyze_photo_with_ai(image_path)
        
        if "error" in result:
            print(f"Error: {result[\"error\"]}")
        else:
            print(f"Analysis: {result[\"analysis\"]}")

if __name__ == "__main__":
    main()

LIGHTROOM_FILE
chmod +x "$LAB_DIR/lightroom-integration.py"

cat > "$LAB_DIR/coding-helpers.sh" << 'CODING_HELPERS_FILE'
#!/bin/bash
# Quick coding helper functions

export PATH=/usr/local/bin:/opt/homebrew/bin:$PATH

# Quick code generation
ask-coder() {
    curl -s http://localhost:11435/api/generate -d "{
        \"model\": \"qwen2.5-coder:7b\",
        \"prompt\": \"$*\",
        \"stream\": false
    }" | jq -r '.response // "No response"'
}

# Quick vision analysis
ask-vision() {
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"llava:7b\",
        \"prompt\": \"$*\",
        \"stream\": false
    }" | jq -r '.response // "No response"'
}

# Photography project helper
analyze-photo() {
    local photo_path="$1"
    local question="${2:-Describe this image in detail}"
    
    if [[ ! -f "$photo_path" ]]; then
        echo "Error: Photo not found at $photo_path"
        return 1
    fi
    
    # Convert image to base64
    local base64_image=$(base64 -i "$photo_path")
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"llava:7b\",
        \"prompt\": \"$question\",
        \"images\": [\"$base64_image\"],
        \"stream\": false
    }" | jq -r '.response // "No response"'
}

# Export functions for use in other scripts
export -f ask-coder ask-vision analyze-photo

echo "🔧 Coding helpers loaded!"
echo "Usage:"
echo "  ask-coder 'Write a Python function to...'"
echo "  ask-vision 'What do you see in this image?'"
echo "  analyze-photo '/path/to/image.jpg' 'What camera settings were used?'"
CODING_HELPERS_FILE
chmod +x "$LAB_DIR/coding-helpers.sh"

cat > "$LAB_DIR/photo-integration.py" << 'PHOTO_INTEGRATION_FILE'
#!/usr/bin/env python3
"""
Photography Project Integration
Connects local Ollama to existing photo workflow
"""

import requests
import json
import base64
import subprocess
from pathlib import Path
import sys

# API endpoints
VISION_API = 'http://localhost:11434/api/generate'
CODING_API = 'http://localhost:11435/api/generate'

# Paths
PROJECT_DIR = Path('$HOME/Documents/code/AI_Photo_Tagger_v3_Repository')
EXIFTOOL_PATH = '/opt/homebrew/bin/exiftool'

def analyze_image_with_llava(image_path, prompt='Analyze this photography image. Describe the composition, lighting, and suggest improvements.'):
    """Analyze image using local LLaVA model"""
    
    if not Path(image_path).exists():
        return f'Error: Image not found at {image_path}'
    
    # Convert image to base64
    with open(image_path, 'rb') as img_file:
        img_base64 = base64.b64encode(img_file.read()).decode('utf-8')
    
    payload = {
        'model': 'llava:7b',
        'prompt': prompt,
        'images': [img_base64],
        'stream': False
    }
    
    try:
        response = requests.post(VISION_API, json=payload, timeout=60)
        result = response.json()
        return result.get('response', 'No response received')
    except Exception as e:
        return f'Error analyzing image: {str(e)}'

def extract_exif_data(image_path):
    """Extract EXIF data using ExifTool"""
    try:
        result = subprocess.run([
            EXIFTOOL_PATH, '-json', str(image_path)
        ], capture_output=True, text=True)
        return json.loads(result.stdout)[0] if result.stdout else {}
    except Exception as e:
        return {'error': str(e)}

def generate_automation_script(task_description):
    """Generate Python automation script using qwen2.5-coder"""
    payload = {
        'model': 'qwen2.5-coder:7b',
        'prompt': f'Write a Python script for this photography automation task: {task_description}. Include error handling and comments.',
        'stream': False
    }
    
    try:
        response = requests.post(CODING_API, json=payload, timeout=60)
        result = response.json()
        return result.get('response', 'No response received')
    except Exception as e:
        return f'Error generating script: {str(e)}'

def batch_analyze_directory(directory_path, max_files=5):
    """Analyze multiple images in a directory"""
    photo_dir = Path(directory_path)
    if not photo_dir.exists():
        return f'Directory not found: {directory_path}'
    
    # Find image files
    image_extensions = {'.jpg', '.jpeg', '.png', '.tiff', '.raw', '.cr2', '.nef'}
    images = [f for f in photo_dir.iterdir() 
              if f.suffix.lower() in image_extensions][:max_files]
    
    results = []
    for img_path in images:
        print(f'Analyzing {img_path.name}...')
        analysis = analyze_image_with_llava(str(img_path))
        exif = extract_exif_data(str(img_path))
        
        results.append({
            'filename': img_path.name,
            'analysis': analysis,
            'exif_summary': {
                'camera': exif.get('Make', 'Unknown') + ' ' + exif.get('Model', ''),
                'lens': exif.get('LensModel', 'Unknown'),
                'settings': f"ISO {exif.get('ISO', 'N/A')}, f/{exif.get('FNumber', 'N/A')}, {exif.get('ShutterSpeed', 'N/A')}s"
            }
        })
    
    return results

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage:')
        print('  python photo-integration.py analyze /path/to/image.jpg')
        print('  python photo-integration.py batch /path/to/directory')
        print('  python photo-integration.py script "task description"')
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == 'analyze' and len(sys.argv) > 2:
        result = analyze_image_with_llava(sys.argv[2])
        print(result)
    elif command == 'batch' and len(sys.argv) > 2:
        results = batch_analyze_directory(sys.argv[2])
        for r in results:
            print(f"\n--- {r['filename']} ---")
            print(f"Camera: {r['exif_summary']['camera']}")
            print(f"Settings: {r['exif_summary']['settings']}")
            print(f"Analysis: {r['analysis'][:200]}...")
    elif command == 'script' and len(sys.argv) > 2:
        script = generate_automation_script(' '.join(sys.argv[2:]))
        print(script)
PHOTO_INTEGRATION_FILE
chmod +x "$LAB_DIR/photo-integration.py"

cat > "$LAB_DIR/tracker/track.py" << 'TRACKER_FILE'
#!/usr/bin/env python3
"""
Auto-Progress Tracking System
Prevents losing progress due to usage limits
"""

import json
import datetime
from pathlib import Path

TRACKER_DIR = Path.home() / 'portable-lab' / 'tracker'
PROGRESS_FILE = TRACKER_DIR / 'progress_notes.md'
STATUS_FILE = TRACKER_DIR / 'STATUS_REPORT.json'

def track(action_name, details, status='completed'):
    """Track progress of development actions"""
    timestamp = datetime.datetime.now().isoformat()
    
    # Append to progress notes
    with open(PROGRESS_FILE, 'a') as f:
        f.write(f'## {timestamp} - {action_name} ({status})\n')
        f.write(f'{details}\n\n')
    
    print(f'📝 Tracked: {action_name} - {status}')

def status_report(priorities=None, next_steps=None, issues=None):
    """Generate comprehensive status report"""
    report = {
        'timestamp': datetime.datetime.now().isoformat(),
        'priorities': priorities or [],
        'next_steps': next_steps or [],
        'issues': issues or [],
        'session_summary': 'Development session status'
    }
    
    with open(STATUS_FILE, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f'📊 Status report saved to {STATUS_FILE}')
    return report

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        track(sys.argv[1], ' '.join(sys.argv[2:]) if len(sys.argv) > 2 else 'Manual entry')
    else:
        print('Usage: python track.py "action_name" "details"')
TRACKER_FILE
chmod +x "$LAB_DIR/tracker/track.py"


# Download AI models
echo ""
echo "🤖 Downloading AI models..."
echo "📥 Downloading LLaVA (Vision model - ~4.7GB)..."
/usr/local/bin/ollama pull llava:7b

echo "📥 Downloading Qwen2.5-Coder (Coding model - ~4.7GB)..."
/usr/local/bin/ollama pull qwen2.5-coder:7b

# Setup automated backup
echo ""
echo "⏰ Setting up automated daily backup..."
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.tca.daily-backup.plist << 'BACKUP_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tca.daily-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$HOME/Documents/code/daily-backup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>18</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/Documents/code/backup.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Documents/code/backup-error.log</string>
</dict>
</plist>
BACKUP_PLIST

launchctl load ~/Library/LaunchAgents/com.tca.daily-backup.plist

# Start services
echo ""
echo "🎯 Starting lab environment..."
cd "$LAB_DIR"
./dev-environment.sh start-dev

# Test everything
echo ""
echo "🧪 Testing all components..."
sleep 10

echo "Testing health dashboard..."
python3 enhanced-health-dashboard.py

echo ""
echo "🎉 Complete Installation Finished!"
echo "================================="
echo ""
echo "🎯 Your Enhanced Portable AI Lab is Ready:"
echo ""
echo "📂 Lab Directory: $LAB_DIR"
echo "🌐 Open WebUI: http://localhost:3000"
echo "⚡ N8N Workflows: http://localhost:5678"
echo "👁️  Vision API: http://localhost:11434"
echo "💻 Coding API: http://localhost:11435"
echo ""
echo "🧠 Enhanced Features Available:"
echo "   python3 ~/portable-lab/enhanced-health-dashboard.py watch"
echo "   python3 ~/portable-lab/lightroom-integration.py analyze /path/to/photo.jpg"
echo "   source ~/portable-lab/coding-helpers.sh && ask-coder 'question'"
echo ""
echo "📚 See BUILD_GUIDE.md and DAILY_TASKS.md for usage"
