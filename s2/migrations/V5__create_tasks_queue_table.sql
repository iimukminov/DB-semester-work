CREATE TABLE marketplace.tasks (
                                   task_id SERIAL PRIMARY KEY,
                                   payload JSONB NOT NULL,
                                   status VARCHAR(20) DEFAULT 'ready' CHECK (status IN ('ready', 'running', 'completed', 'failed')),
                                   priority INT DEFAULT 0,
                                   attempts INT DEFAULT 0,
                                   scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_ready ON marketplace.tasks (priority DESC, scheduled_at ASC) WHERE status = 'ready';

ALTER TABLE marketplace.tasks SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_scale_factor = 0.01,
    autovacuum_analyze_threshold = 50
);