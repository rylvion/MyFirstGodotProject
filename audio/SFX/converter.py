import os
import sys
import shutil
import subprocess

def convert_mp3_to_ogg(folder="."):
    backup_folder = os.path.join(folder, "mp3_backup")
    os.makedirs(backup_folder, exist_ok=True)

    converted = 0
    skipped = 0
    failed = 0

    for root, _, files in os.walk(folder):
        for file in files:

            # only mp3 files
            if not file.lower().endswith(".mp3"):
                continue

            mp3_path = os.path.join(root, file)

            # skip backup folder itself
            if backup_folder in mp3_path:
                continue

            ogg_path = os.path.splitext(mp3_path)[0] + ".ogg"

            try:
                # copy original to backup first
                relative_path = os.path.relpath(mp3_path, folder)
                backup_path = os.path.join(backup_folder, relative_path)
                os.makedirs(os.path.dirname(backup_path), exist_ok=True)

                if not os.path.exists(backup_path):
                    shutil.copy2(mp3_path, backup_path)

                # skip if ogg already exists
                if os.path.exists(ogg_path):
                    print(f"skipping (exists): {ogg_path}")
                    skipped += 1
                    continue

                print(f"converting: {mp3_path}")

                result = subprocess.run([
                    "ffmpeg",
                    "-y",
                    "-i", mp3_path,
                    "-c:a", "libvorbis",
                    "-q:a", "4",
                    ogg_path
                ], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)

                if result.returncode != 0:
                    print(f"failed: {mp3_path}")
                    print(result.stderr.decode("utf-8", errors="ignore"))
                    failed += 1
                    continue

                converted += 1

            except Exception as e:
                print(f"error processing {mp3_path}: {e}")
                failed += 1

    print("\n--- done ---")
    print(f"converted: {converted}")
    print(f"skipped: {skipped}")
    print(f"failed: {failed}")
    print(f"backup folder: {backup_folder}")


if __name__ == "__main__":
    folder = sys.argv[1] if len(sys.argv) > 1 else "."
    convert_mp3_to_ogg(folder)