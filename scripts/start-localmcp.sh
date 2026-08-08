#!/bin/bash
# Slim LocalMCP entrypoint for NCP-managed containers.
# Starts HTTP SSE transport on WEB_API_PORT (default 8001) without Postgres/UI.
set -euo pipefail

WEB_API_PORT="${WEB_API_PORT:-8001}"
export LOCAL_MCP_MODE="${LOCAL_MCP_MODE:-true}"
export SSL_ENABLED="${SSL_ENABLED:-false}"

echo "LocalMCP: starting slim SSE transport on 0.0.0.0:${WEB_API_PORT}"
echo "LocalMCP: LOCAL_MCP_MODE=${LOCAL_MCP_MODE} SSL_ENABLED=${SSL_ENABLED}"

exec python -m uvicorn src.api.localmcp_app:app --host 0.0.0.0 --port "${WEB_API_PORT}"
