<?php

/**
 * Script para testar CORS no backend
 * Execute: php scripts/test-cors.php
 */

$url = 'https://srv1113923.hstgr.cloud/api/health';
$origin = 'http://localhost:39801';

echo "🧪 Testando CORS para: $url\n";
echo "📍 Origin: $origin\n\n";

// Teste 1: Preflight OPTIONS
echo "1️⃣ Testando Preflight OPTIONS...\n";
$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST => 'OPTIONS',
    CURLOPT_HTTPHEADER => [
        "Origin: $origin",
        'Access-Control-Request-Method: GET',
        'Access-Control-Request-Headers: content-type,accept',
    ],
    CURLOPT_HEADER => true,
    CURLOPT_NOBODY => true,
    CURLOPT_SSL_VERIFYPEER => false, // Apenas para teste
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$headers = substr($response, 0, $headerSize);

curl_close($ch);

echo "   Status: $httpCode\n";
echo "   Headers:\n";
foreach (explode("\r\n", $headers) as $header) {
    if (stripos($header, 'access-control') !== false) {
        echo "      ✅ $header\n";
    }
}

if ($httpCode === 204 || $httpCode === 200) {
    echo "   ✅ Preflight OK\n";
} else {
    echo "   ❌ Preflight falhou\n";
}

echo "\n";

// Teste 2: Requisição GET normal
echo "2️⃣ Testando GET normal...\n";
$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        "Origin: $origin",
        'Content-Type: application/json',
        'Accept: application/json',
    ],
    CURLOPT_HEADER => true,
    CURLOPT_SSL_VERIFYPEER => false, // Apenas para teste
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$headers = substr($response, 0, $headerSize);
$body = substr($response, $headerSize);

curl_close($ch);

echo "   Status: $httpCode\n";
echo "   Headers CORS:\n";
foreach (explode("\r\n", $headers) as $header) {
    if (stripos($header, 'access-control') !== false) {
        echo "      ✅ $header\n";
    }
}

if ($httpCode === 200) {
    echo "   ✅ GET OK\n";
    echo "   Body: $body\n";
} else {
    echo "   ❌ GET falhou\n";
}

echo "\n";
echo "📋 Resumo:\n";
echo "   Se os headers CORS aparecerem acima, o backend está configurado corretamente.\n";
echo "   Se não aparecerem, verifique:\n";
echo "   1. Se o CorsMiddleware está registrado em bootstrap/app.php\n";
echo "   2. Se o cache do Laravel foi limpo\n";
echo "   3. Se o servidor foi reiniciado\n";

