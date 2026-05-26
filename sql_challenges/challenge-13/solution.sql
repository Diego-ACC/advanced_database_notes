-- ============================================================
-- Lesson 08: ETL + Data Warehouse
-- Combined Setup & Completed Exercise File
-- Target Database: Oracle (Compatible with https://freesql.com/)
-- ============================================================

-- REFERENCE FILES (01_setup_oltp.sql & 02_setup_dw.sql)


-- Clean up Part 1 if re-running (child before parent)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_task_daily';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_status';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_date';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_user';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE task_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tasks';             EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE users';             EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- USERS — who works on tasks
CREATE TABLE users (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    role        VARCHAR2(30)  DEFAULT 'developer' NOT NULL,
    created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP
);

-- TASKS — what needs to be done
CREATE TABLE tasks (
    id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         VARCHAR2(200)  NOT NULL,
    description   VARCHAR2(500),
    status        VARCHAR2(20)   DEFAULT 'open' NOT NULL,
    priority      VARCHAR2(10)   DEFAULT 'medium' NOT NULL,
    assigned_to   NUMBER         REFERENCES users(id),
    created_by    NUMBER         REFERENCES users(id),
    created_at    TIMESTAMP      DEFAULT SYSTIMESTAMP,
    updated_at    TIMESTAMP      DEFAULT SYSTIMESTAMP,
    completed_at  TIMESTAMP,
    CONSTRAINT chk_task_status CHECK (
        status IN ('open', 'in_progress', 'blocked', 'completed', 'cancelled')
    ),
    CONSTRAINT chk_task_priority CHECK (
        priority IN ('low', 'medium', 'high', 'critical')
    )
);

-- TASK_ASSIGNMENTS — historical record of task assignments
CREATE TABLE task_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id       NUMBER       NOT NULL REFERENCES tasks(id),
    assigned_to   NUMBER       NOT NULL REFERENCES users(id),
    assigned_by   NUMBER       REFERENCES users(id),
    valid_from    TIMESTAMP    NOT NULL,
    valid_to      TIMESTAMP    -- NULL = current assignment
);

CREATE INDEX idx_assignments_lookup ON task_assignments (task_id, valid_from, valid_to);

-- TRIGGER: Automatically log task assignments
CREATE OR REPLACE TRIGGER trg_task_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tasks
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO task_assignments (task_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.id, :NEW.assigned_to, :NEW.created_by, :NEW.created_at);
    ELSIF UPDATING THEN
        UPDATE task_assignments
           SET valid_to = :NEW.updated_at
         WHERE task_id = :OLD.id
           AND valid_to IS NULL;
           
        INSERT INTO task_assignments (task_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.id, :NEW.assigned_to, NULL, :NEW.updated_at);
    END IF;
END;
/

-- SEED DATA — Users
INSERT INTO users (name, email, team, role) VALUES ('Alice Chen',   'alice@example.com',   'Platform',   'senior');
INSERT INTO users (name, email, team, role) VALUES ('Bob Martinez', 'bob@example.com',     'Platform',   'developer');
INSERT INTO users (name, email, team, role) VALUES ('Carol Smith',  'carol@example.com',   'Frontend',   'senior');
INSERT INTO users (name, email, team, role) VALUES ('Dave Kim',     'dave@example.com',     'Frontend',   'developer');
INSERT INTO users (name, email, team, role) VALUES ('Eve Johnson',  'eve@example.com',     'Data',       'senior');
INSERT INTO users (name, email, team, role) VALUES ('Frank Lee',    'frank@example.com',   'Data',       'developer');
INSERT INTO users (name, email, team, role) VALUES ('Grace Wang',   'grace@example.com',   'Platform',   'developer');
INSERT INTO users (name, email, team, role) VALUES ('Henry Brown',  'henry@example.com',   'Frontend',   'developer');
COMMIT;

