FROM python:3.11-slim

# Install system dependencies including ffmpeg for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a non-root user for Hugging Face Spaces (user ID 1000)
RUN useradd -m -u 1000 user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application
COPY --chown=user:user . /app

# Ensure downloads directory is writable
RUN mkdir -p /app/downloads && chown -R user:user /app

USER user

EXPOSE 7860

# Hugging Face Spaces expects traffic on port 7860
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:7860", "--workers", "2", "--timeout", "120"]
