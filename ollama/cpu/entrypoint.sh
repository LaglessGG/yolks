#!/bin/bash
# Ollama (CPU-only) entrypoint.
#
# Unlike the java image, this doesn't eval the egg's STARTUP field — starting Ollama needs
# multiple steps (bind on the server's actual allocated port, wait for the API, pull the
# configured model if it isn't already cached) that don't fit in a single command line, so
# that orchestration lives here instead. MODEL, OLLAMA_CONTEXT_LENGTH, OLLAMA_MAX_LOADED_MODELS
# and OLLAMA_NUM_THREADS all arrive as real environment variables from the egg's variables.

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

LOG_PREFIX="\033[1m\033[33mcontainer@pterodactyl~\033[0m"

cd /home/container || exit 1
mkdir -p "$OLLAMA_MODELS"

printf "${LOG_PREFIX} Starting Ollama on 0.0.0.0:${SERVER_PORT} (threads=${OLLAMA_NUM_THREADS}, ctx=${OLLAMA_CONTEXT_LENGTH}, max_loaded=${OLLAMA_MAX_LOADED_MODELS})\n"
OLLAMA_HOST="0.0.0.0:${SERVER_PORT}" ollama serve &
SERVE_PID=$!

# Forward the stop signal to the actual ollama process — without this, `wait` below would
# just return on SIGTERM/SIGINT and the container would exit without ollama ever seeing it,
# leaving it to be hard-killed instead of shutting down cleanly.
trap 'printf "${LOG_PREFIX} Stopping Ollama...\n"; kill -TERM "$SERVE_PID" 2>/dev/null; wait "$SERVE_PID" 2>/dev/null; exit 0' TERM INT

printf "${LOG_PREFIX} Waiting for the API to come online...\n"
until curl -sf "http://127.0.0.1:${SERVER_PORT}/api/version" >/dev/null 2>&1; do
	sleep 1
done
printf "${LOG_PREFIX} API is up.\n"

printf "${LOG_PREFIX} Checking model '${MODEL}'...\n"
if OLLAMA_HOST="127.0.0.1:${SERVER_PORT}" ollama list 2>/dev/null | awk '{print $1}' | grep -qx "${MODEL}"; then
	printf "${LOG_PREFIX} Model '${MODEL}' already present, skipping pull.\n"
else
	printf "${LOG_PREFIX} Pulling model '${MODEL}' — first run can take a while for large models, this is not a hang.\n"
	if OLLAMA_HOST="127.0.0.1:${SERVER_PORT}" ollama pull "${MODEL}"; then
		printf "${LOG_PREFIX} Model '${MODEL}' ready.\n"
	else
		printf "${LOG_PREFIX} WARNING: failed to pull '${MODEL}'. The API is up but this model will 404 until a pull succeeds — check the model name and try again.\n"
	fi
fi

printf "${LOG_PREFIX} Ollama is serving on 0.0.0.0:${SERVER_PORT} — OpenAI-compatible endpoint at /v1/chat/completions\n"
wait "$SERVE_PID"
