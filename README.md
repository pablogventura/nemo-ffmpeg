# nemo-ffmpeg

Acciones de menú contextual para [Nemo](https://github.com/linuxmint/nemo) que usan **ffmpeg** para convertir audio y preparar archivos para WhatsApp.

![test](https://github.com/pablogventura/nemo-ffmpeg/actions/workflows/test.yml/badge.svg)

## Acciones

| Menú en Nemo | Entrada | Archivo generado |
|--------------|---------|------------------|
| **FFmpeg: Convertir a MP3** | audio + vídeo | `nombre.mp3` |
| **FFmpeg: Audio WhatsApp (chat)** | solo audio | `nombre-whatsapp.mp3` (≤ 16 MB) |
| **FFmpeg: Audio WhatsApp (documento)** | solo audio | `nombre-whatsapp-doc.mp3` (≤ 2 GB) |
| **FFmpeg: Vídeo WhatsApp (chat)** | solo vídeo | `nombre-whatsapp.mp4` (≤ 16 MB) |
| **FFmpeg: Vídeo WhatsApp (documento)** | solo vídeo | `nombre-whatsapp-doc.mp4` (≤ 2 GB) |

Un mismo `.flac` puede generar hasta tres MP3 distintos sin pisarse: `cancion.mp3`, `cancion-whatsapp.mp3` y `cancion-whatsapp-doc.mp3`.

Las acciones **Audio WhatsApp** solo aparecen en archivos de audio. Las **Vídeo WhatsApp** solo en vídeos. **Convertir a MP3** también extrae audio de un vídeo.

Si el archivo de salida **ya existe**, se omite (no se sobrescribe). Para forzar sobrescritura desde terminal:

```bash
MENU_FFMPEG_FORCE=1 ~/.local/share/nemo-ffmpeg/lib/convert-to-mp3.sh archivo.flac
MENU_FFMPEG_FORCE=1 ~/.local/share/nemo-ffmpeg/lib/audio-whatsapp-chat.sh musica.flac
MENU_FFMPEG_FORCE=1 ~/.local/share/nemo-ffmpeg/lib/video-whatsapp-chat.sh clip.mp4
```

El modo **chat** (audio y vídeo) calcula el bitrate para caber en 16 MB. En audio, si no cabe en estéreo, reintenta en **mono** antes de fallar. El modo **vídeo chat** requiere pista de audio.

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

El instalador copia los scripts a `~/.local/share/nemo-ffmpeg/` y registra **cinco** acciones en `~/.local/share/nemo/actions/`.

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
~/.local/share/nemo-ffmpeg/lib/audio-whatsapp-chat.sh musica.flac
~/.local/share/nemo-ffmpeg/lib/audio-whatsapp-document.sh musica.flac
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

Si no cabe en 16 MB tras los reintentos (menor bitrate, mono en audio), verás un error en la terminal. Prueba el modo documento o recorta el archivo.

## Licencia

MIT — ver [LICENSE](LICENSE).
