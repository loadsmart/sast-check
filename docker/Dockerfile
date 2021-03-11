FROM python:3.8-alpine

#RUN apk add jq curl
RUN pip install bandit datadog

#ADD sast-check.sh /bin/sast-check
ADD sast-check.py /bin/sast-check.py
RUN chmod +x /bin/sast-check.py
#ADD test.json /tmp/test.json

ENTRYPOINT [ "/bin/sast-check.py" ]
