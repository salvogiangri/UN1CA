# [
EXTREMEKRNL_REPO="https://github.com/ExtremeXT/990_upstream_v2/"

BUILD_KERNEL()
{
    local PARENT=$(pwd)
    cd $KERNEL_TMP_DIR

    EVAL "./build.sh -m ${TARGET_CODENAME} -k y -r n"

    # Fixup for LTE devices
    EVAL "./build.sh -m ${TARGET_CODENAME}lte -k n -r n -d y"

    cd $PARENT
}

SAFE_PULL_CHANGES()
{
    set -eo pipefail

    local PARENT=$(pwd)

    cd "$KERNEL_TMP_DIR"

    EVAL "git fetch origin"

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse origin/main)
    BASE=$(git merge-base @ origin/main)

    # Now we have three cases that we need to take care of.
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        LOG "- Local branch is up-to-date with remote."
    elif [[ "$LOCAL" == "$BASE" ]]; then
        LOG "- Fast-forward possible. Pulling."
        EVAL "git pull --ff-only"
    elif [[ "$REMOTE" == "$BASE" ]]; then
        LOGW "- Local branch is ahead of remote. Not doing anything."
    else
        cd "$PARENT"
        ABORT "Remote history has diverged (possible force-push)."
    fi

    cd "$PARENT"
}

REPLACE_KERNEL_BINARIES()
{
    local KERNEL_TMP_DIR="$KERNEL_TMP_DIR-$TARGET_PLATFORM"
    [[ ! -d "$KERNEL_TMP_DIR" ]] && mkdir -p "$KERNEL_TMP_DIR"

    if [[ -d "$KERNEL_TMP_DIR/.git" ]]; then
        LOG "- Existing git repo found, trying to pull latest changes"
        if ! SAFE_PULL_CHANGES; then
            ABORT "Could not pull latest Kernel changes. If you hold local changes, please rebase to the new base. If not, cleaning the kernel_tmp_dir should suffice."
        fi
    else
        LOG "- Cloning ExtremeKernel"
        EVAL "git clone "$EXTREMEKRNL_REPO" --single-branch "$KERNEL_TMP_DIR" --recurse-submodules"
    fi

    LOG "- Running the kernel build script."
    BUILD_KERNEL

    for i in "boot" "dtbo"; do
        [[ -f "$WORK_DIR/kernel/$i.img" ]] && rm -f "$WORK_DIR/kernel/$i.img"
        mv -f "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/$i.img" "$WORK_DIR/kernel/$i.img"
    done

    # And now for the LTE DTBOs
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
	    mv -f "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" "$WORK_DIR/kernel/dtbo_lte.img"
    fi
}
# ]

REPLACE_KERNEL_BINARIES
