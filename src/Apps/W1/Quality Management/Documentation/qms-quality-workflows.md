---
title: Quality management workflows
description: Learn how to automate quality management processes using workflows.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: concept-article
ms.search.form: 
ms.date: 11/10/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Quality management workflows

This article explains how to set up and use workflows to automate quality management processes.

Quality Management integrates with workflows in [!INCLUDE [prod_short](includes/prod_short.md)] to automate responses to quality inspection events. Workflows can automatically run business actions when quality tests are created, finished, or when specific conditions are met. For example, quality management workflows can:

- Block and unblock lots.
- Move inventory
- Create negative adjustments

## Prerequisites

- Workflow integration is enabled on the **Quality Management Setup** page.
- The workflows feature is enabled.
- You have permissions required to configure workflows.
- You configured the required journal batches and templates.

## Enable workflow integration

Before creating quality management workflows, ensure that workflow integration is enabled:

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Management Setup**, and then choose the related link.
2. On the **Defaults** FastTab, turn on the **Workflow Integration Enabled** toggle.

   > [!TIP]
   > By default, the toggle is hidden. To access it, you might have to choose **Show more**.

3. Configure the required journal batches for automated processes.

> [!IMPORTANT]
> If you don't enable workflow integration, quality inspection events aren't available when you configure your quality management workflows.

## Typical quality workflow events

The following sections describe often-used workflow events and conditions.

### When events

**When a Quality Inspection Test is Created**:

- This event triggers automatically when test generation rules create new tests.
- Use the event for immediate actions, such as blocking lots when you create tests for them.
- The event is available for all test creation methods. For example, purchase receipts, production output, and manual creation.

**When a Quality Inspection Test is Finished**:

- This event triggers when tests are completed and finalized.
- Use the event for disposal actions based on test results.
- This event is the most popular for quality workflows.

### Workflow conditions

**Grade code conditions**:

- Grade code equals "PASS" for successful test completion.
- Grade code equals "FAIL" for failed test processing.
- Grade code equals "INPROGRESS" for tests in progress.
- Custom grade codes you configure.

**Additional conditions**:

- Location codes for site-specific workflows.
- Item numbers for product-specific processing.
- Test template codes for template-specific responses.

## Workflow response actions

The following sections describe the responses, or actions, that happen after an event.

### Lot, serial, and package number blocking actions

**Block the Lot (Serial, Package) in the Test**:

- Creates a **Lot No. Information Card** page with the status **Blocked**. The status prevents all transactions for the lot until you manually unblock it.
- The standard lot blocking functionality in [!INCLUDE [prod_short](includes/prod_short.md)] applies. To learn more, go to [Block items or item variants from use in sales, purchasing, service, and production](inventory-how-block-items.md).

**Unblock the Lot (Serial, Package) in the Test**:

- Removes lot blocking from previously blocked lots, and restores normal transaction abilities.
- This action is typically used with passing test results.

### Inventory movement actions

**Move Inventory to Different Bin**:

- Automatically relocates inventory based on test results.
- Uses movement worksheets, movement documents, or reclassification journals.
- Supports directed put-away and pick locations.

**Create Transfer Order**:

- Moves inventory between locations.
- Useful for quarantine or rework locations.
- You can configure the action for automatic or manual posting.

### Inventory adjustment actions

**Create Negative Adjustment**:

- Removes inventory for disposal or destructive testing.
- Uses item journals or warehouse item journals.
- Supports reason codes for audit trails.
- Can process full lots, specific quantities, or failed quantities only.

### Test creation actions

**Create Retest**:

- Automatically generates follow-up tests.
- Useful for corrective action processes.
- Can use the same or different test templates.

**Create Internal Put-away**:

- Generates a warehouse put-away for inventory staging.
- Supports quality inspection workflows in warehouse environments.

## Examples of workflow configuration

The following sections provide examples of how to configure different workflows.

### Block a lot when a test fails

This sample configuration automatically quarantines lots that fail a test.

1. **Workflow Name**: **Block Lot on Failure**
2. **When Event**: **When a Quality Inspection Test is Finished**
3. **Condition**: Grade equals **Fail**.
4. **Response**: Block the lot in the test.

The following are the outcomes of this example:

- Failed lots are immediately blocked from all transactions.
- Creates a **Lot No. Information Card** page for tracking.
- Prevents the accidental use of nonconforming materials.

### Preemptive lot blocking

These sample configurations block lots during testing, and unblock them when they pass.

**Blocking workflow**:

1. **Workflow Name**: **Block Lot on Test Creation**
2. **When Event**: **When a Quality Inspection Test is Created**
3. **Condition**: None (applies to all tests)
4. **Response**: Block the lot in the test.

**Unblocking workflow**:

1. **Workflow Name**: **Unblock Lot on Pass**
2. **When Event**: **When a Quality Inspection Test is Finished**
3. **Condition**: **Grade Code** equals **"Pass"**
4. **Response**: Unblock the lot in the test.

The following are the outcomes of this example:

- Lots are quarantined immediately when you create a test.
- Only passing tests unblock lots for normal use.
- Prevents the use of untested materials.

