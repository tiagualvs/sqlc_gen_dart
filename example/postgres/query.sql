-- name: InsertUser :one
INSERT INTO
    users (
        name,
        username,
        email,
        password
    )
VALUES ($1, $2, $3, $4)
RETURNING
    *;

-- name: GetUserById :one
SELECT * FROM users WHERE id = $1 LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users WHERE username = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1 LIMIT 1;

-- name: ListUsers :many
SELECT * FROM users ORDER BY name;

-- name: ListUsersWithPagination :many
SELECT *
FROM users
WHERE id > $1
ORDER BY id ASC
LIMIT $2::int;

-- name: UpdateUser :exec
UPDATE users
set
    name = coalesce($2, name),
    username = coalesce($3, username),
    email = coalesce($4, email),
    password = coalesce($5, password)
WHERE
    id = $1;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;