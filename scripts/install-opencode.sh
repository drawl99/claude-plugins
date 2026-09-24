#!/usr/bin/env bash
# Instala o actualiza las skills de drawl99 en OpenCode.
#
# OpenCode no instala skills desde un marketplace: las descubre en
# ~/.config/opencode/skills/<nombre>/SKILL.md. Este script clona el repo (o lo
# actualiza) y enlaza cada skill y cada comando con un symlink, así un
# `git pull` posterior las deja al día.
#
# Uso:   scripts/install-opencode.sh            instala o actualiza
#        scripts/install-opencode.sh --uninstall quita los symlinks
set -euo pipefail

REPO="drawl99/claude-plugins"
CHECKOUT="${DRAWL99_SKILLS_DIR:-$HOME/.local/share/drawl99/claude-plugins}"
OC="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

link() { # link <origen> <destino>
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    echo "⚠️  $dst ya existe y no es un symlink de este repo: lo dejo como está." >&2
    return 0
  else
    ln -s "$src" "$dst"
  fi
  echo "✔ $dst"
}

unlink_if_ours() {
  local dst="$1"
  if [ -L "$dst" ] && [[ "$(readlink "$dst")" == "$CHECKOUT"* ]]; then
    rm "$dst" && echo "✔ quitado $dst"
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  for d in "$CHECKOUT"/plugins/*/skills/*/; do unlink_if_ours "$OC/skills/$(basename "$d")"; done
  for f in "$CHECKOUT"/opencode/commands/*.md; do unlink_if_ours "$OC/commands/$(basename "$f")"; done
  exit 0
fi

# git usa a gh como credencial (respeta GH_TOKEN): con varias cuentas de GitHub,
# la credencial por defecto de git puede no ver el repo si es privado.
git_auth() {
  if command -v gh >/dev/null 2>&1; then
    git -c credential.helper= -c "credential.helper=!gh auth git-credential" "$@"
  else
    git "$@"
  fi
}

if [ -d "$CHECKOUT/.git" ]; then
  git_auth -C "$CHECKOUT" pull --ff-only --quiet
else
  mkdir -p "$(dirname "$CHECKOUT")"
  if command -v gh >/dev/null 2>&1; then
    gh repo clone "$REPO" "$CHECKOUT" -- --quiet
  else
    git clone --quiet "https://github.com/$REPO.git" "$CHECKOUT"
  fi
fi

mkdir -p "$OC/skills" "$OC/commands"
for d in "$CHECKOUT"/plugins/*/skills/*/; do link "${d%/}" "$OC/skills/$(basename "$d")"; done
for f in "$CHECKOUT"/opencode/commands/*.md; do link "$f" "$OC/commands/$(basename "$f")"; done

echo "Listo. Reinicia OpenCode. Comandos: /github-goal y /workflow-decision."
