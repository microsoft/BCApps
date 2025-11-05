---
title: Handle items that failed a quality test
description: Learn how to handle noncompliant items, including workflows, inventory movements, and actions for failed quality tests.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Process items that failed a quality test

This article explains how to deal with items that don't pass quality inspection tests. It covers:

- Automatic workflows.
- Manual actions for blocking items and moving inventory.
- Deciding what to do with the items that failed a test.

When quality inspection tests fail, you have several automatic and manual options for handling noncompliant items:

- Block items to prevent the use of failed lots.
- Move items to quarantine areas.
- Remove unusable inventory from of the system.
- Transfer items to different locations.
- Send defective items back to your suppliers.

## Prerequisites

- Quality inspection templates with pass and fail criteria.
- Generation rules.
- Quality management workflows to automatically process failures and passes.
- Locations and bins for quarantine.

## Automatic processing when items fail a test

### Workflow-based actions

Quality Management workflows can automatically respond to test failures. The following automatic responses are available:

- Block the lot in the test
- Create negative adjustment
- Create transfer order
- Move inventory to different bin
- Create purchase return
- Create retest
- Send notifications

### Set up automatic blocking when tests fail

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Workflows**, and then choose the related link.
1. Create a new workflow. For example, name it "Block Lot on Failure."
1. In the **Category** field, choose **Quality Examples**.
1. Configure the **When Event** as follows:
   - **Event**: When a Quality Inspection Test is Finished
   - **Condition**: Grade Code equals "FAIL" (or other failing grades)
1. Configure the **Response** as follows:
   - **Response**: Block the lot in the test
   - **Result**: Failed lots automatically get blocked from use
4. Specify grade-specific conditions, as follows:
   - Create separate workflows for different failing grades.
   - Use grade priorities to determine appropriate responses.
   - Configure different actions based on failure severity.

### Set up automatic inventory movement

1. Create a workflow. For example, name it "Move Failed Items to Quarantine."
2. For the **When Event**, choose **Quality Inspection Test is Finished**.
3. For the **Condition**, specify that Grade Code equals "FAIL."  
4. For the **Response**, choose **Move inventory to different bin**
5. For the **Configuration**, specify a quarantine bin code.

## Manual processing when tests fail

The following sections describe ways to manually process items when they fail a test.

### Immediate actions after a test failure

When a quality test fails, consider these immediate actions:

1. **Quarantine**: Physically separate the noncompliant items.
2. **Investigation**: Determine the root cause of the failure.
3. **Documentation**: Record details about the failure and the actions taken.
4. **Notification**: Inform the relevant stakeholders.

### Decide what to do with the failed items

This section describes some typical ways to handle items that failed a test.

Use the failed items as-is:

- The customer accepts with a concession.
- Offer a reduced price or a different application.
- Document that the deviation is approved.

Rework the failed items:

- Correct or repair the failed items.
- Retest the items after you complete the rework.
- Track the costs and time spent on the rework.

Return the defective items to the vendor:

- Record a vendor defect or specification issue.
- Use the purchase return process and report the results from the quality inspection test.
- Document the vendor quality issues.

Treat the items as scrap or disposal:

- Use this method when you can't rework the items. For example, when rework isn't economically feasible.
- Create negative adjustments using reports from the quality inspection test.
- Consider environmental disposal implications.
- Record the costs and reasons for the disposal.

### Use quality inspection test reports for manual actions

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Test**, and then choose the related link.
1. Open the failed test.
1. Use the **Actions** menu to access helpful reports and actions.
1. Run the actions directly from test results for proper record keeping

The following actions are available from the **Actions** menu on the **Quality Inspection Test** page:

- **Create Negative Adjustment** - Automatically fills in item, lot, and quantity information
- **Move Inventory**:
   - Run an inventory movement directly from test results. The movement is prefilled with details about the failed lot, and maintains the connection between movement and quality failure.
   - Specify the destination bin, such as quarantine, rework, or disposal.
