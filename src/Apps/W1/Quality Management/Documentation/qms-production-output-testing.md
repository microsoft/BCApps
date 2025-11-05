---
title: Production output quality testing
description: Learn how to set up and use automatic quality inspection tests for production output.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: how-to
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Production output quality testing

This article explains how to set up and use automatic quality inspection test creation for production output when you post manufacturing operations.

Production output testing creates quality inspection tests automatically when production output is posted. This enables quality control for:

- Finished goods inspection
- In-process quality gates
- Work center-specific testing
- Routing operation validation

## Prerequisites

- At least one quality inspection template is configured
- Production orders have routing operations
- Items are assigned item tracking codes (optional, but recommended)
- Production trigger is configured on the **Quality Inspection Setup** page

## Set up requirements

### Configure production items

Prepare items for production output testing:

**Item Setup**:

   - Configure **Item Tracking Code** (for example, "LOT ALL")
   - Set **Lot Nos.** series for automatic lot assignment
   - Ensure item has routing assigned

### Configure a production trigger

Set up a global trigger for production output, as follows:

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Setup**, and then choose the related link.
2. In the **Production Trigger** field, choose **When Output is Posted**. This option creates tests automatically.

### Create test generation rules

There are a few ways to set up rules for production output testing.

#### Method 1: Create a production rule (recommended)

1. On the **Quality Inspection Templates** or **Test Generation Rules** pages, choose **Create Production Rule**.
3. Fill in the following fields:
   - **Template Code**: Select a quality template
   - **Source Type**: Production Order Routing Line
   - **Production Trigger**: **"When Output is Posted"**

#### Method 2: Manual rule creation

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Test Generation Rules**, and then choose the related link.
2. Create new rule with the following settings:
   - **Source Type**: Production Order Routing Line
   - **Template Code**: Assign a template
   - **Production Trigger**: **"When Output is Posted"**
   - **Filters**: Configure as needed

### 4. Configure rule filters (optional)

Add filters to control when tests are created. The following list shows filters that are often used:

- **Location Code**: Specific production locations
- **Routing No.**: Specific routing operations
- **Work Center No.**: Specific work centers
- **Item No.**: Specific production items

**Example Filter**:

- **Location Code**: WHITE (for White location only)
- Leave other filters blank for broader application

## Create production output tests

### Step 1: Create a production order

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Production Orders**, and then choose the related link.
2. Create a new production order, and fill in the fields as follows:
   - **Item**: Use a lot-tracked production item.
   - **Quantity**: Specify a production quantity.
   - **Location**: Match the test generation rule filters.
   - **Routing**: Verify that routing operations exist.

> [!TIP]
> It's a good idea to review your production order setup.
>
> 1. Check that operations are set up for the routing.
> 2. Confirm that the correct location code is set.
> 3. Review the expected output operations.

### Step 2: Post production output

You can post production output by using a production journal or an output journal.

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Production Journal** or **Output Journal**, and then choose the related link.
2. Enter the output posting, as follows:
   - **Item No.**: Production item
   - **Output Quantity**: Quantity being output
   - **Operation No.**: Final routing operation
3. Configure **Item Tracking**. For example, assign a lot number.
4. Choose **Post** to post the journal or the production output for specific operations.

   After you post production output, a quality inspection test is created automatically. The test includes:

     - **Item Number**: The production item.
     - **Lot Number**: The assigned lot number for item tracking.
     - **Quantity**: The output quantity.
     - **Source**: The production order and operation reference.

## Work with production tests

Production output tests contain:

- **Control Information**: Source production order details
- **Item Tracking**: Lot/serial number information
- **Template Fields**: Quality measurements to complete
- **Quantity**: Specific to output posting

You can access related information in several ways:

- The **Navigate** action in the test shows:

   - Item ledger entries
   - Production order details
   - Warehouse entries
   - Related documents

- **Control Information** shows:
   - Source production order
   - Operation details
   - Posting information

### Complete production tests

The following steps give an overview of how to complete a production test.

1. Open a quality inspection test.
2. Enter the measurement values.
3. Review the calculated grade that the template configuration and measurement results determine.
4. **Finish** the test when it's complete.

## Advanced configuration

### Location-specific rules

You can create multiple rules for different locations. Set up a filter for each specific location, and select the template that you created for that location.

### Operation-specific testing

Configure testing for specific routing operations:

- **Routing No. Filter**: Specify a routing.
- **Work Center Filter**: Specify a work center.
- **Operation Filter**: Specify an operation number.

### Multi-stage testing

Set up testing at different production stages:

- **Assembly Operation**: Basic assembly checks
- **Wiring Operation**: Electrical verification
- **Testing Operation**: Final quality validation

## Production setup considerations

### Posting setup requirements

Ensure that you have a proper posting setups:

- **Inventory Posting Setup** for item transactions.
- **Manufacturing Posting Setup** for production costs.
- **Work Center Posting** for operation posting.

### Item tracking integration

Production output with item tracking:

- **Lot numbers** can be automatically assigned or manually entered.
- **Serial numbers** are supported for serialized items.
- **Package numbers** are supported for package tracking.

### Backflushing considerations

If you use backflushing, there are a few things to consider:

- Material consumption posts automatically.
- Component lot tracking might affect test creation.
- Review backflushing setup for quality integration.

## Troubleshooting output tests

The following sections describe typical issues and suggest solutions.

### Tests Not Creating

- Verify that your production trigger is set to **When Output is Posted**.
- Double-check your test generation rule filters.
- Ensure that the correct template is assigned.
- Confirm that output actually posted.

### Missing Item Tracking

- Verify that your item tracking code is configured.
- Double-check the lot number assignment during output.
- Ensure that item tracking posts with output.

### Posting Setup Errors

- Configure the required posting setups.
- Double-check your inventory posting groups.
- Verify your manufacturing posting setup.

## Related information

[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Manual Test Creation](qms-manual-test-creation.md)  
[Lot Blocking and Unblocking](qms-lot-blocking-unblocking.md)  
[Quality Management Overview](qms-overview.md)