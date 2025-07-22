# ─────────────────────────────────────────────────────────────
# Base image
FROM python:3.12-slim

RUN pip install --no-cache-dir uv

WORKDIR /app

# libs instalation via uv
ENV UV_PROJECT_ENVIRONMENT="/usr/local/"
RUN uv sync --locked --no-dev

COPY server.py .

EXPOSE 8000

# uvicorn used for code-change triggered reload
CMD ["uvicorn", "server:mcp.http_app","--host", "0.0.0.0", "--port", "8000","--reload"]
