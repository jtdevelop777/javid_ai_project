FROM python:3.10-slim
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*
RUN pip install chromadb
EXPOSE 8000
CMD ["chroma", "run", "--host", "0.0.0.0", "--port", "8000", "--path", "/data"]
