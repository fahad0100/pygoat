# -------- runtime stage --------
FROM python:3.11-slim-bookworm

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        libpq5 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* \
    && rm -rf /wheels

COPY . /app/

EXPOSE 8000

# HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
#      CMD curl -f http://localhost:8000/healthz || exit 1

# تعديل أمر التشغيل لتقسيم الأوامر وتنفيذ migrate أولاً
CMD ["sh", "-c", "python manage.py migrate && gunicorn --bind 0.0.0.0:8000 --workers 4 --worker-class gthread --threads 4 --timeout 600 pygoat.wsgi"]
