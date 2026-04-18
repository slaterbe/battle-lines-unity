# Battle Lines Unity

This project includes a small Unity editor build window and a few helper scripts for packaging and distributing Steam Deck builds through GitHub Releases.

## Build Buttons In Unity

Open the custom build window in the Unity editor:

```text
Tools > Builds > Open Build Buttons
```

This window provides two buttons:

- `Build Steam Deck`
  Writes the Linux build output to `steam-deck-build/`
- `Build Web`
  Writes the WebGL build output to `web-build/`

Both output folders are ignored by git.

## Upload A Steam Deck Build To GitHub Releases

The upload script packages `steam-deck-build/` into a zip file, creates a GitHub release if needed, and uploads the zip as a release asset.

Script:

```bash
./scripts/upload-github-release.sh <tag> [notes]
```

Examples:

```bash
./scripts/upload-github-release.sh v0.1.0
./scripts/upload-github-release.sh v0.1.0 "Steam Deck playtest build"
```

Requirements:

- `gh` must be installed and authenticated
- `zip` must be available
- `steam-deck-build/` must already exist

Install GitHub CLI on macOS with Homebrew:

```bash
brew install gh
gh auth login
```

Optional environment variables:

- `GITHUB_REPOSITORY`
  Override the repo slug. Default: `slaterbe/battle-lines-unity`
- `RELEASE_TITLE`
  Override the GitHub release title. Default: the tag
- `ASSET_NAME`
  Override the uploaded zip filename. Default: `battle-lines-steam-deck-<tag>.zip`

Example with overrides:

```bash
GITHUB_REPOSITORY=slaterbe/battle-lines-unity \
RELEASE_TITLE="Battle Lines v0.1.0" \
ASSET_NAME="battle-lines-steam-deck.zip" \
./scripts/upload-github-release.sh v0.1.0 "Steam Deck build"
```

## Download On Steam Deck

If the repo is already cloned on the Steam Deck, you can use:

```bash
./scripts/download-steam-deck-release.sh
```

Or download a specific tag:

```bash
./scripts/download-steam-deck-release.sh v0.1.0
```

What this script does:

- downloads the latest release by default, or a specific tag
- finds a zip asset whose name contains `steam-deck`
- extracts it into `~/Downloads/battle-lines/<tag>/`
- sets executable permission on any `*.x86_64` file it finds

## One-Line Steam Deck Installer

If you want to install on a Steam Deck without cloning the repo first, use the standalone installer script from the `main` branch:

```bash
curl -fsSL https://raw.githubusercontent.com/slaterbe/battle-lines-unity/main/scripts/steam-deck-installer.sh | bash
```

For a specific release tag:

```bash
curl -fsSL https://raw.githubusercontent.com/slaterbe/battle-lines-unity/main/scripts/steam-deck-installer.sh | bash -s -- v0.1.0
```

This downloads the release asset, extracts it into `~/Downloads/battle-lines/<tag>/`, and marks the Linux executable as runnable.

## Set Execution Permission Manually

If needed, you can manually make the Steam Deck executable runnable with:

```bash
chmod +x steam-deck-build/steam-deck.x86_64
```

To verify:

```bash
ls -l steam-deck-build/steam-deck.x86_64
```

## Script Summary

- [scripts/upload-github-release.sh](/Users/benjamin/Developer/personal/battle-lines-web-v2/scripts/upload-github-release.sh:1)
  Package and upload `steam-deck-build/` to a GitHub release
- [scripts/download-steam-deck-release.sh](/Users/benjamin/Developer/personal/battle-lines-web-v2/scripts/download-steam-deck-release.sh:1)
  Download and extract a release from a cloned repo checkout
- [scripts/steam-deck-installer.sh](/Users/benjamin/Developer/personal/battle-lines-web-v2/scripts/steam-deck-installer.sh:1)
  One-line installer script for direct use on Steam Deck
