#!/usr/bin/env bash
set -uo pipefail

locker="${LOCK_PIXEL_LOCKER:-/usr/bin/i3lock}"
tmpbg=""
locker_pid=""
prep_pid=""
sleep_lock_fd=""

close_parent_sleep_fd() {
  if [[ -n "$sleep_lock_fd" ]]; then
    eval "exec ${sleep_lock_fd}>&-"
    sleep_lock_fd=""
  fi
}

cleanup() {
  # A signal during preparation leaves the inhibitor in this wrapper. Close it
  # before launching rm so no cleanup helper can inherit the descriptor.
  close_parent_sleep_fd
  if [[ -n "$tmpbg" ]]; then
    rm -f -- "$tmpbg"
  fi
}

forward_signal() {
  local signal="$1"
  local status="$2"

  trap - TERM INT
  if [[ -n "$prep_pid" ]] && kill -0 "$prep_pid" 2>/dev/null; then
    kill -s "$signal" "$prep_pid" 2>/dev/null || true
    wait "$prep_pid" 2>/dev/null || true
  fi
  if [[ -n "$locker_pid" ]] && kill -0 "$locker_pid" 2>/dev/null; then
    kill -s "$signal" "$locker_pid" 2>/dev/null || true
    wait "$locker_pid" 2>/dev/null || true
  fi
  exit "$status"
}

trap cleanup EXIT
trap 'forward_signal TERM 143' TERM
trap 'forward_signal INT 130' INT

# xss-lock passes an open inhibitor descriptor to the lock command. Only accept
# a non-standard descriptor that is actually open; a stale or malformed value
# must never prevent manual locking.
case "${XSS_SLEEP_LOCK_FD:-}" in
  ''|*[!0-9]*)
    unset XSS_SLEEP_LOCK_FD
    ;;
  *)
    if [[ ${#XSS_SLEEP_LOCK_FD} -le 9 && "$XSS_SLEEP_LOCK_FD" != 0* ]] \
      && (( 10#$XSS_SLEEP_LOCK_FD >= 3 )) \
      && [[ -e "/proc/$$/fd/$XSS_SLEEP_LOCK_FD" ]]; then
      sleep_lock_fd="$XSS_SLEEP_LOCK_FD"
    else
      unset XSS_SLEEP_LOCK_FD
    fi
    ;;
esac

uptime_ms() {
  local uptime seconds fraction
  read -r uptime _ < /proc/uptime || return 1
  seconds=${uptime%%.*}
  fraction=${uptime#*.}000
  now_ms=$((10#$seconds * 1000 + 10#${fraction:0:3}))
}

remaining_suspend_time() {
  uptime_ms || return 1
  local remaining_ms=$((suspend_deadline_ms - now_ms))
  (( remaining_ms > 0 )) || return 1
  printf -v remaining '%d.%03d' "$((remaining_ms / 1000))" "$((remaining_ms % 1000))"
}

run_locker() {
  "$locker" "$@" &
  locker_pid=$!

  # The child inherited the descriptor. Drop the wrapper's copy immediately;
  # the locker closes its copy when the display is secured, releasing suspend.
  close_parent_sleep_fd

  local status=0
  wait "$locker_pid" || status=$?
  locker_pid=""
  return "$status"
}

lock_solid() {
  # A failed image path must still make a real locking attempt.
  # Keep an unconsumed inhibitor for preparation failures. After an image
  # locker was spawned, its inherited copy has already represented readiness.
  if [[ -z "$sleep_lock_fd" ]]; then
    unset XSS_SLEEP_LOCK_FD
  fi
  run_locker -n -c 000000
}

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}"
umask 077

if [[ -n "$sleep_lock_fd" ]]; then
  # Keep one total preparation budget below logind's usual five-second limit.
  # Only the wrapper holds the inhibitor during preparation. A subshell closes
  # its copy before starting each helper (including timeout itself).
  if ! uptime_ms; then
    lock_solid
    exit $?
  fi
  suspend_deadline_ms=$((now_ms + 2000))
  if ! remaining_suspend_time; then
    lock_solid
    exit $?
  fi
  if ! tmpbg="$(close_parent_sleep_fd; timeout -k 0.2s "$remaining" mktemp --tmpdir="$runtime_dir" lock-pixel.XXXXXX.png)"; then
    lock_solid
    exit $?
  fi
else
  if ! tmpbg="$(mktemp --tmpdir="$runtime_dir" lock-pixel.XXXXXX.png)"; then
    lock_solid
    exit $?
  fi
fi

down=40
up=$((10000 / down))
if [[ -n "$sleep_lock_fd" ]]; then
  if ! remaining_suspend_time; then
    lock_solid
    exit $?
  fi
  (
    close_parent_sleep_fd
    # Parameters expand in the nested bash.
    # shellcheck disable=SC2016
    exec timeout -k 0.2s "$remaining" bash -o pipefail -c \
      'maim -u | magick - -sample "$1%" -sample "$2%" "PNG24:$3"' \
      _ "$down" "$up" "$tmpbg"
  ) &
  prep_pid=$!
  prep_status=0
  wait "$prep_pid" || prep_status=$?
  prep_pid=""
  if (( prep_status != 0 )); then
    lock_solid
    exit $?
  fi
else
  if ! maim -u | magick - -sample "$down%" -sample "$up%" "PNG24:$tmpbg"; then
    lock_solid
    exit $?
  fi
fi

if [[ ! -s "$tmpbg" ]]; then
  lock_solid
  exit $?
fi

if run_locker -n -i "$tmpbg"; then
  exit 0
fi

# This also covers an executable that passes preflight but cannot be started.
# If the graphical locker itself reports failure, retry with a plain surface.
lock_solid
