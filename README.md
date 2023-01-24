Prototype to Deployment
==============================
<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a>
    <img src="readme-assets/intro.png" alt="Logo" width="240" height="240">
  </a>
</div>

A cloud native centralized IoT platform for healthcare monitoring.

This project offers a comprehensive cloud solution for simulating, testing, and deploying IoT devices with added capabilities including analytics, reporting, monitoring, auditing, and failure notifications.

Project Organization
-----------

|---readme-assets
|---README.md
|---simulation_details.json
|---references
|---reports
		figures
+---device_simulator
|       device_simulator.zip
|       runSimulation.json
\---virtual_device_creator
        create_root_ca_bundle.sh
        iot_template_body.json
        lambda_function.py
        pub_sub.sh
        virtual_device_creator.sh
		
-----------

Architecture
------------
AWS Architecture Diagram

<div align="center">
  <a>
    <img src="readme-assets/aws-architecture-diagram.png" alt="Logo" width="480" height="480">
  </a>
</div>


------------

Outputs
------------
Dashboard and Alert/Failure Notifications 

Dashboard

<div align="center">
  <a>
    <img src="readme-assets/dashboard.png" alt="Logo" width="480" height="360">
  </a>
</div>

<div align="center">
  <a>
    <img src="readme-assets/dashboard-metrics.png" alt="Logo" width="480" height="360">
  </a>
</div>

Notifications:

<div align="center">
  <a>
    <img src="readme-assets/notifications-audit.png" alt="Logo" width="480" height="360">
  </a>
</div>

Ackowledgements
------------
* [AWS Docs](https://docs.aws.amazon.com/)
* [Parnika Kaushik]
* [Rubani Bhatia]
--------