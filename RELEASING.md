# Releasing

Tags on this repo are consumed via Swift Package Manager by downstream
projects (notably Dasher-Apple). SPM pins the exact SHA of a tag into
`Package.resolved`, so **moving or deleting a published tag breaks every
downstream consumer's CI** the next time they resolve from scratch.

## The rule

> **Tags are immutable. Once `1.13.15` (or any version) is pushed, it stays
> where it is forever — even if the release it points at is broken.**

`main` can be force-pushed, rewritten, rebased — that's fine, no one should
be resolving against `main` directly. Tags cannot.

This rule exists because of the recurring "Package.resolved phantom
revision" failure that has hit Dasher-Apple CI at least three times
(Dasher-Apple commits `7f9881c`, `51d6d9c`, `4466828`). Each one was caused
by force-pushing `main` and moving the `1.13.15` tag while SwiftPM had
pinned to an earlier SHA on the same tag.

## Cutting a new release

When you have a new set of artifacts (rebuilt xcframeworks, checksum fixes,
etc.) and want to publish:

```sh
# 1. Make sure main is in the state you want to release.
git checkout main
git pull

# 2. Bump the version referenced in README / docs if needed. (The
#    Package.swift `version` constant is the *sherpa-onnx* upstream version
#    we wrap, not the SPM package version — the SPM version comes from git
#    tags.)

# 3. Commit any pending changes.
git commit -m "Bump to 1.13.16"

# 4. Push main first (non-force).
git push origin main

# 5. Cut the tag via gh. Use --title and --notes so the release page on
#    GitHub explains what changed. NEVER use --target to override an
#    existing tag.
gh release create 1.13.16 \
    --title "1.13.16" \
    --notes "Fix checksums for X" \
    --verify-tag

# 6. Verify the tag points where you think it does.
gh api repos/willwade/sherpa-onnx-spm/git/refs/tags/1.13.16
```

The downstream project (Dasher-Apple) will resolve to the new tag the next
time Xcode re-resolves packages or someone runs `swift package resolve`.

## Fixing a broken release

**Do not move the tag.** Cut a new patch version instead:

```sh
# Suppose 1.13.16 was just published but the checksums are wrong.
# DON'T DO THIS:
git commit --amend
git tag -f 1.13.16
git push --force origin main 1.13.16    # ← breaks every downstream pin

# DO THIS:
git commit -m "Fix checksums — release as 1.13.17"
git push origin main
gh release create 1.13.17 \
    --title "1.13.17" \
    --notes "Corrects checksums broken in 1.13.16; do not use 1.13.16."

# (Optional) Mark 1.13.16 as a broken release on GitHub so nobody else
# picks it up:
gh release edit 1.13.16 \
    --notes "BROKEN — checksum mismatch. Use 1.13.17 or later."
```

The broken tag stays where it was. Anyone who already resolved against it
keeps working. Anyone who resolves fresh picks up the new tag.

## Optional local enforcement

A `pre-push` hook that refuses force-pushes to tags prevents the mistake
from ever leaving your machine. Install it once:

```sh
./scripts/install-pre-push-hook.sh
```

See `scripts/pre-push-protect-tags` for what it checks.