- **Create Transfer Order**:
   - Generate a transfer orders that automatically includes failed lot information and links transfer to original quality test for tracking
   - Specify a destination location for further processing.
- **Create Purchase Return**:
   - Start vendor returns directly from test results. The return contains purchase order and receipt details, and includes quality test failure information for vendor communication.

The following are benefits of using test-based actions:

- Automatically get item, lot, and quantity details.
- Built-in tracking between actions and test failures.
- Reduced data entry errors.
- Consistent documentation and audit trail.
- Integration with quality workflow processes.

### Step-by-step process using quality inspection test actions

**Process Using Quality Inspection Test Actions**:

1. **Review Test Results**:
   - Go to the failed quality inspection test.
   - Analyze the failure details and measurements.
   - Determine the appropriate action.

2. **Execute Action**:
   - Select the appropriate action from the **Actions** menu on the **Quality Inspection Test** page.
   - Review the prefilled information for accuracy.
   - Add more details as required. For example, a destination or reason code.
   - Run the action to create the necessary documents.

3. **Complete Processing**:
   - Process the created documents. For example, adjustments, transfers, or returns.
   - Update the physical inventory locations as needed.
   - Document the resolution and lessons learned.

4. **Verify Completion**:
   - Confirm that all actions are properly recorded.
   - Verify that inventory movements and adjustments are posted.
   - Update the test status if necessary for tracking

## Grade-based controls for failed items

Quality Management uses grade-based controls to automatically manage noncompliant items based on test results.

**Grade-Based Business Rules**:

- Grade priorities determine which controls take precedence.
- Higher priority grades override lower priority grades.
- Failed grades typically restrict business transactions while allowing handling activities.
- Grade conditions can automatically promote or demote based on business rules.

**Implementation**:

- Test templates assign grades based on measurement results.
- Grade inheritance flows from Default → Field → Template → Test levels.
- Workflows can trigger more actions based on grade assignment.
- Transaction controls apply immediately when you assign a grade.

## Moving items after test failures

The following sections describe how to set up a quality management workflow to automatically or manually move a defective inventory to quarantine.

### Automatic movement to quarantine

You can set up a quality management workflow that automatically moves items to your quarantine area if they fail a test. The movement physically separates the defective items from your good inventory.

Set up a quality management workflow, as follows:

1. **Response**: Move inventory to different bin
2. **Bin Configuration**: Specify quarantine bin
3. **Automatic Execution**: Movement occurs on test failure

### Manual movement process

To manually move defective inventory, you can use quality management reports from the **Actions** menu on the **Quality Inspection Test** page. This section describes the reports.

**Move Inventory Report**:

This report moves inventory between bins or locations for quarantine or handling.

- **Quantity Options**: Entire lot/serial/package, specific quantity, sample quantity, passed/failed quantity.
- **Movement Methods**: Reclassification journal or movement worksheet/internal movement.
- **Source Filters**: Optional location and bin filters to limit movement source.
- **Destination**: Specify a target location and bin for quarantine or disposal.
- **Posting Options**: Post immediately, or create entries for later processing.

**Create Internal Put-away Report**:

This report creates internal put-away documents for warehouse locations.

- **Quantity Options**: Entire lot/serial/package, specific quantity, sample quantity, passed/failed quantity.
- **Source Filters**: Optional location and bin filters.
- **Release Options**: Release immediately, create warehouse put-away, or keep open for review.
- **Usage**: Ideal for directed put-away and pick locations.

**Manual Movement Process**:

1. **Select Failed Test**: Go to the quality inspection test with failed results.
2. **Choose Movement Report**: Select **Move Inventory** or **Create Internal Put-away** from the **Actions** menu.
3. **Configure Movement**: Specify a destination. For example, your quarantine, rework, or disposal areas.
4. **Execute**: Run the report to create movement documents with proper tracking.

## Removing items from inventory

You can remove items from inventory automatically, or manually. The following sections describe how.

### Automatic removal

Set up a quality management workflow with the **Then Response** set to **Create negative adjustment**. This response does the following:

