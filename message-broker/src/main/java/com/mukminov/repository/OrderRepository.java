package com.mukminov.repository;

import com.mukminov.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrderRepository extends JpaRepository<Order, Long> {
    @Modifying
    @Query(value = """
            UPDATE marketplace.orders 
            SET delivery_date = CURRENT_TIMESTAMP 
            WHERE order_id = :orderId
            """, nativeQuery = true)
    void updateOrderDeliveryDate(@Param("orderId") Integer orderId);
}