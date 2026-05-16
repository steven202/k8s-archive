# tmux OSC 52 Clipboard Setup

## Problem

- Headless Linux server, no X server, xclip hangs tmux
- `set-clipboard on` freezes tmux; `set-clipboard off` disables all clipboard
- Need copy-paste to work across different terminal emulators via SSH

## Key Insight

Writing directly to `#{pane_tty}` bypasses tmux, so the `\033Ptmux;...\033\\` DCS wrapper must NOT be used. Use raw OSC 52 sequences instead.

## Supported Terminals

| Terminal | OSC 52 Support |
|----------|---------------|
| iTerm2 (macOS) | Yes (needs setting enabled) |
| macOS Terminal.app | No |
| VS Code terminal | No |

## iTerm2 Setup

Preferences → General → Selection → check "Applications in terminal may access clipboard"

## Configuration

### ~/.tmux.conf

```
set -g mouse on
set-window-option -g mode-keys vi
set -s set-clipboard off

# Keyboard copy (y in copy mode)
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel '/home/cwang33/.tmux/scripts/osc52.sh'

# Mouse drag auto-copy
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel '/home/cwang33/.tmux/scripts/osc52.sh'

# Save pane log (prefix + s)
bind s run-shell 'dir="#{pane_current_path}/.tmux_logs"; mkdir -p "$dir"; tmux capture-pane -p -S - -E - > "$dir/log_W#I_P#P_$(TZ=America/New_York date +%Y%m%d_%H%M%S).txt"' \; display-message "Log saved!"
```

### ~/.tmux/scripts/osc52.sh

```bash
#!/usr/bin/env bash
set -e
input=$(cat)
text=$(printf '%s' "$input" | base64 -w0)
tty=$(tmux display -p '#{pane_tty}')
printf '\033]52;c;%s\033\\' "$text" > "$tty"
```

## Debugging

1. **Test terminal OSC 52 locally** (no SSH, no tmux):
   ```bash
   printf '\033]52;c;%s\033\\' "$(echo -n 'hello' | base64)"
   ```
   If `hello` appears in clipboard, terminal supports OSC 52.

2. **Test DCS-wrapped in tmux**:
   ```bash
   printf '\033Ptmux;\033\033]52;c;%s\033\033\\\033\\' "$(echo -n 'hello' | base64)"
   ```
   This tests tmux passthrough. Works = DCS wrapping is correct.

3. **If step 1 works but copy in tmux doesn't**: the script is writing to `pane_tty` with wrong format. When writing to tty directly, use raw OSC 52 (no DCS wrapper).
