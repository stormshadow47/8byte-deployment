# Stage 1
FROM python:3.13-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency definition
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt


# Stage 2
FROM python:3.13-slim AS runner

WORKDIR /app

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser appuser

COPY --from=builder /usr/local/lib/python3.13/site-packages \
    /usr/local/lib/python3.13/site-packages

COPY --from=builder /usr/local/bin /usr/local/bin

COPY --chown=appuser:appuser . .

# Run as non-root
USER appuser

EXPOSE 8000


CMD ["uvicorn", "index:app", "--host", "0.0.0.0", "--port", "8000"]