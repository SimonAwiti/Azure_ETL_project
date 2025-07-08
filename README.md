# Azure_ETL_Project

An Azure ETL project that ingests data from **IoT sensors** and **user-facing applications** for **real-time analytics**, **batch processing**, and **Power BI visualization**. The system is designed using serverless compute and managed Azure services for scalability, cost-efficiency, and maintainability.

---

## 🚀 Architecture Overview

![alt text](<Screenshot 2025-07-07 at 10.11.28 PM.png>)

### 📥 Data Ingestion

- **IoT Devices** stream telemetry data to **Azure IoT Hub**.
- **Azure IoT Hub** uses an **Event Hub trigger** to invoke an **Azure Function**.
- **User-facing applications** send certification and operational data to the same Azure Function via **HTTP triggers**.

### ⚙️ Processing & Storage

- **Azure Function App** (deployed in the Application Subnet) performs:
  - Real-time operational updates pushed to **Azure SQL Database**.
  - Archival of raw data into **Azure Data Lake Gen2** for batch processing.

### 🧠 Data Transformation & ETL

- **Azure Synapse Pipelines** (in the Analytics Subnet) orchestrate the ETL workflow:
  - Pulls data from **Azure SQL DB** and **Data Lake Gen2**.
  - Transforms and moves data into a curated zone for analytics.

### 📊 Analytics & Reporting

- **Azure Synapse Analytics (Serverless SQL Pool)** accesses the curated data for reporting.
- **Power BI** connects to Synapse Analytics for dashboards and visual insights.

---

## 🧾 Subnet and Network Segmentation

- **Virtual Network**: Ensures secure communication between all services.
- **Application Subnet**: Hosts the Function App, controlled via NSGs.
- **DB Subnet**: Hosts Azure SQL DB, protected by DB-specific NSGs.
- **Analytics Subnet**: Hosts Synapse workloads, protected by Synapse NSGs.


---

## ✅ Summary

This architecture provides a scalable and secure Azure-native data pipeline that handles both **streaming** and **batch workloads**, with clear separation of ingestion, transformation, and analytics layers.

---

