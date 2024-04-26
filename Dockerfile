# Use an official Node.js runtime as a parent image
FROM node:16-alpine

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./
COPY tsconfig.json ./
COPY src ./src

ENV PORT=8080

# Install dependencies
RUN npm ci

# Build TypeScript files
RUN npm run build

# Expose the port the app runs on
EXPOSE ${PORT}

# Command to run the application
CMD ["npm", "start"]