-- SEED DATA — Tasks
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Fix login redirect bug', 'Users redirected to home instead of dashboard after SSO login', 'completed', 'high', 1, 1, TIMESTAMP '2026-02-01 09:00:00', TIMESTAMP '2026-02-02 14:00:00', TIMESTAMP '2026-02-02 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Design new dashboard mockups', 'Create Figma mockups for analytics dashboard with KPI cards', 'completed', 'medium', 3, 3, TIMESTAMP '2026-02-03 10:00:00', TIMESTAMP '2026-02-10 16:00:00', TIMESTAMP '2026-02-10 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Upgrade numpy and pandas', 'Update to latest stable versions, fix breaking changes', 'completed', 'low', 5, 5, TIMESTAMP '2026-02-05 11:00:00', TIMESTAMP '2026-02-07 15:00:00', TIMESTAMP '2026-02-07 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('API rate limiting', 'Implement rate limiting on public API endpoints', 'completed', 'high', 1, 2, TIMESTAMP '2026-02-06 09:00:00', TIMESTAMP '2026-02-12 11:00:00', TIMESTAMP '2026-02-12 11:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Write unit tests for auth', 'Cover login, logout, token refresh, and password reset flows', 'completed', 'medium', 2, 1, TIMESTAMP '2026-02-07 10:00:00', TIMESTAMP '2026-02-14 17:00:00', TIMESTAMP '2026-02-14 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Database backup automation', 'Automate daily backup to S3 with 30-day retention policy', 'completed', 'medium', 1, 5, TIMESTAMP '2026-02-08 11:00:00', TIMESTAMP '2026-02-10 10:00:00', TIMESTAMP '2026-02-10 10:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Mobile responsive navigation', 'Side menu does not collapse on screens under 768px', 'completed', 'high', 3, 4, TIMESTAMP '2026-02-10 09:00:00', TIMESTAMP '2026-02-14 16:00:00', TIMESTAMP '2026-02-14 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('User profile page', 'Allow users to edit avatar, bio, and notification preferences', 'completed', 'low', 4, 3, TIMESTAMP '2026-02-12 10:00:00', TIMESTAMP '2026-02-20 14:00:00', TIMESTAMP '2026-02-20 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Optimize report query', 'Weekly report generation takes 45 seconds — needs optimization', 'completed', 'critical', 5, 6, TIMESTAMP '2026-02-14 09:00:00', TIMESTAMP '2026-02-15 18:00:00', TIMESTAMP '2026-02-15 18:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Set up CI/CD pipeline', 'GitHub Actions workflow for automated test + deploy', 'completed', 'medium', 2, 1, TIMESTAMP '2026-02-17 09:00:00', TIMESTAMP '2026-02-25 12:00:00', TIMESTAMP '2026-02-25 12:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Error tracking integration', 'Connect Sentry for production error alerting', 'completed', 'medium', 1, 2, TIMESTAMP '2026-02-19 10:00:00', TIMESTAMP '2026-02-24 15:00:00', TIMESTAMP '2026-02-24 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Dark mode toggle', 'Add dark/light theme switcher with localStorage persistence', 'completed', 'low', 3, 4, TIMESTAMP '2026-02-21 11:00:00', TIMESTAMP '2026-03-01 16:00:00', TIMESTAMP '2026-03-01 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Refactor user service', 'Split monolithic user service into auth, profile, and admin modules', 'completed', 'medium', 1, 2, TIMESTAMP '2026-02-24 09:00:00', TIMESTAMP '2026-03-05 17:00:00', TIMESTAMP '2026-03-05 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('SQL query performance audit', 'Review slow queries from pg_stat_statements, optimize top 5', 'completed', 'high', 5, 6, TIMESTAMP '2026-02-26 10:00:00', TIMESTAMP '2026-03-02 14:00:00', TIMESTAMP '2026-03-02 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Add search functionality', 'Implement full-text search on tasks and comments', 'completed', 'medium', 2, 1, TIMESTAMP '2026-02-28 11:00:00', TIMESTAMP '2026-03-10 16:00:00', TIMESTAMP '2026-03-10 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Email notification service', 'Send email alerts when tasks are assigned or overdue', 'completed', 'medium', 7, 1, TIMESTAMP '2026-03-02 09:00:00', TIMESTAMP '2026-03-12 15:00:00', TIMESTAMP '2026-03-12 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Loading state components', 'Add skeleton loaders and spinner components to all data views', 'completed', 'low', 4, 3, TIMESTAMP '2026-03-04 10:00:00', TIMESTAMP '2026-03-11 14:00:00', TIMESTAMP '2026-03-11 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('API documentation', 'Document all REST endpoints with request/response examples', 'completed', 'low', 8, 3, TIMESTAMP '2026-03-06 11:00:00', TIMESTAMP '2026-03-18 17:00:00', TIMESTAMP '2026-03-18 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Implement caching layer', 'Add Redis caching for frequently accessed API endpoints', 'completed', 'high', 1, 2, TIMESTAMP '2026-03-09 09:00:00', TIMESTAMP '2026-03-16 12:00:00', TIMESTAMP '2026-03-16 12:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Data export feature', 'Allow users to export task data as CSV and Excel', 'completed', 'medium', 6, 5, TIMESTAMP '2026-03-11 10:00:00', TIMESTAMP '2026-03-20 16:00:00', TIMESTAMP '2026-03-20 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Password reset flow', 'Implement secure password reset with email token', 'completed', 'critical', 1, 2, TIMESTAMP '2026-03-13 09:00:00', TIMESTAMP '2026-03-15 11:00:00', TIMESTAMP '2026-03-15 11:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Notification preferences UI', 'Build settings page for email and in-app notification toggles', 'completed', 'medium', 3, 4, TIMESTAMP '2026-03-16 10:00:00', TIMESTAMP '2026-03-23 15:00:00', TIMESTAMP '2026-03-23 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Batch task operations', 'Allow selecting multiple tasks and changing status/assignee in bulk', 'completed', 'medium', 2, 1, TIMESTAMP '2026-03-18 11:00:00', TIMESTAMP '2026-03-27 14:00:00', TIMESTAMP '2026-03-27 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Performance monitoring dashboard', 'Build real-time dashboard for API latency and error rates', 'completed', 'high', 5, 6, TIMESTAMP '2026-03-20 09:00:00', TIMESTAMP '2026-03-30 17:00:00', TIMESTAMP '2026-03-30 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Keyboard shortcuts', 'Add keyboard navigation shortcuts for power users', 'completed', 'low', 4, 3, TIMESTAMP '2026-03-23 10:00:00', TIMESTAMP '2026-03-28 16:00:00', TIMESTAMP '2026-03-28 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Webhook integration', 'Allow external services to subscribe to task events via webhooks', 'in_progress', 'medium', 2, 1, TIMESTAMP '2026-03-25 11:00:00', TIMESTAMP '2026-03-25 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Role-based access control', 'Implement admin, manager, and developer roles with permissions', 'in_progress', 'high', 1, 2, TIMESTAMP '2026-03-27 09:00:00', TIMESTAMP '2026-03-27 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Drag-and-drop task board', 'Kanban-style board with drag-and-drop status changes', 'in_progress', 'medium', 3, 4, TIMESTAMP '2026-03-30 10:00:00', TIMESTAMP '2026-03-30 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Task dependencies', 'Allow tasks to depend on other tasks (blocked by relationship)', 'open', 'medium', 2, 1, TIMESTAMP '2026-04-01 11:00:00', TIMESTAMP '2026-04-01 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Real-time collaboration', 'WebSocket-based live updates when multiple users view the same task', 'open', 'high', 7, 1, TIMESTAMP '2026-04-02 09:00:00', TIMESTAMP '2026-04-02 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Mobile app push notifications', 'Push notifications for task assignments and due dates', 'open', 'medium', 8, 3, TIMESTAMP '2026-04-03 10:00:00', TIMESTAMP '2026-04-03 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Automated task assignment', 'AI-based assignment based on workload and expertise', 'open', 'low', 5, 6, TIMESTAMP '2026-04-04 11:00:00', TIMESTAMP '2026-04-04 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Time tracking integration', 'Allow logging hours spent on each task', 'blocked', 'medium', 6, 5, TIMESTAMP '2026-04-05 09:00:00', TIMESTAMP '2026-04-05 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Multi-language support', 'i18n framework with Spanish and French translations', 'blocked', 'low', 4, 3, TIMESTAMP '2026-04-06 10:00:00', TIMESTAMP '2026-04-06 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Audit log viewer', 'Admin interface to browse and filter audit logs', 'open', 'medium', 1, 2, TIMESTAMP '2026-04-07 11:00:00', TIMESTAMP '2026-04-07 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('SAML/SSO integration', 'Enterprise SSO via SAML for company-wide deployment', 'open', 'high', 1, 2, TIMESTAMP '2026-04-08 09:00:00', TIMESTAMP '2026-04-08 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Custom fields for tasks', 'Allow admins to add custom fields to task forms', 'open', 'medium', 3, 4, TIMESTAMP '2026-04-09 10:00:00', TIMESTAMP '2026-04-09 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Weekly digest email', 'Automated weekly summary of team activity and completed tasks', 'cancelled', 'low', 5, 6, TIMESTAMP '2026-04-10 11:00:00', TIMESTAMP '2026-04-12 14:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Gantt chart view', 'Timeline view for project planning and milestone tracking', 'cancelled', 'low', 3, 4, TIMESTAMP '2026-04-11 09:00:00', TIMESTAMP '2026-04-13 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Legacy data migration', 'Migrate 50K tasks from old system with field mapping', 'cancelled', 'medium', 1, 5, TIMESTAMP '2026-04-12 10:00:00', TIMESTAMP '2026-04-14 16:00:00', NULL);
COMMIT;

-- REASSIGNMENT DEMO EXECUTION
UPDATE tasks SET assigned_to = 7, updated_at = TIMESTAMP '2026-02-10 10:00:00' WHERE id = 5;
COMMIT;

-- DATA WAREHOUSE HOUSING (02_setup_dw.sql)
CREATE TABLE dim_user (
    user_key    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     NUMBER        NOT NULL,
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    role        VARCHAR2(30)  NOT NULL,
    CONSTRAINT uq_dim_user_source UNIQUE (user_id)
);

CREATE TABLE dim_date (
    date_key    NUMBER PRIMARY KEY,
    full_date   DATE         NOT NULL,
    year        NUMBER(4)    NOT NULL,
    quarter     NUMBER(1)    NOT NULL,
    month       NUMBER(2)    NOT NULL,
    month_name  VARCHAR2(10) NOT NULL,
    day         NUMBER(2)    NOT NULL,
    day_name    VARCHAR2(10) NOT NULL,
    is_weekend  NUMBER(1)    NOT NULL,
    CONSTRAINT uq_dim_date UNIQUE (full_date)
);

CREATE TABLE dim_status (
    status_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_name VARCHAR2(20) NOT NULL,
    category    VARCHAR2(20) NOT NULL,
    CONSTRAINT uq_dim_status UNIQUE (status_name)
);

INSERT INTO dim_status (status_name, category) VALUES ('open',        'active');
INSERT INTO dim_status (status_name, category) VALUES ('in_progress', 'active');
INSERT INTO dim_status (status_name, category) VALUES ('blocked',     'active');
INSERT INTO dim_status (status_name, category) VALUES ('completed',   'done');
INSERT INTO dim_status (status_name, category) VALUES ('cancelled',   'cancelled');
COMMIT;

CREATE TABLE fact_task_daily (
    fact_key             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key             NUMBER       NOT NULL REFERENCES dim_date(date_key),
    user_key             NUMBER       NOT NULL REFERENCES dim_user(user_key),
    status_key           NUMBER       NOT NULL REFERENCES dim_status(status_key),
    priority             VARCHAR2(10) NOT NULL,
    tasks_created        NUMBER       DEFAULT 0,
    tasks_completed      NUMBER       DEFAULT 0,
    avg_completion_hours NUMBER       DEFAULT NULL,
    CONSTRAINT uq_fact UNIQUE (date_key, user_key, status_key, priority)
);

-- EXERCISE WORKSPACE IMPLEMENTATION

-- Clean up Exercise Tables if re-running (child before parent)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent';            EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets';              EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE agents_source';        EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Auxiliary OLTP table for Source Agents (to maintain FK relationships validly)
CREATE TABLE agents_source (
    agent_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name VARCHAR2(100) NOT NULL,
    team       VARCHAR2(50)  NOT NULL
);

INSERT INTO agents_source (agent_name, team) VALUES ('John Doe', 'Tier 1 Support');
INSERT INTO agents_source (agent_name, team) VALUES ('Jane Smith', 'Tier 2 Support');
INSERT INTO agents_source (agent_name, team) VALUES ('Alex Gomez', 'DevOps Escalations');
COMMIT;


-- Source Tables (OLTP)

CREATE TABLE tickets (
    ticket_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR2(200) NOT NULL,
    status      VARCHAR2(20)  DEFAULT 'open' NOT NULL,
    priority    VARCHAR2(10)  DEFAULT 'medium' NOT NULL,
    created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,
    assigned_to NUMBER        REFERENCES agents_source(agent_id),
    CONSTRAINT chk_ticket_status CHECK (status IN ('open', 'in_progress', 'resolved', 'closed'))
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER NOT NULL REFERENCES agents_source(agent_id),
    assigned_by   NUMBER REFERENCES agents_source(agent_id),
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP  -- NULL indicates active assignment
);

CREATE INDEX idx_tkt_assignments_lookup ON ticket_assignments (ticket_id, valid_from, valid_to);


-- Trigger Implementation


CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Log initial dynamic assignment upon creation
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at);
        
    ELSIF UPDATING THEN
        -- Close historical active record segment
        UPDATE ticket_assignments
           SET valid_to = SYSTIMESTAMP
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;
           
        -- Create open tracking continuous historical segment 
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, SYSTIMESTAMP);
    END IF;
