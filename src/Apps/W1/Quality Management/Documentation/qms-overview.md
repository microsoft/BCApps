---
title: Quality management overview
description: Learn how to use quality management to ensure product quality through automated and manual testing, lot grading, and workflow integration.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Quality management overview

Quality Management is a quality inspection application for [!INCLUDE [prod_short](includes/prod_short.md)]. The app provides comprehensive quality control capabilities throughout your business operations. This app enables automated and manual quality testing for purchase receipts, production and assembly output, and warehouse operations.

Quality Management helps you maintain product quality standards by creating inspection tests at key points in your business processes. The app integrates seamlessly with purchasing, production, assembly, and warehouse management in [!INCLUDE [prod_short](includes/prod_short.md)] to embed quality control in your daily operations.

### Key capabilities

The Quality Management app offers a range of benefits.

- **Automated Test Creation**: Automatically generate quality inspection tests when you receive purchase orders, post production and assembly output, or process warehouse movements.
- **Manual Test Creation**: Create quality tests on-demand for reactive testing scenarios.
- **Scheduled Test Creation**: Create quality tests for routing, periodic inspections using job queues.
- **Template-Based Testing**: Use predefined quality inspection templates with customizable measurements and pass/fail criteria.
- **Lot Blocking and Grading**: Automatically block or grade inventory lots based on test results.
- **Workflow Integration**: Configure automated responses to test results using workflows for quality management.
- **Inventory Movement**: Comprehensive features for processing noncompliant items. For example, you can do automatic movements to quarantine bins, make negative adjustments for disposal, transfer orders to different locations, and create purchase returns to vendors.
- **Warehouse Integration**: Full support for locations with and without warehouse handling.

## Getting started

Setting up Quality Management involves configuring templates, test generation rules, and integration with your [!INCLUDE [prod_short](includes/prod_short.md)] processes. To learn more, go to:

- [Initial Setup and Configuration](qms-setup.md)
- [Assisted Setup Wizard](qms-assisted-setup-wizard.md)
- [Configuring Quality Inspection Grades](qms-configuring-grades.md)
- [Creating Quality Inspection Templates](qms-quality-templates.md)
- [Setting Up Test Generation Rules](qms-test-generation-rules.md)
- [Configuring Workflows](qms-quality-workflows.md)

## How to Use

After you configure the app, Quality Management gives you several ways to create and manage quality tests.

### Purchase receipt testing

- [Purchase Receipt Testing Without Warehouse Tracking](qms-purchase-receipt-testing-simple.md)
- [Purchase Receipt Testing With Warehouse Tracking](qms-purchase-receipt-testing-warehouse.md)

### Production testing

- [Production Output Quality Testing](qms-production-output-testing.md)

### Manual and scheduled testing

- [Manual Test Creation](qms-manual-test-creation.md)
- [Scheduled Test Creation](qms-scheduled-test-creation.md)

### Quality control actions

- [Lot Blocking and Unblocking](qms-lot-blocking-unblocking.md)
- [Processing Non-Compliant Items](qms-non-compliant-processing.md)

## Prerequisites

- Microsoft Dynamics 365 Business Central (on-premises or cloud)
- Premium experience tier (required for production order functionality)
- Quality Management app is installed and configured

## Related information

[Microsoft Dynamics 365 Business Central Documentation](/dynamics365/business-central)