# -------- build stage --------
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        dnsutils \
        libpq-dev \
        gcc \
        python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt requirements.txt

RUN pip wheel --no-cache-dir --no-deps -w /wheels -r requirements.txt

# -------- runtime stage --------
FROM python:3.11-slim-bookworm

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

# أمر التشغيل: تنفيذ الـ migrate أولاً لإنشاء قاعدة البيانات وجداولها تلقائياً ثم بدء السيرفر
CMD ["sh", "-c", "python manage.py migrate && python manage.py loaddata initial_data || true && gunicorn --bind 0.0.0.0:8000 --workers 4 --worker-class gthread --threads 4 --timeout 600 pygoat.wsgi"]