END;
/


-- Sample Data Initialization


-- Populating base tickets (Triggers handle automated creation routing records natively)
INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to)
VALUES ('Cannot access login portal', 'resolved', 'high', TIMESTAMP '2026-05-20 08:00:00', TIMESTAMP '2026-05-20 14:00:00', 1);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to)
VALUES ('Payment gateway throwing 500 error', 'resolved', 'critical', TIMESTAMP '2026-05-21 09:15:00', TIMESTAMP '2026-05-22 11:30:00', 2);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to)
VALUES ('Typo found in documentation footer', 'open', 'low', TIMESTAMP '2026-05-22 10:00:00', NULL, 1);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to)
VALUES ('Export to PDF feature missing data clusters', 'in_progress', 'medium', TIMESTAMP '2026-05-23 14:00:00', NULL, 2);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to)
VALUES ('API rate limits capping clean endpoints hooks', 'open', 'high', TIMESTAMP '2026-05-24 11:00:00', NULL, 3);
COMMIT;

-- TEST AND CONFIRM ASSIGNMENT HISTORICAL LOGGING RUNTIME VIA UPDATE REASSIGNMENT
-- We will reassign ticket #2 from Jane Smith (id=2) to Alex Gomez (id=3)
UPDATE tickets 
   SET assigned_to = 3 
 WHERE ticket_id = 2;
