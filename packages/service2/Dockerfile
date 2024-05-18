# Use the official Node.js LTS image from the Docker Hub
FROM node:lts-alpine

# Create and change to the app directory
WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package.json ./

# Install the dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE 3001

# Run the application
CMD ["node", "index.js"]
