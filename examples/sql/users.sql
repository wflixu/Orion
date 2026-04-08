-- name: getUserById
-- description: Get a user by ID
-- result: single
SELECT id, name, age, email FROM users WHERE id = ?;

-- name: listUsers
-- description: List all users
-- result: many
SELECT id, name, age, email FROM users ORDER BY id;

-- name: createUser
-- description: Create a new user
-- result: last_insert_id
INSERT INTO users (name, age, email) VALUES (?, ?, ?);

-- name: updateUser
-- description: Update user information
-- result: affected_rows
UPDATE users SET name = ?, age = ?, email = ? WHERE id = ?;

-- name: deleteUser
-- description: Delete a user by ID
-- result: affected_rows
DELETE FROM users WHERE id = ?;