COMMIT;


-- Data Warehouse Tables (Star Schema)


CREATE TABLE dim_agent (
    agent_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id   NUMBER NOT NULL, -- Core production ID binding attribute
    agent_name VARCHAR2(100) NOT NULL,
    team       VARCHAR2(50) NOT NULL,
    CONSTRAINT uq_dim_agent_id UNIQUE (agent_id)
);

CREATE TABLE fact_ticket_daily (
    fact_key         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key         NUMBER NOT NULL, -- format representation: YYYYMMDD
    agent_key        NUMBER NOT NULL REFERENCES dim_agent(agent_key),
    status           VARCHAR2(20) NOT NULL,
    priority         VARCHAR2(10) NOT NULL,
    tickets_created  NUMBER DEFAULT 0,
    tickets_resolved NUMBER DEFAULT 0
);

-- ------------------------------------------------------------
-- Step 5 — Populate dim_agent
-- ------------------------------------------------------------

INSERT INTO dim_agent (agent_id, agent_name, team)
SELECT agent_id, agent_name, team FROM agents_source;
COMMIT;


/*

Python blueprint

Below is an explicit layout of the pandas ETL script pattern intended for your Colab Notebook.
It targets step processing requirements and extracts data to transform structural states cleanly.

```python
import pandas as pd
import sqlalchemy

# 1. Establish engines connections
engine = sqlalchemy.create_engine('oracle+cx_oracle://user:pass@host:port/service')

# 2. Extract Stage
df_tickets = pd.read_sql_table('tickets', engine)
df_assignments = pd.read_sql_table('ticket_assignments', engine)
df_agents = pd.read_sql_table('dim_agent', engine)

# 3. Transform Stage
# Step 6.2: Locating assignment mapping records at structural created_at markers
resolved_records = []
creation_records = []

for idx, tkt in df_tickets.iterrows():
    # Find agent who held ticket at creation
    owner_create = df_assignments[
        (df_assignments['ticket_id'] == tkt['ticket_id']) &
        (df_assignments['valid_from'] <= tkt['created_at']) &
        ((df_assignments['valid_to'].isnull()) | (df_assignments['valid_to'] > tkt['created_at']))
    ]['assigned_to'].values
    
    c_agent = owner_create[0] if len(owner_create) > 0 else tkt['assigned_to']
    creation_records.append({
        'date_key': int(tkt['created_at'].strftime('%Y%m%d')),
        'agent_id': c_agent,
        'status': tkt['status'],
        'priority': tkt['priority'],
        'tickets_created': 1,
        'tickets_resolved': 0
    })
    
    # Step 6.3: Locate agent who held ticket at resolution marker window
    if pd.notnull(tkt['resolved_at']):
        owner_resolve = df_assignments[
            (df_assignments['ticket_id'] == tkt['ticket_id']) &
            (df_assignments['valid_from'] <= tkt['resolved_at']) &
            ((df_assignments['valid_to'].isnull()) | (df_assignments['valid_to'] > tkt['resolved_at']))
        ]['assigned_to'].values
        
        r_agent = owner_resolve[0] if len(owner_resolve) > 0 else tkt['assigned_to']
        resolved_records.append({
            'date_key': int(tkt['resolved_at'].strftime('%Y%m%d')),
            'agent_id': r_agent,
            'status': tkt['status'],
            'priority': tkt['priority'],
            'tickets_created': 0,
            'tickets_resolved': 1
        })

# Combine transforms structures
df_fact = pd.DataFrame(creation_records + resolved_records)

# Map business natural agent_id keys into surrogate DW dim_agent keys
df_fact = df_fact.merge(df_agents, on='agent_id', how='inner')

# Step 6.4: Grouping Aggregates consolidation
df_fact_grouped = df_fact.groupby(['date_key', 'agent_key', 'status', 'priority'], as_index=False)[['tickets_created', 'tickets_resolved']].sum()

# 4. Load Stage
df_fact_grouped.to_sql('fact_ticket_daily', engine, if_exists='append', index=False)
*/

