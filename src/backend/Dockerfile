FROM python:3.10-slim

# Set a reliable temporary directory
ENV TMPDIR=/tmp

# Set working directory
WORKDIR /app

# Copy only requirements first to leverage Docker caching
COPY requirements.txt .

# Update apt and install system dependencies (including python3-distutils)
RUN apt-get update && apt-get install -y \
    gcc \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-distutils && \
    pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir --no-build-isolation -r requirements.txt

# Copy the rest of the backend source code
COPY . .

# Expose FastAPI port
EXPOSE 8080

# Run the FastAPI application using Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

