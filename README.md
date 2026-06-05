# nemo-ffmpeg

Acciones de menú contextual para [Nemo](https://github.com/linuxmint/nemo) que usan **ffmpeg** para convertir audio y preparar vídeos para WhatsApp.

![test](https://github.com/pablogventura/nemo-ffmpeg/actions/workflows/test.yml/badge.svg)

## Acciones

| Menú en Nemo | Qué hace | Archivo generado |
|--------------|----------|------------------|
| **FFmpeg: Convertir a MP3** | Convierte audio o extrae el audio de un vídeo | `nombre.mp3` (misma carpeta) |
| **FFmpeg: WhatsApp (chat)** | MP4 ≤ 16 MB, H.264 + AAC, ~720p, preview en el chat | `nombre-whatsapp.mp4` |
| **FFmpeg: WhatsApp (documento)** | MP4 compatible, alta calidad, hasta 2 GB como documento | `nombre-whatsapp-doc.mp4` |

Las acciones de vídeo solo aparecen al hacer clic derecho sobre archivos de vídeo. La de MP3 aparece en audio y en vídeos (para extraer la pista de audio).

Si el archivo de salida **ya existe**, se omite (no se sobrescribe). Para forzar sobrescritura en terminal:

```bash
MENU_FFMPEG_FORCE=1 ~/.local/share/nemo-ffmpeg/lib/convert-to-mp3.sh archivo.flac
```

## Requisitos

- [Nemo](https://github.com/linuxmint/nemo) (gestor de archivos de Cinnamon / Linux Mint)
- `ffmpeg` y `ffprobe`
- `libnotify-bin` (opcional, para notificaciones al terminar)

En Debian / Ubuntu / Linux Mint:

```bash
sudo apt install ffmpeg libnotify-bin nemo
```

## Instalación

```bash
git clone https://github.com/pablogventura/nemo-ffmpeg.git
cd nemo-ffmpeg
./install.sh
```

Instalación rápida en una línea:

```bash
git clone https://github.com/pablogventura/nemo-ffmpeg.git /tmp/nemo-ffmpeg && /tmp/nemo-ffmpeg/install.sh
```

El instalador copia los scripts a `~/.local/share/nemo-ffmpeg/` y registra tres acciones en `~/.local/share/nemo/actions/`.

Si no ves las acciones nuevas, reinicia Nemo:

```bash
nemo --quit
```

## Uso

1. Abre Nemo y selecciona uno o más archivos.
2. Clic derecho → elige la acción **FFmpeg: …**
3. Se abre una terminal con el progreso de ffmpeg.
4. Al terminar recibes una notificación con el resumen (convertidos / omitidos / errores).

También puedes ejecutar los scripts directamente:

```bash
~/.local/share/nemo-ffmpeg/lib/convert-to-mp3.sh musica.flac
~/.local/share/nemo-ffmpeg/lib/video-whatsapp-chat.sh clip.mp4
~/.local/share/nemo-ffmpeg/lib/video-whatsapp-document.sh clip.mkv
```

## Desinstalación

```bash
cd nemo-ffmpeg   # carpeta del clone
./install.sh uninstall
```

## Comprobar instalación

```bash
./install.sh status
```

## Tests

```bash
./test.sh
```

Genera fixtures temporales en `tests/tmp/` y ejecuta pruebas de los scripts y del instalador (sin tocar tu `HOME` real en los tests de install).

## Límites de WhatsApp

| Modo | Tamaño | Uso |
|------|--------|-----|
| **Chat (multimedia)** | ≤ 16 MB | Se reproduce en el chat con miniatura |
| **Documento** | ≤ 2 GB | Mayor calidad; el destinatario descarga para ver |

El modo chat calcula el bitrate según la duración del vídeo. Si no cabe en 16 MB incluso tras un reintento con menor calidad, verás un error en la terminal (prueba el modo documento o recorta el vídeo).

## Licencia

MIT — ver [LICENSE](LICENSE).
