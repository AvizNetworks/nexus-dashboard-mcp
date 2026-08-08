"""Minimal FastAPI app for NCP LocalMCP mode.

Serves only the MCP HTTP/SSE transport. Unlike the full web_api product app,
this entrypoint does not require Postgres, web UI, or cluster management APIs.
Credentials come from environment variables injected by NCP.
"""

import logging

from fastapi import FastAPI

from src.api.mcp_transport import router as mcp_router

logger = logging.getLogger(__name__)

app = FastAPI(
    title="Nexus Dashboard LocalMCP",
    description="Slim MCP SSE transport for NCP-managed LocalMCP connectors",
    version="1.0.0",
)

app.include_router(mcp_router)


@app.get("/health")
async def health():
    """Simple liveness endpoint for LocalMCP containers."""
    return {"status": "ok", "mode": "localmcp"}


@app.on_event("startup")
async def on_startup():
    logger.info("Nexus Dashboard LocalMCP SSE app starting (no Postgres required)")
