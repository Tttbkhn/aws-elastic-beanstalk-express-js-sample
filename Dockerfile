# Dockerfile
FROM node:16-alpine

# Create app directory
WORKDIR /app

# Install deps first (better layer cache)
COPY package*.json ./

# not to install devDependencies when building the runtime image
RUN npm install --omit=dev

# Copy source
COPY . .

# App listens on 8080
EXPOSE 8080

# Start the app
CMD ["node", "app.js"]
