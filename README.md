# Cubemancy

Prototype **Godot 4** de survie Cube World-like, pensé **iPhone** (joystick tactile). Pas d’app Swift, pas de Steam.

**Cubemancy** · *Survive. Cast. Cube.* · **Jouer**

Choisis une classe (**Feu**, **Glace** ou **Foudre**) avant de lancer. Un seul sort de classe. **Rejouer** garde la classe.

## Ouvrir dans Godot 4

1. Installe [Godot 4.4+](https://godotengine.org/download) (4.7 recommandé).
2. Importe le dossier du dépôt (`project.godot`).
3. Lance la scène `scenes/home.tscn` (scène principale).

Debug clavier (pas le livrable iPhone) : WASD, Espace, **E** = sort de classe, **F** = frapper.

## Jouer (HTML5 / GitHub Pages)

Le build web (sans threads, compatible GitHub Pages et Safari iPhone) est dans `docs/`.

- En local : `python3 -m http.server 8080 --directory docs` puis ouvrir http://localhost:8080
- En ligne : https://jprivard-baam.github.io/mage-duel/

## Exporter HTML5 depuis Godot

1. Éditeur → Gérer les modèles d’export… → installer les templates de **ta** version Godot.
2. Projet → Exporter → preset **Web** (déjà dans `export_presets.cfg`).
3. **Important** : décocher le support des threads (GitHub Pages n’envoie pas les en-têtes COOP/COEP).
4. Exporter vers `docs/index.html`.

```bash
godot --headless --path . --export-release "Web" docs/index.html
```

## iOS (plus tard)

L’export iPhone se fait depuis Godot (preset iOS + Xcode), sans réécrire le jeu. Steam n’est pas dans le v1.

## Gameplay v1

- Accueil : choix de classe Feu / Glace / Foudre, puis **Jouer**.
- Mobile : **Sort** (sort de la classe), **Frapper** (ennemis ou arbres → Bois), **Saut**.
- Mage cubique 3e personne, monde voxel **96×96**, cubes **0,5**.
- Terrain seulement : **terre**, **roche**, **arbres**.
- Survie : PV, faim, mana, jour/nuit, cubes hostiles la nuit.
- Mort : « Vous êtes mort » + **Rejouer** (même classe).
