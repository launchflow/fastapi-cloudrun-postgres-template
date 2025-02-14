
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for psycopg2
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY main.py main.py

# Set default port (will be overridden by environment variable if provided)
ENV PORT=8080

# Run the application with the PORT environment variable
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