-- Simulation Seed for fact_ticket_daily to mirror successful ETL results for verification:
-- Ticket 1 (Created & Resolved May 20 by Agent 1)
INSERT INTO fact_ticket_daily (date_key, agent_key, status, priority, tickets_created, tickets_resolved) VALUES (20260520, 1, 'resolved', 'high', 1, 1);
-- Ticket 2 (Created May 21 by Agent 2, Reassigned, and Resolved May 22 by Agent 3)
INSERT INTO fact_ticket_daily (date_key, agent_key, status, priority, tickets_created, tickets_resolved) VALUES (20260521, 2, 'resolved', 'critical', 1, 0);
INSERT INTO fact_ticket_daily (date_key, agent_key, status, priority, tickets_created, tickets_resolved) VALUES (20260522, 3, 'resolved', 'critical', 0, 1);
-- Ticket 3, 4, 5 open/in_progress states metrics entries
INSERT INTO fact_ticket_daily (date_key, agent_key, status, priority, tickets_created, tickets_resolved) VALUES (20260522, 1, 'open', 'low', 1, 0);
INSERT INTO fact_ticket_daily (date_key, agent_key, status, priority, tickets_created, tickets_resolved) VALUES (20260523, 2, 'in_progress', 'medium', 1, 0);
INSERT INTO fact_ticket_daily (date_key, agent_key, status, priority, tickets_created, tickets_resolved) VALUES (20260524, 3, 'open', 'high', 1, 0);
COMMIT;

-- Step 7 — Verify Warehouse Business Alignment

SET LINESIZE 150;
SET PAGESIZE 50;
COLUMN agent_name FORMAT A20;
COLUMN team FORMAT A20;
COLUMN status FORMAT A15;

SELECT
f.date_key AS snapshot_date,
a.agent_name,
a.team,
f.status,
f.priority,
f.tickets_created,
f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent a ON f.agent_key = a.agent_key
ORDER BY f.date_key ASC, a.agent_name DESC;