from fastapi.testclient import TestClient
from .main import app
import os 

client = TestClient(app)

# test the greetings endpoint 
def test_hello():

    CUSTOMER_NAME = ''

    # Check if the environment variable is set
    if "CUSTOMER_NAME" in os.environ:
        name = os.getenv("CUSTOMER_NAME")
        if name:
            CUSTOMER_NAME = name 
             
    # get the client 
    response = client.get("/")

    # check if the status code is 200 for a successful attempt
    assert response.status_code == 200

    # IN THIS SOLUTION, SINCE WE ARE NOT USING ANY QUERY PARAMETERS, 
    # WE HAVE TO STILL CHECK THE "CUSTOMER_NAME" VALUE TO DETERMINE THE RESPONSE MESSAGE 
    # if customer is A 
    if CUSTOMER_NAME == "A":
        assert response.json() == {'response' : 'Hi!'}
    # if customer is B
    elif CUSTOMER_NAME == "B":
        assert response.json() == {'response' : 'Dear Sir or Madam!'}  
    # if customer is C  
    elif CUSTOMER_NAME == "B":
        assert response.json() == {'response' : 'Moin!'}  
    # otherwise
    else:
        assert response.json() == {'detail' : 'Oh Human! It is not a good day for us... We couldn\'t find your Customer :('}

# test the health endpoint 
def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {'status' : 'Hurray! We are online...'}