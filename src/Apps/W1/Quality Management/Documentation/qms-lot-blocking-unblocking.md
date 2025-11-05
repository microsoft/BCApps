---
title: Lot blocking and unblocking
description: Learn how to block and unblock inventory lots using workflows and grade-specific controls to ensure quality compliance.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: how-to
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Lot blocking and unblocking

This article explains how to automatically block and unblock inventory lots based on quality inspection test results using workflows and grade-specific controls. There are two main approaches for lot blocking:

- **Workflow-Based Blocking**: Block lots using workflows.
- **Grade-Based Blocking**: Document-specific blocking based on test grades

Both approaches help ensure that noncompliant inventory isn't used inappropriately, while allowing flexible quality control processes.

## Prerequisites

- Enable **Workflow integration** in **Quality Inspection Setup**.
- Configure **Quality Templates** with pass/fail criteria.
- Set up **Test Generation Rules** for automatic test creation.
- Configure **Items** with lot tracking.

## Workflow-based lot blocking

Workflow-based blocking creates or modifies **Lot Number Information Cards** to completely block lots for all transactions (except warehouse operations when configured).

### Set up a block-on-fail workflow

The following procedure describes the key settings for a workflow that blocks lots when quality tests fail.

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Workflow**, and then choose the related link.
1. Create a new workflow. For example, name it "Block Lot Example."
1. Configure the **When Event**, as follows:

   - **Event**: When a **Quality Inspection Test is Finished**
   - **Condition**: Grade Code equals **"Fail"**

1. Configure the **Response** as **Block the lot in the test**. This setting creates a lot information card with the status **Blocked**.

### Set up block-on-creation, and unblock on pass workflows

The following procedures describe the key settings for workflows that block lots immediately when tests are created, and unblock them when tests pass.

#### Block on test creation

1. Create a new workflow. For example, name it "Block Lot on Creation."
1. Set the **When Event** as **Quality Inspection Test is Created**.
1. Set the **Response** as **Block the lot in the test**.

   The result is that all lots are blocked immediately when tests are created.

#### Unblock on pass

1. Create a new workflow. For example, name it "Unblock on Pass."  
2. Set the **When Event** as **Quality Inspection Test is Finished**.
3. Set the **Condition** as **Grade Code equals Pass**.
4. Set the **Response** as **Unblock the lot in the test**.
5. Set the **Result** as **Lots unblocked only when tests pass**.

### Enable workflow integration

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Setup**, and then choose the related link.
2. Turn on the **Enable Workflow Integration** toggle.

> [!NOTE]
> If you don't turn on the **Enable Workflow Integration** toggle, the quality management events for workflows aren't available.

## Grade-based document blocking

Grade-based blocking provides granular, document-specific controls based on the current grade of quality inspection tests. Unlike complete lot blocking, this approach lets you block specific transaction types while permitting others, based on the test grade.

The following list describes how [!INCLUDE [prod_short](includes/prod_short.md)] evaluates grades:

- The system evaluates current test grades for the lot/serial number.
- The grade configuration determines transaction permissions.
- Multiple tests for the same lot might have different grades.
- The system can consider specific tests when it evaluates restrictions.

### Configuring grade transaction controls

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Grades**, and then choose the related link.
2. Select the grade to configure. For example, INPROGRESS, FAIL, or PASS.
3. Configure transaction permissions for each grade:

   - **Allow Sales**: Enable or disable sales document posting.
   - **Allow Purchase**: Enable or disable purchase document posting.
   - **Allow Transfer**: Enable or disable transfer order posting.
   - **Allow Consumption**: Enable or disable material consumption in production.
   - **Allow Pick**: Enable or disable warehouse picks.
   - **Allow Put-away**: Enable or disable warehouse put-aways.
   - **Allow Movement**: Enable or disable warehouse movements.
   - **Allow Output**: Enable or disable production output posting.

### Examples of grade configurations

#### INPROGRESS grade (priority 0)

Use this grade configuration to restrict most transactions when testing is in progress. The business logic is that you can store and move items for testing, but not use them in business transactions.

