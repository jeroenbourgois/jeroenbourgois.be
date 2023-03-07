FROM --platform=$BUILDPLATFORM alpine:3.13 as build
RUN apk add --no-cache hugo
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/tmp/hugo_cache hugo

FROM nginx
COPY --from=build /src/public /usr/share/nginx/html
