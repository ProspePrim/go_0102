# Start by building the application.
ARG PORT="9000"
ARG HOST="0.0.0.0"
ARG DB_URL="postgres://user:pass@db:5432/app"

FROM golang:1.19-alpine as build

WORKDIR /go/src/app
COPY . .

RUN go mod download
RUN go build -o /go/bin/app.bin cmd/main.go

# Now copy it into our base image.
FROM gcr.io/distroless/base-debian11
COPY --from=build /go/bin/app /
CMD ["/app.bin"]


# Start by building the application.
FROM golang:1.19-alpine as build

ENV USER=appuser
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "$UID" \
    "$USER"

WORKDIR $GOPATH/src/app/

COPY ["src/go.mod", "src/go.sum", "./"]
RUN go mod download && go mod verify 

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build  -o /go/bin/app.bin cmd/main.go

# Now copy it into our base image.
FROM gcr.io/distroless/base-debian11 as final

ENV PORT ${PORT}
ENV HOST ${HOST}
ENV DB_URL ${DB_URL}

COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /app.bin /app.bin

USER $USER:$USER

EXPOSE $PORT

ENTRYPOINT ["/bin/sh", "-c", "/app.bin -port=$PORT -host=$HOST -dbUrl=$DB_URL"]
