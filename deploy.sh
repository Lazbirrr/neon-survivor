#!/bin/bash
set -e

echo "🎮 NEON SURVIVOR - Déploiement"
echo "══════════════════════════════"

echo ""
echo "📦 Création du fichier .love..."
zip -r NEON_SURVIVOR.love main.lua
echo "✅ NEON_SURVIVOR.love créé"

echo ""
echo "🌐 Compilation pour le web..."

if ! command -v npx &> /dev/null; then
    echo "❌ Node.js n'est pas installé. Installe-le depuis https://nodejs.org"
    exit 1
fi

rm -rf web-build-flat
npx love.js NEON_SURVIVOR.love web-build-flat -c --title "NEON SURVIVOR" 2>/dev/null

cp web-build-flat/theme/*.css web-build-flat/theme/*.png web-build-flat/ 2>/dev/null || true
sed -i '' 's|theme/love.css|love.css|g' web-build-flat/index.html 2>/dev/null || true
rm -rf web-build-flat/theme

rm -f NEON_SURVIVOR_web.zip
cd web-build-flat
zip -r ../NEON_SURVIVOR_web.zip . -x "*.DS_Store"
cd ..

echo "✅ NEON_SURVIVOR_web.zip créé"

echo ""
echo "══════════════════════════════"
echo "🚀 DÉPLOIEMENT TERMINÉ!"
echo "══════════════════════════════"
echo ""
echo "Fichiers créés :"
ls -lh NEON_SURVIVOR.love NEON_SURVIVOR_web.zip
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Commit sur GitHub : git add . && git commit -m 'Update game' && git push"
echo "   2. Sur itch.io : Upload NEON_SURVIVOR_web.zip"
echo "   3. Coche 'This file will be played in the browser'"
echo "   4. Taille : 1000 x 700"
echo "   5. Sauvegarde et teste !"
echo ""
echo "🎮 Pour jouer en local : glisse NEON_SURVIVOR.love sur l'app LÖVE"
