.PHONY: help setup-web install generate watch run-web run run-ios test clean build-android build-ios build-web share-ngrok share-cloudflare

help:
	@echo "Symplus Finance - Flutter App"
	@echo ""
	@echo "Comandos disponíveis:"
	@echo "  make setup-web     - Habilita suporte web (execute primeiro!)"
	@echo "  make install       - Instala dependências"
	@echo "  make generate      - Gera código (freezed, json_serializable)"
	@echo "  make run-web       - Executa o app no Chrome (web)"
	@echo "  make run-web-share - Executa app preparado para compartilhar (ngrok/cloudflare)"
	@echo "  make run           - Executa o app (Android)"
	@echo "  make run-ios       - Executa o app (iOS)"
	@echo "  make test          - Executa testes"
	@echo "  make clean         - Limpa build files"
	@echo "  make build-android - Build APK/AAB para Android"
	@echo "  make build-ios     - Build para iOS"
	@echo "  make build-web     - Build web para deploy"
	@echo "  make share-ngrok   - Compartilha app via ngrok (requer ngrok instalado)"
	@echo "  make share-cloudflare - Compartilha app via Cloudflare Tunnel"

setup-web:
	@echo "Habilitando suporte web..."
	flutter create . --platforms=web
	@echo "✅ Suporte web habilitado!"

install:
	@echo "Instalando dependências..."
	flutter pub get

generate:
	@echo "Gerando código..."
	flutter pub run build_runner build --delete-conflicting-outputs

watch:
	@echo "Gerando código (watch mode)..."
	flutter pub run build_runner watch --delete-conflicting-outputs

run-web:
	@echo "Executando app no Chrome (web)..."
	flutter run -d chrome

run-web-share:
	@echo "Executando app no Chrome (web) - preparado para compartilhar..."
	@echo "⚠️  Use este comando quando for compartilhar via ngrok/cloudflare"
	@flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

run:
	@echo "Executando app (Android)..."
	flutter run

run-ios:
	@echo "Executando app (iOS)..."
	flutter run -d ios

test:
	@echo "Executando testes..."
	flutter test

clean:
	@echo "Limpando build files..."
	flutter clean
	flutter pub get

build-android:
	@echo "Building Android APK..."
	@echo "⚠️  Para dispositivo físico, configure o IP do backend:"
	@echo "   flutter build apk --release --dart-define=API_BASE_URL=http://SEU_IP:8000"
	flutter build apk --release

build-android-device:
	@echo "Building Android APK para dispositivo físico..."
	@echo "⚠️  Configure SEU_IP com o IP da sua máquina na rede local"
	@read -p "Digite o IP do backend (ex: 192.168.1.100): " IP; \
	flutter build apk --release --dart-define=API_BASE_URL=http://$$IP:8000

build-ios:
	@echo "Building iOS..."
	flutter build ios --release

build-web:
	@echo "Building web app for deployment..."
	flutter build web --release
	@echo "✅ Build completo! Arquivos em: build/web"
	@echo "📦 Pronto para deploy em Vercel, Netlify ou Firebase Hosting"

share-ngrok:
	@echo "🌐 Compartilhando app via ngrok..."
	@echo "⚠️  Certifique-se que:"
	@echo "   1. O app está rodando em outro terminal: make run-web-share"
	@echo "   2. O backend está acessível (se usar API)"
	@echo "   3. O ngrok está instalado e configurado"
	@echo ""
	@echo "💡 Se receber erro 502, verifique se usou: make run-web-share"
	@echo ""
	@read -p "Pressione Enter para continuar..." dummy
	ngrok http 8080

share-cloudflare:
	@echo "🌐 Compartilhando app via Cloudflare Tunnel..."
	@echo "⚠️  Certifique-se que:"
	@echo "   1. O app está rodando em outro terminal: make run-web-share"
	@echo "   2. O backend está acessível (se usar API)"
	@echo "   3. O cloudflared está instalado"
	@echo ""
	@echo "💡 Se receber erro 502, verifique se usou: make run-web-share"
	@echo ""
	@read -p "Pressione Enter para continuar..." dummy
	cloudflared tunnel --url http://localhost:8080

