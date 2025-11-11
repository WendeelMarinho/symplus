#!/bin/bash

# Script para compartilhar o app Flutter web facilmente
# Uso: ./scripts/share-app.sh [ngrok|cloudflare|local]

set -e

PORT=8080
METHOD=${1:-ngrok}

echo "🌐 Compartilhando Symplus Finance App"
echo "======================================"
echo ""

# Verificar se o app está rodando
if ! lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  O app não está rodando na porta $PORT"
    echo ""
    echo "Execute primeiro em outro terminal:"
    echo "  cd app"
    echo "  flutter run -d chrome --web-port=$PORT"
    echo ""
    read -p "Pressione Enter para continuar mesmo assim..." dummy
fi

case $METHOD in
    ngrok)
        echo "📡 Iniciando túnel via ngrok..."
        if ! command -v ngrok &> /dev/null; then
            echo "❌ ngrok não está instalado!"
            echo ""
            echo "Instale com:"
            echo "  snap install ngrok"
            echo "  # ou"
            echo "  curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc"
            echo "  echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list"
            echo "  sudo apt update && sudo apt install ngrok"
            echo ""
            echo "Configure com: ngrok config add-authtoken SEU_TOKEN"
            exit 1
        fi
        echo "🌐 Túnel criado! Acesse a URL mostrada abaixo:"
        echo ""
        ngrok http $PORT
        ;;
    
    cloudflare|cloudflared)
        echo "📡 Iniciando túnel via Cloudflare..."
        if ! command -v cloudflared &> /dev/null; then
            echo "❌ cloudflared não está instalado!"
            echo ""
            echo "Instale com:"
            echo "  snap install cloudflared"
            echo "  # ou"
            echo "  wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
            echo "  chmod +x cloudflared-linux-amd64"
            echo "  sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared"
            exit 1
        fi
        echo "🌐 Túnel criado! Acesse a URL mostrada abaixo:"
        echo ""
        cloudflared tunnel --url http://localhost:$PORT
        ;;
    
    local)
        echo "🖥️  Modo servidor local (mesma rede)"
        echo ""
        IP=$(hostname -I | awk '{print $1}')
        echo "✅ App acessível em: http://$IP:$PORT"
        echo ""
        echo "⚠️  Certifique-se que:"
        echo "   1. O firewall permite conexões na porta $PORT"
        echo "   2. O backend também está acessível (se necessário)"
        echo "   3. Todos estão na mesma rede WiFi"
        echo ""
        echo "Para permitir conexões externas, execute:"
        echo "  flutter run -d chrome --web-hostname=0.0.0.0 --web-port=$PORT"
        ;;
    
    *)
        echo "❌ Método inválido: $METHOD"
        echo ""
        echo "Uso: ./scripts/share-app.sh [ngrok|cloudflare|local]"
        echo ""
        echo "Métodos disponíveis:"
        echo "  ngrok      - Túnel público via ngrok (requer conta)"
        echo "  cloudflare - Túnel público via Cloudflare (gratuito)"
        echo "  local      - Servidor local (mesma rede)"
        exit 1
        ;;
esac

