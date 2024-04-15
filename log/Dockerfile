FROM public.ecr.aws/lambda/python:3.11 as builder

COPY pyproject.toml poetry.lock ./
RUN pip install --upgrade pip \
    && pip install poetry \
    && poetry config virtualenvs.create false \
    && poetry install
COPY src/handler.py src/handler.py
COPY tests/ tests/

FROM public.ecr.aws/lambda/python:3.11 as runner
COPY --from=builder /var/lang/bin /var/lang/bin
COPY --from=builder /var/lang/lib/python3.11/site-packages /var/lang/lib/python3.11/site-packages
COPY --from=builder /var/task /var/task
ENV PYTHONPATH="$PYTHONPATH:/var/task/src"
