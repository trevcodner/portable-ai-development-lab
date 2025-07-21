#!/bin/bash
# Complete Installation Verification Script

LAB_DIR="$HOME/portable-lab"

echo "🔍 Portable AI Lab Installation Verification"
echo "==========================================="

ERRORS=0
WARNINGS=0

# Function to check if something exists
check_exists() {
    if [ -e "$1" ]; then
        echo "  ✅ $2"
    else
        echo "  ❌ $2 - MISSING"
        ((ERRORS++))
    fi
}

# Function to check if command works
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "  ✅ $2"
    else
        echo "  ❌ $2 - NOT FOUND"
        ((ERRORS++))
    fi
}

# Function to check service
check_service() {
    if curl -s "$1" >/dev/null 2>&1; then
        echo "  ✅ $2"
    else
        echo "  ⚠️  $2 - NOT RESPONDING"
        ((WARNINGS++))
    fi
}

echo ""
echo "📦 Checking Dependencies..."
check_command "brew" "Homebrew"
check_command "docker" "Docker CLI"
check_command "docker-compose" "Docker Compose"
check_command "colima" "Colima"
check_command "ollama" "Ollama"
check_command "exiftool" "ExifTool"
check_command "jq" "jq (JSON processor)"
check_command "gh" "GitHub CLI"

echo ""
echo "🐳 Checking Docker Status..."
if colima status >/dev/null 2>&1; then
    echo "  ✅ Colima running"
else
    echo "  ⚠️  Colima not running"
    ((WARNINGS++))
fi

echo ""
echo "📁 Checking Lab Directory Structure..."
check_exists "$LAB_DIR" "Lab directory"
check_exists "$LAB_DIR/docker-compose.yml" "Docker compose configuration"
check_exists "$LAB_DIR/dev-environment.sh" "Development environment controller"
check_exists "$LAB_DIR/enhanced-health-dashboard.py" "Enhanced health dashboard"
check_exists "$LAB_DIR/lightroom-integration.py" "Lightroom integration"
check_exists "$LAB_DIR/coding-helpers.sh" "Coding helpers"
check_exists "$LAB_DIR/photo-integration.py" "Photo integration"
check_exists "$LAB_DIR/tracker/track.py" "Progress tracker"
check_exists "$LAB_DIR/health-reports" "Health reports directory"

echo ""
echo "🤖 Checking AI Models..."
if command -v ollama >/dev/null 2>&1; then
    if ollama list | grep -q "llava"; then
        echo "  ✅ LLaVA model installed"
    else
        echo "  ❌ LLaVA model missing"
        ((ERRORS++))
    fi
    
    if ollama list | grep -q "qwen2.5-coder"; then
        echo "  ✅ Qwen2.5-Coder model installed"
    else
        echo "  ❌ Qwen2.5-Coder model missing"
        ((ERRORS++))
    fi
else
    echo "  ❌ Ollama not available"
    ((ERRORS++))
fi

echo ""
echo "🔧 Checking Services (if running)..."
check_service "http://localhost:11434/api/tags" "Vision API (port 11434)"
check_service "http://localhost:11435/api/tags" "Coding API (port 11435)"
check_service "http://localhost:3000" "Open WebUI (port 3000)"
check_service "http://localhost:5678" "N8N (port 5678)"

echo ""
echo "🐍 Checking Python Dependencies..."
if python3 -c "import psutil" 2>/dev/null; then
    echo "  ✅ psutil installed"
else
    echo "  ❌ psutil missing"
    ((ERRORS++))
fi

if python3 -c "import requests" 2>/dev/null; then
    echo "  ✅ requests installed"
else
    echo "  ❌ requests missing"
    ((ERRORS++))
fi

echo ""
echo "⏰ Checking Automated Backup..."
if [ -f "~/Library/LaunchAgents/com.tca.daily-backup.plist" ]; then
    echo "  ✅ Backup scheduler installed"
else
    echo "  ⚠️  Backup scheduler not installed"
    ((WARNINGS++))
fi

if [ -f "~/Documents/code/daily-backup.sh" ]; then
    echo "  ✅ Backup script exists"
else
    echo "  ⚠️  Backup script missing"
    ((WARNINGS++))
fi

echo ""
echo "🧪 Testing Core Functionality..."

# Test health dashboard
if [ -f "$LAB_DIR/enhanced-health-dashboard.py" ]; then
    if python3 "$LAB_DIR/enhanced-health-dashboard.py" >/dev/null 2>&1; then
        echo "  ✅ Health dashboard working"
    else
        echo "  ⚠️  Health dashboard has issues"
        ((WARNINGS++))
    fi
fi

# Test dev environment script
if [ -f "$LAB_DIR/dev-environment.sh" ]; then
    if "$LAB_DIR/dev-environment.sh" status >/dev/null 2>&1; then
        echo "  ✅ Dev environment script working"
    else
        echo "  ⚠️  Dev environment script has issues"
        ((WARNINGS++))
    fi
fi

echo ""
echo "📊 Verification Summary"
echo "======================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 PERFECT! All components verified successfully"
    echo ""
    echo "🚀 Ready to use:"
    echo "   cd ~/portable-lab"
    echo "   ./dev-environment.sh start-dev"
    echo "   python3 enhanced-health-dashboard.py watch"
elif [ $ERRORS -eq 0 ]; then
    echo "✅ GOOD! Core installation complete with $WARNINGS warning(s)"
    echo ""
    echo "🔧 You may want to address the warnings, but the lab should work"
else
    echo "❌ ISSUES FOUND! $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    echo "🛠️  Please fix the errors before using the lab"
fi

echo ""
echo "📚 Next Steps:"
echo "1. Review any errors or warnings above"
echo "2. Start the lab: cd ~/portable-lab && ./dev-environment.sh start-dev"
echo "3. Open http://localhost:3000 for web interface"
echo "4. Monitor with: python3 ~/portable-lab/enhanced-health-dashboard.py watch"
echo "5. See BUILD_GUIDE.md for complete usage instructions"

exit $ERRORS
