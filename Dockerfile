#builder
FROM python:3.12-alpine AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    --prefix=/install \
    -r requirements.txt

#runtime
FROM python:3.12-alpine

WORKDIR /app

RUN adduser -D -u 10001 appuser

COPY --from=builder /install /usr/local
COPY --chown=appuser:appuser app/ ./app/
COPY --chown=appuser:appuser static/ ./static

RUN chown appuser:appuser /app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"]

CMD ["uvicorn", "app:api", "--host", "0.0.0.0", "--port", "8000"]
