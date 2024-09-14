FROM elixir:${ELIXIR_VERSION}-alpine

ARG PLEROMA_VERSION=develop
ARG UID=911
ARG GID=911
ENV MIX_ENV=prod

RUN echo "http://nl.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && apk update \
    && apk upgrade --no-cache libssl3 libcrypto3 \
    && apk add git gcc g++ musl-dev make cmake file-dev \
    exiftool imagemagick libmagic ncurses postgresql-client ffmpeg

RUN addgroup -g ${GID} pleroma \
    && adduser -h /pleroma -s /bin/false -D -G pleroma -u ${UID} pleroma

ARG DATA=/var/lib/pleroma
RUN mkdir -p /etc/pleroma \
    && chown -R pleroma /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R pleroma ${DATA}

USER pleroma
WORKDIR /pleroma

RUN git clone -b develop https://git.pleroma.social/pleroma/pleroma.git /pleroma \
    && git checkout ${PLEROMA_VERSION}

RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /pleroma

COPY --chown=pleroma --chmod=640 ./config.exs /etc/pleroma/config.exs
RUN chmod o= /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
