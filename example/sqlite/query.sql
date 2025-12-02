-- name: InsertOneUser :one
INSERT INTO
    users (
        name,
        username,
        email,
        password
    )
VALUES (?, ?, ?, ?)
RETURNING
    *;

-- name: FindOneUserById :one
SELECT * FROM users WHERE id = ? LIMIT 1;

-- name: FindOneUserByUsername :one
SELECT * FROM users WHERE username = ? LIMIT 1;

-- name: FindOneUserByEmail :one
SELECT * FROM users WHERE email = ? LIMIT 1;

-- name: FindManyUsers :many
SELECT * FROM users;

-- name: FindPaginatedUsers :many
SELECT * FROM users
WHERE id > COALESCE(sqlc.narg('cursor'), 0)
ORDER BY id ASC;

-- name: UpdateOneUser :exec
UPDATE users
set
    name = coalesce(sqlc.narg('name'), name),
    username = coalesce(sqlc.narg('username'), username),
    email = coalesce(sqlc.narg('email'), email),
    password = coalesce(sqlc.narg('password'), password)
WHERE
    id = ?1;

-- name: DeleteOneUser :exec
DELETE FROM users WHERE id = ?;