- Automatically removes failed inventory.
- Records the disposal in the item ledger.
- Updates inventory quantities.

The following are a few things to consider about your configuration:

- Ensure that you have a suitable posting setup.
- Consider the effect on cost.
- Maintain an audit trail.

### Manual removal process

The manual removal process involves using the **Create Negative Adjustment** report from the **Actions** menu on the **Quality Inspection Test** page.

The report decreases inventory quantity for disposal, destructive testing, or write-offs.

- **Quantity Options**:
  - Entire lot/serial/package quantity
  - Specific quantity with manual entry
  - Sample quantity (uses test sample size)
  - Passed quantity (samples that passed all measurements)
  - Failed quantity (samples with at least one failed measurement)
- **Source Filters**: Optional location and bin filters to limit adjustment source
- **Reason Codes**: Optional reason code for audit trail
- **Posting Behavior**: Create journal entries only or post immediately

The following steps give an overview of the manual removal process:

1. From the failed quality inspection test, choose **Create Negative Adjustment** from the **Actions** menu.
2. **Select Quantity**: Choose the appropriate quantity method. For example, this selection is often **Failed Quantity** for noncompliant items.
3. **Add Reason**: Specify a reason code. For example, disposal, destructive testing, damage, and so on.
4. **Configure Source**: Add location/bin filters if you need to limit the scope.
5. **Execute**: Create entries for review, or post immediately.
6. **Verify**: Confirm the inventory reduction and that cost accounting is correct.

## Return items to vendors

You can return items to vendors automatically, or manually. The following sections describe how.

### Automatic return processing

Set up a quality management workflow with the **Then Response** set to **Create purchase return**. This response does the following:

- **Automatic Execution**: Return order created on test failure
- **Vendor Notification**: Include details about the quality failure.

### Manual return process

The manual return process involves using the **Create Purchase Return** report from the **Actions** menu on the **Quality Inspection Test** page.

The report creates purchase return orders for vendor-related defects.

- **Quantity Options**:
  - Entire lot/serial/package quantity
  - Specific quantity with manual entry
  - Sample quantity (uses test sample size)
  - Passed quantity (if partial return needed)
  - Failed quantity (most common for defects)
- **Return Reason**: Optional return reason code for vendor communication
- **Source Filters**: Optional location and bin filters
- **Credit Memo**: Optional vendor credit memo number field

The following steps give an overview of the manual return process:

1. **Document the failure**: Compile the test results and evidence from the quality inspection test.
2. Access the report by choosing **Create Purchase Return** from the **Actions** menu on the **Quality Inspection Test** page.
3. **Configure the return**:
   - Choose **Failed Quantity** for defective items
   - Add a return reason code.
   - Include the vendor credit memo number, if it's available.
4. **Run the report**: Create a purchase return order with prefilled test information.
5. **Process the return**: Follow your standard return procedures with links to the quality documentation.
6. **Vendor communication**: Include quality test failure details in a return notification.

## Transfer items to other locations

This section describes how to manually transfer items to other locations.

### Manual transfer process

The manual transfer process involves using the **Create Transfer Order** report from the **Actions** menu on the **Quality Inspection Test** page:

The report transfers items to another location for external processing, lab analysis, or disposal.

- **Quantity Options**:
  - Entire lot/serial/package quantity
  - Specific quantity with manual entry
  - Sample quantity (uses test sample size)
  - Passed quantity (for approved items)
  - Failed quantity (for noncompliant items)
- **Source Filters**: Optional location and bin filters to limit transfer source
- **Destination**: Target location for transfer
- **Transfer Details**: Support for direct transfer or in-transit locations

The following steps give an overview of the manual transfer process:

1. **Access the report**: From the quality inspection test, choose **Create Transfer Order** from the **Actions** menu on the **Quality Inspection Test** page.
2. **Select the quantity**: Choose the appropriate quantity method based on what you want to do.
3. **Configure the source**: Add location/bin filters if the test covers multiple locations.
4. **Set a destination**: Specify the target location. For example, an external lab, disposal facility, or rework center.
5. **Transfer options**: Choose a direct transfer, or specify in-transit location.
6. **Execute**: Create a transfer order with quality test tracking.

