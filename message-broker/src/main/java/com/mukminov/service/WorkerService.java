package com.mukminov.service;

import com.mukminov.entity.Task;
import com.mukminov.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Service
@RequiredArgsConstructor
public class WorkerService {

    private final TaskRepository taskRepository;
    private final AtomicInteger processedTasksCounter = new AtomicInteger(0);

    @Scheduled(fixedDelay = 50)
    @Transactional
    public void workerOne() {
        processTask("Worker-1");
    }

    @Scheduled(fixedDelay = 50)
    @Transactional
    public void workerTwo() {
        processTask("Worker-2");
    }

    private void processTask(String workerName) {
        Optional<Task> taskOpt = taskRepository.findAndLockNextTask();
        
        if (taskOpt.isPresent()) {
            Task task = taskOpt.get();
            log.info("{} взял задачу ID: {} с приоритетом {}", workerName, task.getId(), task.getPriority());

            try {
                task.setStatus("running");
                taskRepository.saveAndFlush(task);

                Thread.sleep(50);

                if (Math.random() < 0.1) {
                    throw new RuntimeException("Случайный сбой!");
                }

                task.setStatus("completed");
                taskRepository.save(task);

                processedTasksCounter.incrementAndGet();

            } catch (Exception e) {
                log.error("{} Ошибка при обработке задачи ID: {}", workerName, task.getId());
                handleFailure(task);
            }
        }
    }

    public int getAndResetProcessedCount() {
        return processedTasksCounter.getAndSet(0);
    }

    private void handleFailure(Task task) {
        int newAttempts = task.getAttempts() + 1;
        task.setAttempts(newAttempts);

        if (newAttempts >= 3) {
            task.setStatus("failed");
            taskRepository.save(task);
        } else {
            taskRepository.postponeTaskRetry(task.getId(), newAttempts);
        }
    }
}