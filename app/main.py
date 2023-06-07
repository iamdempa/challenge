from fastapi import FastAPI, HTTPException
import os

app = FastAPI(title="Hello-World Greetings Service", description="A simple service that returns different salutations for customers")

@app.get("/")
def hello():

    # set the string that needs to match 
    CUSTOMER_NAME = ''

    # Check if the environment variable is set
    if "CUSTOMER_NAME" in os.environ:
        name = os.getenv("CUSTOMER_NAME")
        if name:
            CUSTOMER_NAME = name             

    # use a hash table to store the greeting messages
    greeting_messages = {
        'A': 'Hi!',
        'B': 'Dear Sir or Madam!',
        'C': 'Moin!'
    }

    # retrieve the appropriate greeting message from the hash table
    greeting = ''
    greeting = greeting_messages.get(CUSTOMER_NAME)

    if greeting:    
        return {'response' : greeting}
    else:
        raise HTTPException(status_code=404, detail="Oh Human! It is not a good day for us... We couldn't find your Customer :(")

# Define the health API endpoint to be used by the kubernetes
@app.get('/health')
def health():
    return {'status' : "Hurray! We are online now..."}
