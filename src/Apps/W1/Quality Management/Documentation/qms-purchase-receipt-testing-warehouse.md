---
title: Purchase receipt testing with warehouse tracking
description: Learn how to set up and use automatic quality inspection tests for purchase receipts in warehouse-enabled locations.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Purchase receipt testing with warehouse tracking

This article explains how to set up and use automatic quality inspection test creation for purchase receipts in locations with warehouse handling.

For locations with warehouse handling, quality tests are created when you post warehouse receipts. This workflow integrates with warehouse management, and supports:

- Locations that require warehouse receipts.
- Complex warehouse operations with put-aways.
- Multiple lot numbers per receipt.
- Warehouse tracking and traceability.

## Prerequisites

- A quality inspection template is configured.
- A test generation rule set up for purchase receipts.
- A location where warehouse receipt handling is enabled.
- Items that have item tracking (optional, but recommended)

## Key differences from locations without warehouse tracking

| Feature       | Without Warehouse          | With Warehouse                                |
| ------------- | -------------------------- | --------------------------------------------- |
| Document Flow | Purchase Order → Receipt   | Purchase Order → Warehouse Receipt → Put-away |
| Test Trigger  | Purchase Receipt Posting   | Warehouse Receipt Posting                     |
| Configuration | Same test generation rules | Same test generation rules                    |
| Item Tracking | Direct on purchase order   | Can use lot warehouse tracking                |

## Set up the requirements

The following sections describe how to set up the requirements for testing purchase receipts with warehouse tracking.

### 1. Verify the configuration of your location

Ensure that your location supports warehouse operations:

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Locations**, and then choose the related link.
2. Select a warehouse-enabled location.
3. Verify that the **Require Receipt** toggle is turned on.
4. Double-check the other warehouse settings, as needed.

### 2. Use existing test generation rules

The same test generation rules work for both warehouse and nonwarehouse locations:

- **Source Type**: **Purchase Line**
- **Purchase Trigger**: **When Purchase Order is Received**
- **Template**: Assigned quality inspection template
- **Filters**: Item and location filters, as needed

> [!NOTE]
> The **When Purchase Order is Received** trigger works for both direct posting and warehouse receipt posting.

## Process flow with warehouse handling

The following sections provide a high-level overview of the process flow with warehouse handling.

### Step 1: Create a purchase order

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Purchase Orders**, and then choose the related link.
2. Create a new purchase order.
3. Fill in the fields, as follows:

   - **Vendor**: Select a vendor.
   - **Item**: Choose the item specified in the test generation rule.
   - **Location**: Use a location that is warehouse-enabled.
   - **Quantity**: Enter the quantity to receive.

### Step 2: Configure item tracking

For lot-tracked items:

1. Choose **Item Tracking Lines** on a purchase order line.
2. Enter lot information, as follows:
   - **Lot Number**: Create or select lot numbers.
   - **Quantity**: Assign a quantity to lots.
   - **Expiration Date**: Set expiration dates.
3. You can configure multiple lots per line.

   **Example configuration**:

     The following example shows settings for multiple lots.

   - Total Quantity: 123
   - Lot A: 23 pieces, expiration date
   - Lot B: 100 pieces, expiration date

### Step 3: Create and post a warehouse receipt

1. Choose **Release** to release the purchase order.
2. Choose **Create Warehouse Receipt** to create a warehouse receipt with the following information:

   - The total quantity from the purchase order.
   - The item tracking information transferred.
   - The bins assigned based on the location's setup.

3. Choose **Post** to post the receipt.

   The following things happen when you post the warehouse receipt:

   - Quality inspection tests are created automatically.
   - A test is created per lot number, if item tracking is used.
   - Tests reference the original purchase order.
   - Put-away documents are created for warehouse operations.

## Work with multiple lots

When you receive multiple lots:

- Each lot gets its own quality inspection test.
- Tests are linked to specific lot numbers.
- Quantities reflect lot-specific amounts.

**Example**: A receipt with two lots creates two tests:

- Test 1: Lot A, 23 pieces
- Test 2: Lot B, 100 pieces

### Manage lot tests

You can access lot-specific tests through:

1. **Show Tests for Item and Document** from a purchase order.
2. **Quality Inspection Tests** filtered by lot number.
3. **Lot Number Information**, if you configured lot blocking.

## Integration with warehouse operations

### Put-away processing

After you post a warehouse receipt:

1. Warehouse put-away documents are created automatically and reference the same lot numbers.
2. Quality tests can be completed during or after put-away.
3. Lot blocking can prevent movement until tests pass.

### Warehouse tracking

[!INCLUDE [prod_short](includes/prod_short.md)] maintains full traceability in the warehouse:

- Item tracking follows through to warehouse documents.
- Results of quality tests are linked to specific lots.
- Warehouse entries reference quality inspection data.

## Configuration considerations

Consider the pros and cons of using item tracking or lot warehouse tracking

For standard item tracking (recommended):

- You define item tracking on the purchase order.
- Lot numbers transfer to warehouse documents.
- Quality tests use purchase order tracking information.

For lot warehouse tracking:

- Lot numbers are assigned during warehouse operations.
- Setup and processing are more complex.
- Supported, but optional for quality testing.

Pay attention to your test generation rule triggers. The same trigger works for both scenarios:

- The **When Purchase Order is Received** trigger works when you post a warehouse receipt.
- You don't need a separate configuration for warehouse versus nonwarehouse setups.
- Rules apply consistently across location types.

## Troubleshooting

The following sections describe typical issues and suggest solutions.

### No tests are created

- Verify that the **Require Receipt** toggle is turned on for the location.
- Double-check that the test generation rule applies to the item.
- Ensure that the warehouse receipt is posted.

### I'm getting the wrong number of tests

- Review your item tracking configuration.
- Check for lot consolidation in the warehouse receipt.
- Verify the logic in your test generation rule.

### Tests are missing lot information

- Confirm that item tracking is correctly configured.
- Check whether lot numbers transfer to warehouse documents.
- Verify that your item tracking code is set up.

## Related information

[Purchase Receipt Testing Without Warehouse Tracking](qms-purchase-receipt-testing-simple.md)  
[Lot Blocking and Unblocking](qms-lot-blocking-unblocking.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Quality Management Overview](qms-overview.md)