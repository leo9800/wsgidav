# Dockerfile for https://github.com/mar10/wsgidav/
# Build:
#   docker build --rm -f Dockerfile -t mar10/wsgidav .
# Run:
#   docker run --rm -it -p <PORT>:8080 -v <ROOT_FOLDER>:/var/wsgidav-root mar10/wsgidav
# for example
#   docker run --rm -it -p 8080:8080 -v c:/temp:/var/wsgidav-root mar10/wsgidav
# Then open (or enter this URL in Windows File Explorer or any other WebDAV client)
#   http://localhost:8080/

# NOTE 2018-07-28: alpine does not compile lxml
# NOTE 2019-11-27: smallest image generated at the end
# NOTE 2025-12-10: add capability wrapper for impersonating in containers
# NOTE 2025-12-10: build against local root, not PyPI
# NOTE 2025-12-10: reduce image size with multi-stage building
FROM alpine AS wrapper-builder
WORKDIR /root
ADD suid-wrapper.c /root
RUN apk update && \
    apk upgrade && \
    apk add --no-cache build-base libcap-ng-dev libcap-ng-static
RUN gcc suid-wrapper.c -static -s -o suid-wrapper \
    $(pkg-config --cflags --libs --static libcap-ng)

# https://testdriven.io/blog/docker-best-practices/#use-multi-stage-builds
FROM python:3-alpine AS app-builder
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ADD . /wsgidav
RUN mkdir /wheels
RUN pip wheel \
    --no-cache-dir \
    --no-deps \
    --wheel-dir /wheels \
    --prefer-binary \
    /wsgidav gunicorn lxml

FROM python:3-alpine
COPY --from=wrapper-builder /root/suid-wrapper /usr/local/bin/
RUN --mount=type=bind,source=/wheels,target=/wheels,from=app-builder \
    pip install --no-cache --prefer-binary /wheels/*
CMD ["wsgidav"]
