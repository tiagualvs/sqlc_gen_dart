-- name: InsertUser :one
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

-- name: GetUserById :one
SELECT * FROM users WHERE id = ? LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users WHERE username = ? LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = ? LIMIT 1;

-- name: ListUsers :many
SELECT * FROM users ORDER BY name;

-- name: UpdateUser :exec
UPDATE users
set
    name = ?,
    username = ?,
    email = ?,
    password = ?
WHERE
    id = ?;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = ?;