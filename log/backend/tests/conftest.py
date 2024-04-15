from dataclasses import dataclass

import pytest


@pytest.fixture
def lambda_context():  # test
    @dataclass
    class LambdaContext:
        def __init__(self):
            self.function_name = "test"
            self.memory_limit_in_mb = 128
            self.aws_request_id = "test"
            self.invoked_function_arn = "test"

    yield LambdaContext()
