CREATE TABLE "events"
(
    "id"          UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    "test"      TEXT        NOT NULL,
    "created"     timestamptz NOT NULL DEFAULT current_timestamp
);