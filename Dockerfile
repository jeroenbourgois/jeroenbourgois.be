FROM --platform=$BUILDPLATFORM alpine:3.13 as build
RUN apk add --no-cache hugo
WORKDIR /src
COPY . .
RUN hugo

FROM nginx:1.25-alpine
COPY --from=build /src/public /usr/share/nginx/html