- **Allow Sales**: No (can't sell unconfirmed quality)
- **Allow Transfer**: No (prevent distribution before testing is complete)
- **Allow Consumption**: No (can't use in production)
- **Allow Pick**: No (prevent picking for shipments)
- **Allow Put-away**: Yes (allow warehouse storage)
- **Allow Movement**: Yes (allow movement to testing areas)
- **Allow Output**: Yes (might be acceptable for work-in-progress)

#### FAIL grade (priority 1+)

Use this grade configuration to require quarantine with a quality test fails. The business logic is to block all use and allow only quarantine and disposal activities.

- **Allow Sales**: No (can't sell nonconforming items)
- **Allow Transfer**: No (prevent distribution of failed items)
- **Allow Consumption**: No (can't use defective materials)
- **Allow Pick**: No (prevent accidental picking)
- **Allow Put-away**: Yes (allow quarantine storage)
- **Allow Movement**: Yes (allow movement for disposal)
- **Allow Output**: No (prevent use in production)

#### PASS grade (highest priority)

Use this grade configuration to allow normal business operations when a quality test passes. The business logic is to allow transactions for items with confirmed quality.

- **Allow Sales**: Yes (approved for customer shipment)
- **Allow Transfer**: Yes (approved for distribution)
- **Allow Consumption**: Yes (approved for production use)
- **Allow Pick**: Yes (approved for warehouse operations)
- **Allow Put-away**: Yes (normal warehouse operations)
- **Allow Movement**: Yes (normal warehouse operations)
- **Allow Output**: Yes (approved for production output)

#### Example of a CONDITIONAL (medium priority) custom grade

Use this grade configuration when a grade is conditionally acceptable with restrictions. The business logic is to allow limited use, and perhaps require management approval.

- **Allow Sales**: No (requires customer approval)
- **Allow Transfer**: Yes (can transfer with documentation)
- **Allow Consumption**: Yes (acceptable for noncritical applications)
- **Allow Pick**: Yes (with proper documentation)
- **Allow Put-away**: Yes (normal storage)
- **Allow Movement**: Yes (normal handling)
- **Allow Output**: No (not suitable for finished goods)

## Implement lot blocking scenarios

This section describes some typical scenarios for lot blocking.

### Block on failure only

**Business Rule**: Lots remain available until tests fail.

**Implementation**:

1. **Workflow**: Block lot when test finishes with "FAIL" grade.
2. **Grade Setup**: The **INPROGRESS** grade allows all transactions.

The following process is a sample flow for this implementation:

1. You receive the item and put it away normally.
2. You create and run a quality test.  
3. The lot remains available for all operations.
4. If the test fails, the lot becomes blocked. If it passes, no blocking happens.

### Block during testing

**Business Rule**: Block lots immediately when testing begins.

**Implementation**:

1. **Workflow 1**: Block lot when test is created.
2. **Workflow 2**: Unblock lot when test passes with "PASS" grade.
3. **Grade Setup**: Configure document-specific controls if needed.

The following process is a sample flow for this implementation:

1. You receive the item.
2. You create and run quality test, and the lot is immediately blocked.
3. Put-away might still be allowed (warehouse operations).
4. If the test fails, the lot remains blocked. If it passes, normal operations resume.

### Document-specific controls

**Business Rule**: Prevent sales, but allow warehouse operations during testing.

**Implementation**:

1. **No Workflows**: Rely entirely on grade controls.
2. **In Progress Grade**:
   - Allow Put-away: Yes
   - Allow Movement: Yes
   - Allow Pick: No
   - Allow Sales: No

The following is a sample process flow for this implementation:

1. You receive the item and create a test.
2. Put-away proceeds normally (allowed).
3. Sales orders can't be posted (blocked).
4. Warehouse movements are allowed for the quality area.
5. Test completion changes the grade, updating permissions.

## Work with blocked lots

The following sections describe some actions you can take while a lot is blocked.

### Identify blocked lots

It't easy to find out whether a lot is blocked. Open the **Lot No. Information List** page, and check the **Blocked** field. You can also use quality test references.

For **Quality Test Integration**, tests show related lot blocking status. You can go from tests to lot information and review blocking history.

### Manage blocked inventory

You can do the following for warehouse operations:

- Blocked lots might still allow warehouse movements.
- Use for quarantine and disposal processes.
- Configure grade controls for specific needs.

For disposal, you can take the following actions:

- Move to quarantine areas.
- Process through rework procedures.
- Create negative adjustments for disposal.
- Return to vendors if appropriate.

## Test lot blocking configuration

### Test Scenario: Purchase receipt with blocking

1. **Create a purchase order**:
   - Item with lot tracking.
   - Location with appropriate setup.
   - Post warehouse receipt.

2. **Verify test creation**:
   - Quality test is created automatically.
   - Check the lot blocking status (depends on configuration).

3. **Test a sales transaction**:
   - Create a sales order for the same lot.
   - Try to post a shipment.
   - Verify the blocking behavior.

4. **Complete a quality test**:
   - Enter the measurement values.
   - Finish the test with a pass or fail result.
   - Verify that the lot status changes appropriately.

### Validation points

**Automatic Blocking**:

- Tests create and lots block as configured.
- Blocking prevents inappropriate transactions.
- Warehouse operations follow grade settings.

**Test Completion**:

- Passing tests unblock lots (if configured).
- Failing tests maintain or create blocking.
- Grade changes update transaction permissions.

## Troubleshoot lot blocking

This section lists some typical issues and describes how to get unblocked.

### My workflow doesn't start

- The **Workflow Integration** toggle isn't enabled on the **Quality Inspection Setup** page. Turn on the toggle.
- The workflow isn't active. Activate the workflow.
- There's an incorrect event or condition in your workflow configuration. Review the settings in your workflow.

### I get unexpected blocking behavior

There might be a problem with your grade control:

- Review your grade configuration for transaction types.
- Check your test grade assignments.
- Verify your grade inheritance rules.

There might be conflicts with your workflow:

- Check whether multiple workflows conflict.
- Review workflow priorities.
- Consider disabling conflicting workflows.

### My lots aren't becoming unblocked

There might be issues with you pass condition:

- Verify that the test resulted in a passing grade.
- Check your workflow conditions for unblocking.
- Review your grade transition rules.

You might need to manually intervene:

- Manually unblock lots on the **Lot No. Information Card** page.
- Review and correct your workflow configuration.
- Consider using grade-based controls instead.

## Related information

[Purchase Receipt Testing Without Warehouse Tracking](qms-purchase-receipt-testing-simple.md)  
[Purchase Receipt Testing With Warehouse Tracking](qms-purchase-receipt-testing-warehouse.md)  
[Configuring Workflows](qms-quality-workflows.md)  
[Processing Non-Compliant Items](qms-non-compliant-processing.md)  
[Quality Management Overview](qms-overview.md)