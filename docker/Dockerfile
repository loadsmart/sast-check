FROM python:3.8-alpine

RUN pip install bandit datadog
ADD sast-check.py /bin/sast-check.py
RUN chmod +x /bin/sast-check.py

ENTRYPOINT [ "/bin/sast-check.py" ]