### Automatic movement between bins

This sample configuration moves failed items to the quarantine bin.

1. **Workflow Name**: **Move Failed Items to Quarantine**
2. **When Event**: **When a Quality Inspection Test is Finished**
3. **Condition**: **Grade Code** equals **"Fail"**
4. **Response**: Move inventory to a different bin.
5. **Details**:
   - **Method**: Reclassification Journal
   - **Quantity**: Entire Lot
   - **Destination**: Quarantine bin
   - **Post Immediately**: No (requires manual review)

The following are outcomes of this example:

- Failed items are automatically staged for quarantine.
- Physical separation of conforming and nonconforming items.
- Maintain an audit trail of disposals.

### Negative adjustment for disposal

This sample configuration automatically disposes of failed or destructively tested items.

1. **Workflow Name**: **Dispose Failed Items**
2. **When Event**: **When a Quality Inspection Test is Finished**
3. **Condition**: **Grade Code** equals **"Fail"**
4. **Response**: Create a negative adjustment.
5. **Details**:
   - **Quantity**: Failed quantity (or entire lot)
   - **Reason Code**: **Quality Assurance**
   - **Post Immediately**: No (review required)

The following are outcomes of this example:

- An automatic inventory reduction for the unrecoverable items.
- Accurate cost accounting for quality losses.
- An audit trail for the disposed materials.

## Advanced workflow scenarios

The following sections describe examples of advanced scenarios in which quality management workflows are useful.

### Conditional, grade-based processing

You can use multiple failure types:

- Create separate workflows for different failure grades.
- Use different responses based on the severity of the failure.
- Implement escalation procedures for critical failures.

You can use location-specific processing:

- Create different workflows for different locations.
- Implement location-specific quarantine procedures.
- Meet country/regional compliance requirements.

### Integration with other features

You can integrate your quality management workflows with purchase returns:

- Automatically create purchase returns for vendor defects.
- Link to vendor quality performance tracking.
- Streamline vendor corrective action processes.

You can integrate your quality management workflows with production processes:

- Automatically create rework orders for repairable items.
- Control the quality of production output.
- Enable work center quality tracking.

### Requirements for batches

Workflows require that you configure journal batches on the **Quality Management Setup** page:

- Use the **Item Journal Batch** for nonwarehouse location adjustments.
- Use the **Warehouse Item Journal Batch** for warehouse location adjustments.
- Use the **Warehouse Movement Worksheet** for directed put-away/pick movements.
- Use the **Warehouse Reclass Journal Batch** for warehouse reclassifications.
- Use the **Item Reclass Journal Batch** for nonwarehouse reclassifications.

## Test your workflow configuration

The following are high-level steps to validate your workflow configuration>

1. Create a test scenario:
   - Generate a quality test through a normal business process.
   - Verify that the workflow events trigger correctly.
   - Confirm that the conditions evaluate correctly.
2. Check the response actions:
   - Verify that the intended actions happen.
   - Review the journal entries that you created.
   - Confirm the blocking and unblocking behavior.
3. Business process integration:
   - Test with actual business transactions.
   - Verify that documents post correctly.
   - Confirm that the user experience meets your expectations.

## Best practices

Be diligent when you design your workflow. Start simple, with basic scenarios and gradually add complexity. Be sure to thoroughly test your workflows in a development environment before you use them in production. Document your process and keep clear records of your workflow business rules. Also, keep an eye on performance. Regularly review your workflow runs, and maintain override capabilities for exceptions.

Monitor the business effects of your workflows, and set up audit trails and approval processes. Help your users engage by ensuring that they understand the automated process, and incorporate their suggestions for process improvements.

## Troubleshooting

The following sections describe typical issues and suggest solutions.

### The workflow doesn't trigger

- Double-check that you enabled workflow integration.
- Verify that your workflow is active.
- Review the event conditions.
- Confirm that users have the correct permissions.

### Incorrect actions are running

- Review your workflow conditions and logic.
- Check whether multiple workflows are conflicting.
- Verify your grade code configuration.
- Review the order in which your workflow steps run.

### There are issues with performance

- Monitor how often your workflow runs.
- Review your settings for the related batch.
- Consider the timing of the automated actions.
- Evaluate the effect on your system resources.

### Workflow events for quality management aren't available

- Double-check that you enabled workflow integration on **Quality Management Setup** page.
- Verify that your workflows are active.
- Confirm that your users have the correct permissions

## Actions aren't running

- Review your workflow conditions.
- Review your settings for the journal batch.
- Verify that the values match your grade code.

### I'm getting unexpected blocking behavior

- If you have multiple workflows, review their interactions.
- Check your grade-based transaction controls.
- Verify your workflow priorities and sequence.

## Related information

[Lot Blocking and Unblocking](qms-lot-blocking-unblocking.md)  
[Processing Non-Compliant Items](qms-non-compliant-processing.md)  
[Configuring Grades](qms-configuring-grades.md)  
[Quality Management Setup](qms-setup.md)  
[Quality Management Overview](qms-overview.md)