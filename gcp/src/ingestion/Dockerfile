
# Base image
FROM us-central1-docker.pkg.dev/serverless-runtimes/google-22/runtimes/python312

# Set the working directory inside the container
WORKDIR /app

# Copy requirements.txt
COPY requirements.txt /app/requirements.txt

# Install the specified packages
RUN pip install -r requirements.txt

# Copy the script into the container
COPY main.py /app/main.py

# Expose port
EXPOSE 9000

# Set the default command to run the main script
CMD ["python", "-u", "main.py"]
