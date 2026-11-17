# Shared environment for Bash and Zsh. Keep this file POSIX-compatible.
export BOOTSTRAP_DIRECTORY="$HOME/linux-bootstrap"
export SDKMAN_DIR="$HOME/.sdkman"
export NODE_OPTIONS="--use-env-proxy --use-system-ca"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$PATH:$HOME/.local/bin" ;;
esac
case ":$PATH:" in
    *":$HOME/.local/share/fnm:"*) ;;
    *) PATH="$HOME/.local/share/fnm:$PATH" ;;
esac
export PATH

if [ -r "$BOOTSTRAP_DIRECTORY/proxy.env" ]; then
    . "$BOOTSTRAP_DIRECTORY/proxy.env"
fi
