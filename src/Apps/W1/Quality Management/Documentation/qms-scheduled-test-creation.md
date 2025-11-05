---
title: Scheduled test creation
description: Learn how to set up and use scheduled quality inspection tests to ensure proactive quality management through automated, time-based test creation.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Scheduled test creation

This article explains how to set up and use quality inspection tests that are created automatically and scheduled to run at regular intervals using job queues.

Scheduled tests enable proactive quality management. They automatically generate quality inspection tests based on time intervals, rather than business transactions. This capability is ideal for:

- Routine inspections that involve regular sampling of your in-stock inventory.
- Shelf life monitoring where you periodically test items that are approaching expiration.
- Environmental compliance testing to meet time-based testing requirements.
- Statistical quality control through systematic sampling programs.
- Preventive quality assurance supported by proactive testing schedules.

## Prerequisites

- Quality inspection templates are configured.
- The job queue functionality is enabled.
- Test generation rules are configured for creating scheduled tests.
- Items are available for scheduled testing.
- Users have the permissions they need for the job queue.

## Understand scheduled testing

The following table illustrates the differences between scheduled and transaction-based testing.

| Feature | Transaction-Based | Scheduled |
|---------|------------------|-----------|
| Trigger | Business transactions (receipts, output) | Time intervals |
| Frequency | Event-driven | Regular intervals |
| Purpose | Process validation | Proactive monitoring |
| Coverage | All processed items | Sampled items |
| Resource Planning | Reactive | Predictable |

### Business applications

This section describes the business benefits of various types of scheduled tests.

They're good for routine inventory sampling:

- Randomly test the items you have in stock.
- Verify that your storage conditions are suitable.
- Quality drift monitoring.

Do compliance testing:

- Be sure that you meet regulatory requirements.
- Comply with industry standards.
- Prepare for customer audits.

Apply preventive quality control:

- Detect quality issues early.
- Analyze and monitor trends.
- Continuously improve data collection.

## Set up scheduled tests

The following sections provide high-level steps to set up scheduled tests.

### Configure quality templates

Create templates specifically for scheduled testing. The following are a few suggestions for things to think about when you do:

- For efficiency, use as simple a set of measurements as you can.
- Focus on critical quality parameters.
- Streamline the settings for regular runs.

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Templates**, and choose the related link.
2. Create a template for scheduled tests.
3. Configure measurements that are appropriate for routine testing.
4. Set pass and fail criteria for ongoing monitoring.

### Create test generation rules and set up a job queue entry

Configure rules specifically for time-based test creation.

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Test Generation Rules**, and then choose the related link.
2. Create a new test generation rule for scheduled testing.
3. Choose the **Schedule Group** field. You're prompted to create a job queue, followed by an option to view it. The next session describes the job queue settings.

### Configure a job queue entry

The following settings are important for scheduled tests.

Enter the following settings that control when, and how often the job queue entry runs:

- **Earliest Start Date/Time**: Specify when to begin scheduled testing.
- **Run on <\day of the week>**: Schedule the job queue entry to run on a specific day.
- **Starting Time**: Specify the time of day to start.
- **Ending Time**: Specify the time of day to stop.

Enter the following settings that control**Execution Parameters**:

- **Maximum No. of Attempts**: Retry logic for failures
- **Rerun Delay**: Wait time between retry attempts
- **Status**: Use the **Set Status to Ready** action to update the status to **Ready** and enable the job queue entry.

## Troubleshooting scheduled tests

The following sections describe typical issues and suggest solutions.

### The job queue entry isn't running

- Verify that the job queue service is running.
- Double-check the status of the job queue entry.
- Verify that users have the permissions they need.

### No tests are created

- Verify the settings for your test generation rule.
- Double-check your item filters and availability.
- Review the codeunit parameters.

### Too many tests are created

- Adjust your sampling percentages.
- Refine your item filters.
- Review the selection logic.

## Best Practices

There are several things to think about when you determine your strategy for scheduling. Use a balanced approach, and combine scheduled and transaction-based testing. Focus your scheduled tests on high-risk areas, and maintain statistical validity.

Consider the capacity of your inspectors, and coordinate with operational schedules.

Regularly evaluate the effectiveness of your scheduled tests. Adjust frequencies and optimize resource allocation based on your findings.

Use the data from your tests to drive decisions about process improvements. Identify quality trends and patterns that support vendor quality discussions.

## Related information

[Manual Test Creation](qms-manual-test-creation.md)  
[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Quality Management Setup and Configuration](qms-setup.md)  
[Quality Management Overview](qms-overview.md)