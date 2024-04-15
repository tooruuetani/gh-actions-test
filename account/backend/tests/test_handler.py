from handler import lambda_handler


def test_lambda_handler(lambda_context: dict):
    event = {
        "resource": "/services",
        "path": "/services",
        "httpMethod": "GET",
        "requestContext": {"authorizer": {"claims": {"email": "登録済メールアドレス"}}},
        "queryStringParameters": {"spaceId": ""},
    }
    lambda_handler(event, lambda_context)
