FROM python:3.8-alpine

RUN apk add jq
RUN pip install bandit

ADD docker/sast-check.sh /bin/sast-check
RUN chmod +x /bin/sast-check
ADD libptlpricing /tmp/libptlpricing

ENTRYPOINT [ "/bin/sast-check" ]
