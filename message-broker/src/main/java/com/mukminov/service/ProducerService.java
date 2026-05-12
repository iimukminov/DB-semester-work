package com.mukminov.service;

import com.mukminov.entity.Order;
import com.mukminov.entity.Task;
import com.mukminov.repository.OrderRepository;
import com.mukminov.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Random;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProducerService {

    private final TaskRepository taskRepository;
    private final OrderRepository orderRepository;
    private final Random random = new Random();

    @Scheduled(fixedRate = 100)
    @Transactional
    public void generateTasks() {
        for (int i = 0; i < 30; i++) {
            int existingOrderId = random.nextInt(10000) + 1;
            orderRepository.updateOrderDeliveryDate(existingOrderId);

            String orderId = UUID.randomUUID().toString();
            Task task = new Task();
            task.setPayload("{\"order_id\": \"" + orderId + "\"}");
            task.setPriority((random.nextInt(100) < 20) ? 100 : 0);

            taskRepository.save(task);
        }
    }
}