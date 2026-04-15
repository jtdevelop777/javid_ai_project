docker run -d \
  --name javid-flow-manager \
  --restart always \
  -p 18880:3000 \
  -v flowise_data:/root/.flowise \
  flowiseai/flowise:latest
