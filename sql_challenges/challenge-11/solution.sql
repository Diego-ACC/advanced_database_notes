-- ============================================================
-- Exercise 1 — Model Design
-- ============================================================

CREATE TABLE comments (
id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
task_id     NUMBER NOT NULL,
user_id     NUMBER NOT NULL,
content     VARCHAR2(1000) NOT NULL,
created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_comments_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id),
-- Bonus: CHECK constraint for non-empty content
CONSTRAINT check_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Questions:
-- 1. What relationships should Comment have?
--    Answer: Many-to-One with Task (Each comment belongs to one task) and
--    Many-to-One with User (Each comment is authored by one user).

-- 2. Should Task have a comments relationship?
--    Answer: Yes, a One-to-Many relationship (back-reference) allows easy
--    access to all comments associated with a specific task.

-- 3. What should happen to comments when a task is deleted?
--    Answer: They should be deleted (Cascade Delete). Comments lose their
--    context and become "orphaned" data if the parent task no longer exists.

-- ============================================================
-- Exercise 2 — Migration Creation
-- ============================================================

-- Questions:
-- 1. What does upgrade() do?
--    Answer: It contains the logic to apply changes to the database schema
--    (e.g., CREATE TABLE, ADD COLUMN) to move the database forward to a newer version.

-- 2. What does downgrade() do?
--    Answer: It contains the logic to reverse the changes made in upgrade()
--    (e.g., DROP TABLE), returning the schema to the previous state.

-- 3. What happens if you downgrade this migration?
--    Answer: The 'comments' table will be dropped from the database,
--    and all data stored within that table will be permanently lost.

-- ============================================================
-- Exercise 3 — CRUD Challenge (Conceptual SQL logic)
-- ============================================================

-- 1. Create Team
INSERT INTO teams (name, description) VALUES ('DevOps', 'Infrastructure and CI/CD');

-- 2. Create User (Assuming Team ID 3 for DevOps)
INSERT INTO users (username, email, full_name, team_id)
VALUES ('diana_ops', 'diana@example.com', 'Diana Prince', 3);

-- 3. Create 3 tasks (Using priority in description since column doesn't exist)
INSERT INTO tasks (title, description, assigned_to) VALUES ('Setup Jenkins', 'High Priority', 4);
INSERT INTO tasks (title, description, assigned_to) VALUES ('Config VPC', 'Medium Priority', 4);
INSERT INTO tasks (title, description, assigned_to) VALUES ('Update README', 'Low Priority', 4);

-- 4. Print count
SELECT COUNT(*) AS task_count FROM tasks WHERE assigned_to = 4;

-- 5. Close one task
UPDATE tasks SET status = 'closed', updated_at = CURRENT_TIMESTAMP WHERE title = 'Setup Jenkins';

-- 6. Delete lowest priority
DELETE FROM tasks WHERE title = 'Update README';

COMMIT;

-- ============================================================
-- Exercise 4 — Migration Rollback
-- ============================================================

-- Questions:
-- 1. What happens to the column?
--    Answer: The column is removed (dropped) from the table definition in the database.

-- 2. What happens to the data?
--    Answer: All data stored in that specific column is deleted and cannot be
--    recovered unless a backup exists.

-- ============================================================
-- Exercise 5 — Concept Check
-- ============================================================

-- 1. Why use ORM instead of raw SQL?
--    Answer: It allows developers to interact with the database using Python objects,
--    providing better abstraction, security (auto-escaping), and maintainability.

-- 2. Why use migrations?
--    Answer: To track and version control schema changes, ensuring all environments
--    (dev, staging, prod) stay synchronized without manual SQL scripts.

-- 3. When would you rollback?
--    Answer: When a migration contains a bug, breaks the application, or when
--    deploying a feature that needs to be reverted.

-- 4. Difference between add() and commit()?
--    Answer: add() places an object into the session (staging area),
--    while commit() flushes all changes and saves them permanently to the database.

-- 5. Why are relationships useful?
--    Answer: They automate the joining of tables, allowing you to access related
--    data (like a user's tasks) through simple attribute access (user.tasks).