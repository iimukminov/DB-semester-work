package com.mukminov.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@Entity
@Table(name = "orders", schema = "marketplace")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "order_id")
    private Integer id;

    @Column(name = "purchase_id", nullable = false, unique = true)
    private Integer purchaseId;

    @Column(name = "pvz_id", nullable = false)
    private Integer pvzId;

    @Column(nullable = false)
    private String status = "created";

    @Column(name = "order_date", insertable = false, updatable = false)
    private LocalDateTime orderDate;

    @Column(name = "tracking_number", length = 100)
    private String trackingNumber;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "delivery_date")
    private LocalDateTime deliveryDate;
}