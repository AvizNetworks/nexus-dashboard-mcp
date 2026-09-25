# Multi-stage build for Nexus Dashboard MCP Server
#
# Shared hardened NCP base (see deploy-ones/dockerfiles/ncp-python-base-312-alpine).
# Every dependency ships a musllinux wheel (psycopg2-binary and asyncpg vendor their
# own libpq), so neither gcc/libpq-dev in the builder nor libpq5 at runtime is needed.
ARG PYTHON_BASE=avizdock/ncp-python-base-312-alpine:latest
# Runtime stage: plain upstream python:3.12-alpine -- the same Alpine release and
# CPython the shared base is built FROM, but without its build toolchain, so the
# image does not carry ~450 MB of gcc/binutils/git layers underneath. Override
# with a lean shared runtime base once deploy-ones provides one.
ARG PYTHON_RUNTIME_BASE=python:3.12-alpine

# Stage 1: Builder
FROM ${PYTHON_BASE} AS builder

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install Python dependencies into a self-contained venv
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt \
    && /opt/venv/bin/pip uninstall -y pip setuptools wheel

# Stage 2: Runtime
FROM ${PYTHON_RUNTIME_BASE}

# Build toolchain, packaging tools: if PYTHON_RUNTIME_BASE is the shared alpine base it
# carries build-base/git/curl/*-dev, and every base carries pip/setuptools/wheel
# for building; none are needed at runtime, and they are the bulk of the image's
# HIGH findings (binutils, pip's vendored msgpack/setuptools).
RUN pkgs="$(apk info -e build-base libffi-dev openssl-dev git curl || true)" \
    && if [ -n "$pkgs" ]; then apk del --no-cache $pkgs; fi \
    && apk upgrade --no-cache \
    && (python -m pip uninstall -y setuptools wheel pip || true)

WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY src/ ./src/
COPY openapi_specs/ ./openapi_specs/
COPY scripts/ ./scripts/
COPY docs/ ./docs/

# Make sure scripts in the venv are usable
ENV PATH=/opt/venv/bin:$PATH

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Runs as root, unchanged from the previous image.
USER root

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

# Default command (can be overridden in docker-compose)
CMD ["python", "src/main.py"]
