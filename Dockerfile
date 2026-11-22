
# Stage 1: Build and install Python dependencies
FROM python:3.12 AS build

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Run the application using a lightweight image
FROM python:3.12-slim

WORKDIR /app

# Copy the installed dependencies from the build stage
COPY --from=build /install /usr/local

# Copy the application and machine-learning models
COPY app/ ./app/
COPY models/ ./models/

# Application configuration
ENV MODELS_DIR=/app/models
ENV PYTHONUNBUFFERED=1

# Create a non-root user
RUN useradd --uid 10001 --no-create-home app

# Run as the non-root user
USER 10001

# Document the application port
EXPOSE 8000

# Start the FastAPI application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]