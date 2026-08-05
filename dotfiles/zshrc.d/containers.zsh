container_run_or_exec() {
  local run_args=()
  local container_name=""
  local image_name=""

  # 1. Parse optional flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-args)
        if [[ -n "$2" ]]; then
          # Safely split string into an array (handles quotes/spaces via eval)
          eval "run_args=($2)"
          shift 2
        else
          echo "Error: --run-args requires a quoted string argument." >&2
          return 1
        fi
        ;;
      *)
        if [[ -z "$container_name" ]]; then
          container_name="$1"
        elif [[ -z "$image_name" ]]; then
          image_name="$1"
        else
          break # Remaining parameters are commands to execute inside container
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$container_name" || -z "$image_name" ]]; then
    echo "Usage: run_or_exec [--run-args \"...\"] <container_name> <image_name> [command...]" >&2
    return 1
  fi

  # Detect container engine (Prefer podman over docker)
  local engine
  if command -v podman >/dev/null 2>&1; then
    engine="podman"
  elif command -v docker >/dev/null 2>&1; then
    engine="docker"
  else
    echo "Error: Neither podman nor docker was found in PATH." >&2
    return 1
  fi

  # Check container status using the selected engine
  local running
  running="$("$engine" inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)"

  # 1. Container is running -> exec into it
  if [ "$running" = "true" ]; then
    echo "[$engine] Container '$container_name' is running. Connecting..."
    "$engine" exec -it "$container_name" "${@:-sh}"

  # 2. Container exists but is stopped -> start & attach
  elif "$engine" inspect "$container_name" >/dev/null 2>&1; then
    echo "[$engine] Container '$container_name' exists but is stopped. Starting..."
    "$engine" start -ai "$container_name"

  # 3. Container doesn't exist -> run new container
  else
    echo "[$engine] Container '$container_name' does not exist. Spawning new container..."
    "$engine" run -it "${run_args[@]}" --name "$container_name" "$image_name" "${@:-sh}"
  fi
}

kalirun() {
  container_run_or_exec --run-args "--net host -v matir_kali:/home/matir" matir_kali ghcr.io/matir/containers/kali:latest "$@"
}
