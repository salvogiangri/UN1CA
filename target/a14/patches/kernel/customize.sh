LOG "- Replacing kernel with langsdorffkernel"

# Fetch latest release info from GitHub API
GITHUB_API="https://api.github.com/repos/clangsdorff/langsdorffkernel/releases/latest"
RELEASE_JSON=$(curl -sf "$GITHUB_API") || { LOG "ERROR: Failed to fetch GitHub API"; exit 1; }

TAG=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*en_a14\.tar"' | head -1 | cut -d'"' -f4)

[ -z "$TAG" ]       && { LOG "ERROR: Failed to get release tag";        exit 1; }
[ -z "$ASSET_URL" ] && { LOG "ERROR: Could not find e_a14.tar asset";   exit 1; }

LOG "- Found langsdorff release: $TAG"
LOG "- Downloading: $(basename "$ASSET_URL")"

KERNEL_TMP="$WORK_DIR/kernel/langsdorff_tmp"
mkdir -p "$KERNEL_TMP"

TARBALL="$KERNEL_TMP/langsdorffkernel.tar"
curl -L --progress-bar -o "$TARBALL" "$ASSET_URL" || { LOG "ERROR: Download failed"; exit 1; }

LOG "- Extracting kernel images..."
tar -xf "$TARBALL" -C "$KERNEL_TMP" || { LOG "ERROR: Failed to extract tar"; exit 1; }

# Unpack .lz4 images
for LZ4_FILE in boot.img.lz4 vendor_boot.img.lz4 vbmeta.img.lz4; do
    SRC="$KERNEL_TMP/$LZ4_FILE"
    DEST="$WORK_DIR/kernel/${LZ4_FILE%.lz4}"
    [ -f "$SRC" ] || { LOG "ERROR: $LZ4_FILE not found in archive"; exit 1; }
    lz4 -d -f "$SRC" "$DEST" || { LOG "ERROR: Failed to unpack $LZ4_FILE"; exit 1; }
    LOG "  - Unpacked: $LZ4_FILE -> $(basename "$DEST")"
done

rm -rf "$KERNEL_TMP"
LOG "- langsdorffkernel ($TAG) installation finished"