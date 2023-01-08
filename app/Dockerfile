# ARG PYTHON_VERSION=3.7

# # Use the python image as the base image
# FROM python:${PYTHON_VERSION}

# # upgrade pip 
# RUN pip install --upgrade pip

# # set CUSTOMER_NAME as environment variables
# ENV CUSTOMER_NAME=${CUSTOMER_NAME:-A}

# # Set the working directory 
# WORKDIR /app

# # Create a non-root user and add the permissions
# RUN useradd -u 1001 "${USERNAME:-jananath}" \
#     && chown "${USERNAME:-jananath}" /app

# # set the username - HERE WE ARE USING A DEFAULT VALUE FOR THE USERNAME, WHICH IS "jananath"
# USER "${USERNAME:-jananath}"

# # copy the requirements file and install the dependencies
# COPY --chown="${USERNAME:-jananath}":"${USERNAME:-jananath}" requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir --upgrade --user -r /app/requirements.txt

# ENV PATH="/home/${USERNAME:-jananath}/.local/bin:${PATH}"

# # copy the app code
# COPY --chown="${USERNAME:-jananath}":"${USERNAME:-jananath}" . /app

# # expose the default Flask port
# EXPOSE 80 

# # set the entrypoint to run the app
# CMD ["uvicorn", "main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "80"]



ARG PYTHON_VERSION=3.7

# Use the python image as the base image
FROM python:${PYTHON_VERSION}

RUN pip install --upgrade pip

RUN adduser -D myuser
USER myuser
WORKDIR /home/myuser

COPY --chown=myuser:myuser requirements.txt requirements.txt
RUN pip install --user -r requirements.txt

ENV PATH="/home/myuser/.local/bin:${PATH}"

COPY --chown=myuser:myuser . .

CMD ["uvicorn", "main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "80"]