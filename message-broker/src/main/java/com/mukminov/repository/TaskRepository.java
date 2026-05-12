package com.mukminov.repository;

import com.mukminov.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    @Query(value = """
            SELECT * FROM marketplace.tasks 
            WHERE status = 'ready' 
              AND scheduled_at <= CURRENT_TIMESTAMP 
            ORDER BY priority DESC, created_at ASC 
            FOR UPDATE SKIP LOCKED 
            LIMIT 1
            """, nativeQuery = true)
    Optional<Task> findAndLockNextTask();

    @Query(value = """
            SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) 
            FROM marketplace.tasks 
            WHERE status = 'ready' 
            ORDER BY created_at ASC 
            LIMIT 1
            """, nativeQuery = true)
    Double getQueueLagSeconds();

    @Modifying
    @Query(value = """
            UPDATE marketplace.tasks 
            SET status = 'ready', 
                attempts = :newAttempts, 
                scheduled_at = CURRENT_TIMESTAMP + INTERVAL '5 minutes' 
            WHERE task_id = :taskId
            """, nativeQuery = true)
    void postponeTaskRetry(@Param("taskId") Integer taskId, @Param("newAttempts") int newAttempts);
}