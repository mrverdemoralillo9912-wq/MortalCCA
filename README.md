# Mortal CCA

Prototipo jugable en **Godot 4.x** (GDScript). Requiere Godot 4.3 o superior.

## Como abrirlo
1. Abre Godot Engine 4.x.
2. "Import" -> selecciona la carpeta `MortalCCA` (el archivo `project.godot`).
3. Presiona Play (F5). La escena inicial es `scenes/MainMenu.tscn`.

## Que incluye este prototipo

- **Menu principal**: botones "Comenzar Nuevo Juego" y "Digitaliza tu Apodo"
  (ventana para escribir tu nombre, se guarda en el GameManager).
- **3 personajes**: Conserje (por defecto, el mas debil pero principal),
  Profesor y Directora (se desbloquean en la tienda con monedas). Usan tus
  3 imagenes originales (recortadas y con fondo transparente).
- **Patio unico** con ninos que deambulan y botan basura periodicamente
  (usando tus 56 sprites de basura, recortados automaticamente de tu hoja).
- **Batallas por turnos** estilo Pokemon: cada personaje tiene 3
  habilidades con poder/precision distintos; el nino contraataca.
- **Reflexion**: al ganar una batalla, acercate al nino y presiona **E**
  para hablar con el; obtienes monedas y una frase de reflexion aleatoria.
- **Recoleccion de basura**: presiona **E** cerca de un objeto tirado para
  recogerlo, y **E** cerca del basurero para depositarla (+2 monedas c/u).
- **Ninos especiales**: veloz (⚡), botabasura (🗑) y fortachon (💪), con
  probabilidad creciente segun el dia.
- **Ciclo de dias infinito**: 2 recesos por dia; al terminar el receso 2
  avanza el dia y la dificultad escala (mas ninos, mas variados).
- **Ninos reformados**: al reflexionar, un nino tiene 25% de probabilidad
  de "recordarse" y puede reaparecer en dias futuros como aliado (da
  monedas extra una vez por dia).
- **Tienda** (acercate al kiosco cafe y presiona E): desbloquea Profesor y
  Directora, y compra herramientas (iman de basura, bolsa grande, botas
  veloces).

## Controles
- **WASD / Flechas**: moverse.
- **E**: interactuar (recoger basura, depositar en basurero, retar a un
  nino, hablar/reflexionar, entrar/salir de la tienda, avanzar dialogos).

## Estructura
```
MortalCCA/
├── project.godot
├── scenes/
│   ├── MainMenu.tscn
│   └── Main.tscn
├── scripts/
│   ├── GameManager.gd   (autoload: monedas, dias, personajes, tienda)
│   ├── MainMenu.gd
│   ├── Main.gd          (orquesta el patio, el ciclo de dias, etc.)
│   ├── Player.gd
│   ├── Kid.gd           (IA de ninos + dibujo procedural)
│   ├── TrashItem.gd
│   ├── Battle.gd        (sistema de batalla por turnos)
│   ├── Dialogue.gd      (reflexion / saludo de aliados)
│   └── Shop.gd
└── assets/
    ├── characters/ (conserje.png, profesor.png, director.png)
    └── trash/      (56 sprites recortados de tu hoja de basura)
```

## Limitaciones y proximos pasos sugeridos
Este es un **prototipo funcional completo** con todos los sistemas que
pediste conectados entre si, pero como no incluiste sprites especificos
de "ninos", esos personajes se dibujan de forma procedural (figuras de
colores con iconos) en vez de arte pixel-art dedicado. Si me pasas sprites
de ninos (idealmente en el mismo estilo pixel-art que tus 3 personajes),
puedo reemplazar `Kid._draw()` por sprites reales con animaciones.

Otras mejoras posibles a futuro:
- Animaciones mas elaboradas con AnimationPlayer y spritesheets reales
  (ahora mismo las animaciones son de rebote/inclinacion proceduales,
  ya que solo hay 1 imagen estatica por personaje).
- Guardado/carga de partida en disco (ahora el progreso vive en memoria
  durante la sesion).
- Mas variedad de dialogos y habilidades por dia.
- Sonidos y musica.