## Change item information

This section describes how to manually update information about items. Updating item information involves using the **Change Item Tracking** report from the **Actions** menu on the **Quality Inspection Test** page.

The report updates item tracking information such as lot numbers, serial numbers, package numbers, or expiration dates.

- **Quantity Options**:
  - Entire lot/serial/package quantity
  - Specific quantity with manual entry
  - Sample quantity (uses test sample size)
  - Passed quantity (for approved samples)
  - Failed quantity (for noncompliant samples)
- **Tracking Changes**: Update the lot, serial, or package numbers, and the expiration date.
- **Source Filters**: Optional filters for locations and bins.
- **Posting Options**: Post immediately, or create journal entries for review.

The following steps give an overview of how to manually track items:

1. **Access the report**: Run the **Change Item Tracking** report from the **Actions** menu on the **Quality Inspection Test** page.
2. **Select a quantity**: Choose the appropriate quantity method for tracking updates.
3. **Specify your changes**: Enter a new lot, serial, or package number, or a new expiration date.
4. **Configure the source**: Add filters for locations or bins, if needed.
5. **Execute**: Create a reclassification journal with updated tracking information.
6. **Post the changes**: Process the journal to update the item tracking records.

## Corrective Action Integration

### Root Cause Analysis

**Quality Failure Investigation**:

- Review test data and trends
- Identify process or supplier issues
- Document findings and recommendations

**Process Improvement**:

- Update specifications or procedures
- Enhance incoming inspection criteria
- Improve vendor quality agreements

### Preventive Actions

**Enhanced Testing**:

- Create more test generation rules
- Implement more comprehensive templates
- Increase sampling frequencies

**Supplier Development**:

- Work with vendors on quality improvement
- Provide feedback on failure patterns
- Establish quality agreements and scorecards

## Retesting Procedures

### Automatic Retest Creation

**Workflow Response**: Create retest
- New quality test generated after rework
- Same template and criteria applied
- Links to original failed test

### Manual Retest Process

**After Rework or Investigation**:

1. **Complete Corrective Action**: Address root cause
2. **Create New Test**: Use manual test creation
3. **Reference Original Test**: Maintain tracking
4. **Document Resolution**: Record corrective actions taken

## Example: Complete Process for Failed Items

### Scenario: Failed Purchase Receipt Test

1. **Test Failure**:
   - Purchase receipt quality test fails measurement criteria
   - Grade automatically set to "FAIL"

2. **Automatic Workflow Actions**:
   - Lot automatically blocked (prevents further use)
   - Inventory moved to quarantine bin
   - Notification sent to quality manager

3. **Investigation**:
   - Quality team reviews failure details
   - Root cause identified as vendor process issue
   - Decision made to return to vendor

4. **Action Taken**:
   - Purchase return order created
   - Vendor notified of quality issue
   - Items returned and credit processed

5. **Follow-up**:
   - Vendor corrective action requested
   - Enhanced inspection implemented temporarily
   - Process documented for future reference

## Monitoring and Reporting

### Quality Metrics

**Track Failure Rates**:

- Test failure percentages by vendor
- Failure trends by item or category
- Cost of quality issues

**Action Tracking**:

- Time to resolution
- Action method effectiveness
- Recurring quality issues

### Continuous Improvement

**Process Enhancement**:

- Regular review of failure patterns
- Update templates and criteria as needed
- Improve workflow automation

**Vendor Management**:

- Quality scorecards based on test results
- Vendor development programs
- Supplier quality agreements

## Related information

[Lot Blocking and Unblocking](qms-lot-blocking-unblocking.md)  
[Configuring Workflows](qms-quality-workflows.md)  
[Purchase Receipt Testing Without Warehouse Tracking](qms-purchase-receipt-testing-simple.md)  
[Quality Management Overview](qms-overview.md)