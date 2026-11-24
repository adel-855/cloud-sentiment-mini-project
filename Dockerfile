# Stage 1: Build and install Python dependencies
FROM python:3.12 AS build

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --no-compile --prefix=/install -r requirements.txt


# Stage 2: Run the application using a lightweight image
FROM python:3.12-slim

WORKDIR /app

# Copy the installed dependencies from the build stage
COPY --from=build /install /usr/local

# Copy the application and machine-learning models
COPY app/ ./app/
COPY models/ ./models/

# Application configuration
ENV MODELS_DIR=/app/models \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create a non-root user
RUN useradd --uid 10001 --no-create-home app

# Run as the non-root user
USER 10001

# Document the application port
EXPOSE 8000

# Santé du conteneur : application seule (la base est vérifiée par /health et par compose).
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import sys,urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=3).status == 200 else 1)"

# Start the FastAPI application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
