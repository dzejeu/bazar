FROM elixir:1.15.7

WORKDIR /usr/src/app

COPY . .

RUN mix deps.get
RUN mix compile