#!/bin/bash
# Setup N8N Example Workflows

echo "🔧 Setting up N8N Example Workflows..."

# Wait for N8N to be ready
echo "⏳ Waiting for N8N to start..."
for i in {1..30}; do
    if curl -s http://localhost:5678 >/dev/null 2>&1; then
        echo "✅ N8N is ready"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done

# Create example workflows via N8N API
echo ""
echo "📋 Creating example workflows..."

# Workflow 1: AI Photo Analysis
echo "1️⃣ Creating 'AI Photo Analysis' workflow..."
curl -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Example: AI Photo Analysis",
    "nodes": [
      {
        "id": "manual-trigger",
        "type": "n8n-nodes-base.manualTrigger",
        "name": "Manual Trigger",
        "position": [200, 300],
        "parameters": {}
      },
      {
        "id": "set-photo-data",
        "type": "n8n-nodes-base.set",
        "name": "Set Photo Data", 
        "position": [400, 300],
        "parameters": {
          "values": {
            "string": [
              {"name": "image_path", "value": "/path/to/your/photo.jpg"},
              {"name": "analysis_prompt", "value": "Analyze this photograph for composition, lighting, and technical quality."}
            ]
          }
        }
      },
      {
        "id": "ollama-vision",
        "type": "n8n-nodes-base.httpRequest",
        "name": "Ollama Vision API",
        "position": [600, 300],
        "parameters": {
          "url": "http://localhost:11434/api/generate",
          "method": "POST",
          "sendHeaders": true,
          "headerParameters": {
            "parameters": [{"name": "Content-Type", "value": "application/json"}]
          },
          "sendBody": true,
          "bodyParameters": {
            "parameters": [
              {"name": "model", "value": "llava:7b"},
              {"name": "prompt", "value": "={{$node[\"Set Photo Data\"].json.analysis_prompt}}"},
              {"name": "stream", "value": false}
            ]
          }
        }
      }
    ],
    "connections": {
      "Manual Trigger": {"main": [[{"node": "Set Photo Data", "type": "main", "index": 0}]]},
      "Set Photo Data": {"main": [[{"node": "Ollama Vision API", "type": "main", "index": 0}]]}
    }
  }' >/dev/null 2>&1

# Workflow 2: AI Code Assistant  
echo "2️⃣ Creating 'AI Code Assistant' workflow..."
curl -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Example: AI Code Assistant",
    "nodes": [
      {
        "id": "webhook-trigger",
        "type": "n8n-nodes-base.webhook",
        "name": "Coding Help Webhook",
        "position": [200, 300],
        "parameters": {"path": "coding-help", "responseMode": "responseNode"}
      },
      {
        "id": "ollama-coding",
        "type": "n8n-nodes-base.httpRequest",
        "name": "Ollama Coding API",
        "position": [400, 300],
        "parameters": {
          "url": "http://localhost:11435/api/generate",
          "method": "POST",
          "sendHeaders": true,
          "headerParameters": {
            "parameters": [{"name": "Content-Type", "value": "application/json"}]
          },
          "sendBody": true,
          "bodyParameters": {
            "parameters": [
              {"name": "model", "value": "qwen2.5-coder:7b"},
              {"name": "prompt", "value": "={{$json.body.question || \"Write a Python hello world function\"}}"},
              {"name": "stream", "value": false}
            ]
          }
        }
      },
      {
        "id": "respond",
        "type": "n8n-nodes-base.respondToWebhook",
        "name": "Respond with Code",
        "position": [600, 300],
        "parameters": {"responseBody": "={{$json.response}}"}
      }
    ],
    "connections": {
      "Coding Help Webhook": {"main": [[{"node": "Ollama Coding API", "type": "main", "index": 0}]]},
      "Ollama Coding API": {"main": [[{"node": "Respond with Code", "type": "main", "index": 0}]]}
    }
  }' >/dev/null 2>&1

echo ""
echo "🎉 Example workflows created successfully!"
echo ""
echo "📱 Access N8N at: http://localhost:5678"
echo ""
echo "💡 Example workflows available:"
echo "   1. AI Photo Analysis - Manual trigger to analyze photos with LLaVA"
echo "   2. AI Code Assistant - Webhook endpoint for coding help"
echo ""
echo "🧪 Test the coding webhook:"
echo "   curl -X POST http://localhost:5678/webhook/coding-help \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"question\": \"Write a Python function to resize images\"}'"
echo ""
