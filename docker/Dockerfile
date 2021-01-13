FROM python:3.8-alpine

RUN apk add jq
RUN pip install bandit

ADD sast-check.sh /bin/sast-check
RUN chmod +x /bin/sast-check

ENTRYPOINT [ "/bin/sast-check" ]
