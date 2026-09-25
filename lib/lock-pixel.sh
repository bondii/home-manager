#!/usr/bin/env bash
set -uo pipefail

locker="${LOCK_PIXEL_LOCKER:-/usr/bin/i3lock}"
tmpbg=""
locker_pid=""
sleep_lock_fd=""

cleanup() {
  if [[ -n "$tmpbg" ]]; then
    rm -f -- "$tmpbg"
  fi
}

forward_signal() {
  local signal="$1"
  local status="$2"

  trap - TERM INT
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

close_parent_sleep_fd() {
  if [[ -n "$sleep_lock_fd" ]]; then
    eval "exec ${sleep_lock_fd}>&-"
    sleep_lock_fd=""
  fi
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

if ! tmpbg="$(mktemp --tmpdir="$runtime_dir" lock-pixel.XXXXXX.png)"; then
  lock_solid
  exit $?
fi

down=40
up=$((10000 / down))
if ! maim -u | magick - -sample "$down%" -sample "$up%" "PNG24:$tmpbg"; then
  lock_solid
  exit $?
fi

if run_locker -n -i "$tmpbg"; then
  exit 0
fi

# This also covers an executable that passes preflight but cannot be started.
# If the graphical locker itself reports failure, retry with a plain surface.
lock_solid
