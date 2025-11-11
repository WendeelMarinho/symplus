#!/bin/bash

# Script para inicializar o repositório Git e fazer push para o remoto

echo "Inicializando repositório Git..."
git init

echo "Adicionando remote..."
git remote add origin https://github.com/WendeelMarinho/symplus.git

echo "Adicionando arquivos ao staging..."
git add .

echo "Fazendo commit inicial..."
git commit -m "Initial commit: Symplus Finance - Plataforma de gestão financeira multi-tenant"

echo "Configurando branch main..."
git branch -M main

echo "Fazendo push para o repositório remoto..."
git push -u origin main

echo "✅ Concluído!"

