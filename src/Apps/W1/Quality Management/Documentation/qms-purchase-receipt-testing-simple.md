---
title: Purchase receipt testing without warehouse tracking
description: Learn how to set up and use automatic quality inspection test creation for purchase receipts in locations without warehouse handling.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Purchase receipt testing without warehouse tracking

This article explains how to set up and use automatic quality inspection test creation for purchase receipts in locations without warehouse handling. For example, like the Silver location in the Contoso demo data.

For locations without warehouse handling, quality tests are created automatically when you directly post purchase receipts. This simpler workflow is ideal for:

- Smaller operations without complex warehouse management.
- Locations that use bin management but don't use warehouse documents.
- Quick receipt and inspection processes.

## Prerequisites

- A quality inspection template is configured
- A test generation rule is set up for purchase receipts.
- Items have lot tracking (optional, but recommended).
- Location doesn't use warehouse receipt handling.

## Set up the requirements

The following sections describe how to set up the requirements for purchase receipt testing without warehouse tracking.

### Create a quality inspection template

If you don't already have a template, follow these steps to set up a template for incoming inspections:

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Templates**, and then choose the related link.
2. Create new template. For example, name it **EXAMPLE**.
3. Add measurement fields with pass/fail criteria.

The following example shows settings in a quality inspection template:

- **Field Name**: "Example Measurement"
- **Allowed Values**: 5 to 90
- **Pass Values**: 10 to 20

### Configure a test generation rule

Set up a rule to automatically create tests for purchase receipts:

#### Method 1: Manual rule creation

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Test Generation Rules**, and then choose the related link.
2. Create a new rule.
3. Fill in the fields, as follows:

   - **Source Type**: **Purchase Line**
   - **Template Code**: Select your template.
   - **Purchase Trigger**: **When Purchase Order is Received**
   - **Item Filter**: Specify the items to test.

#### Method 2: Use a create receiving rule

1. From the template or test generation rules, choose **Create Receiving Rule**.
2. Select your template.
3. Configure filters, as follows:

	- **Item Number Filter**: Specify the items.
	- **Location Filter**: Leave blank, or specify a location.
4. For the **Purchase Trigger**, choose **When Purchase Order is Received**.

### Verify your location configuration

Ensure that you properly configured your location:

- The location shouldn't require warehouse receipts.
- You can configure bins for the location.
- Verify that the location supports item tracking, if needed.

## Create tests through a purchase receipt

### Step 1: Create a purchase order

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Purchase Orders**, and then choose the related link.
2. Create a new purchase order.
3. Fill in the fields, as follows:

   - **Vendor**: Select the appropriate vendor.
   - **Item**: Choose an item configured in the test generation rule.
   - **Location**: Choose a location that doesn't use warehouse handling.
   - **Quantity**: Enter a quantity to receive.

### Step 2: Configure item tracking (if applicable)

For lot-tracked items:

1. On the **Lines** FastTab for your purchase order, choose **Item Tracking Lines**.
2. Enter lot numbers:
   - Use existing lot numbers, or create new ones.
   - Assign a quantity to each lot.
   - Set expiration dates, as needed.
3. Specify bin codes, if the location uses bins.

### Step 3: Post the purchase receipt

1. **Release** the purchase order, if needed.
2. Choose **Post** from the purchase order.
3. Select **Receive**, or **Receive and Invoice**.
4. Confirm the posting.

   The following things happen when you post the purchase receipt:

   - One quality inspection test per lot number is created automatically, if item tracking is used.
   - Tests might open automatically, depending on setup configuration.

## Work with created tests

You can access tests in the following ways:

1. **Quality Inspection Tests** page (view all tests)
2. **Show Tests for Item and Document** from the purchase order
3. Automatic popup, if you specified that on the **Quality Management Setup** page.

Each created test contains:

- The **Item Number** of the purchased item.
- The **Lot Number** of the specific lot being tested, if applicable.
- The **Quantity** from item tracking line.
- A **Source Document** reference to the originating purchase order.
- **Template Fields**, which are the measurements to be complete.

### Complete a quality inspection test

To complete a test, follow these steps:

1. Open the quality inspection test.
2. Enter your measurement values in the template fields.
3. Review the calculated grade that the template configuration and measurement results determined.
4. Choose **Finish** to complete the test.

## Configuration options

The following sections describe various configuration options on the **Quality Management Setup** page.

### Control test display behavior

Choose one of the following options in the **Show Test Behavior** field:

- **Automatically and Manually Created Tests**: Tests open immediately when you create them. This option is good for demonstrations and training. It's also convenient for immediate inspection workflows.
- **Only Manually Created Tests**: Tests create in the background. This option is good for production environments. IT also separates receipt posting from inspection roles.

### Configure when to trigger test creation

Configure when to create tests, as follows:

- **Automatic Only** means that tests always create when you post a receipt.
- **Manual or Automatic** means to create tests manually or automatically.
- **Manual Only** means that you must manually create tests.

## Troubleshooting

The following sections describe typical issues and suggest solutions.

### Tests aren't being created automatically

- Verify that you properly configured your test generation rule.
- Double-check that your item filter matches the purchased item.
- Ensure that you set up your purchase trigger correctly.
- Confirm that the template is assigned to the rule.

### Tests are creating for the wrong items

- Review the item filters in your test generation rules.
- Check whether rules overlap.
- Verify your rule priority and ordering.

### Test data is missing

- Confirm that you correctly configured item tracking.
- Verify that lot numbers are assigned before posting.
- Check the bin assignments, if the location requires bins.

## Related information

[Purchase Receipt Testing With Warehouse Tracking](qms-purchase-receipt-testing-warehouse.md)  
[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Manual Test Creation](qms-manual-test-creation.md)  
[Quality Management Overview](qms-overview.md)