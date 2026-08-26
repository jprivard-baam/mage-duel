# Mage Duel — Survie en cubes

Prototype **Godot 4** de survie Cube World-like, pensé **iPhone** (joystick tactile). Pas d’app Swift, pas de Steam.

Titre : **Mage Duel** · sous-titre **Survie en cubes** · bouton **Jouer**.

## Ouvrir dans Godot 4

1. Installe [Godot 4.4+](https://godotengine.org/download) (4.7 recommandé).
2. Importe le dossier du dépôt (`project.godot`).
3. Lance la scène `scenes/home.tscn` (scène principale).

Commandes debug clavier (pas le livrable iPhone) : WASD, Espace, E/F couper, 1/2/3 sorts.

## Jouer (HTML5 / GitHub Pages)

Le build web (sans threads, compatible GitHub Pages et Safari iPhone) est dans `docs/`.

- En local : `python3 -m http.server 8080 --directory docs` puis ouvrir http://localhost:8080
- En ligne : https://jprivard-baam.github.io/mage-duel/

## Exporter HTML5 depuis Godot

1. Éditeur → Gérer les modèles d’export… → installer les templates de **ta** version Godot.
2. Projet → Exporter → preset **Web** (déjà dans `export_presets.cfg`).
3. **Important** : décocher le support des threads (GitHub Pages n’envoie pas les en-têtes COOP/COEP).
4. Exporter vers `docs/index.html`.

En ligne de commande :

```bash
godot --headless --path . --export-release "Web" docs/index.html
```

## iOS (plus tard)

L’export iPhone se fait depuis Godot (preset iOS + Xcode), sans réécrire le jeu. Ce proto n’inclut pas encore de certificats ni de preset iOS.

Steam n’est pas dans le v1 : Godot pourra exporter desktop plus tard, sans rewrite.

## Gameplay v1

- Mage cubes, 3e personne, monde voxel **96×96**, cubes **deux fois plus petits** qu’un proto 48 « chunky ».
- Terrain seulement : **terre**, **roche**, **arbres** (tronc + feuilles cubes). Pas d’eau, grottes, sable, neige.
- Joystick gauche, glisser à droite pour regarder (swipe droite = regarder à droite, joystick droite = strafe droite).
- Le mage fait face à la direction du regard ; **Feu / Glace / Foudre** partent devant lui.
- **Couper** un arbre (bois + feuilles) → objets **Bois** dans l’inventaire.
- Survie : PV, faim, mana, jour/nuit, cubes hostiles la nuit.
- Mort : « Vous êtes mort » + **Rejouer**.
