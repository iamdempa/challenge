ARG PYTHON_VERSION=3.7

# Use the python image as the base image
FROM python:${PYTHON_VERSION}

ARG CUSTOMER_NAME

# set CUSTOMER_NAME as environment variables
ENV CUSTOMER_NAME={CUSTOMER_NAME}

# Set the working directory 
WORKDIR /app

# copy the requirements file and install the dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# Create a non-root user and add the permissions
RUN useradd -u 1001 "${USERNAME:-jananath}" \
    && chown "${USERNAME:-jananath}" /app

# set the username - HERE WE ARE USING A DEFAULT VALUE FOR THE USERNAME, WHICH IS "jananath"
USER "${USERNAME:-jananath}"

# copy the app code
COPY main.py /app

# expose the default Flask port
EXPOSE 80 

# set the entrypoint to run the app
CMD ["uvicorn", "main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "80"]

