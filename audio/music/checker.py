import os
from mutagen import File


def get_duration(path):
    try:
        audio = File(path)
        if audio is None or not hasattr(audio, 'info'):
            return None
        return audio.info.length  # seconds (float)
    except Exception:
        return None


def main():
    cwd = os.getcwd()
    ogg_files = [f for f in os.listdir(cwd) if f.lower().endswith('.ogg')]

    if not ogg_files:
        print("No .ogg files found in current directory.")
        return

    print(f"Found {len(ogg_files)} .ogg file(s):\n")

    for file in ogg_files:
        path = os.path.join(cwd, file)
        duration = get_duration(path)

        if duration is None:
            print(f"{file}: could not read duration")
            continue

        ms = duration * 1000
        print(f"{file}: {duration:.3f} sec ({ms:.0f} ms)")


if __name__ == "__main__":
    main()