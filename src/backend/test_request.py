import requests

def test_request(ip='34.238.155.46', port='8000', endpoint='test', method='GET'):
    url = f'http://{ip}:{port}/{endpoint}'
    if method == 'GET':
        response = requests.get(url)
    elif method == 'POST':
        response = requests.post(url)
    else:
        raise ValueError('Method not supported')
    assert response.status_code == 200
    print(response.text)

test_request()



