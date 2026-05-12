package com.mukminov.service;

import com.mukminov.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class MonitorService {

    private final TaskRepository taskRepository;
    private final WorkerService workerService;

    @Scheduled(fixedRate = 2000)
    public void monitorLag() {
        Double lagSeconds = taskRepository.getQueueLagSeconds();
        int processedInTwoSeconds = workerService.getAndResetProcessedCount();
        int rps = processedInTwoSeconds / 2;

        if (lagSeconds != null) {
            log.info("=== СТАТИСТИКА ОЧЕРЕДИ ===");
            log.info("Лаг очереди: {} сек", String.format("%.2f", lagSeconds));
            log.info("Пропускная способность: {} задач/сек (сумма 2-х воркеров)", rps);
            log.info("==========================");
        }
    }
}