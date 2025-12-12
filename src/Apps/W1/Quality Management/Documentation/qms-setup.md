---
title: Quality management setup and configuration 
description: Learn how to set up and configure quality management features, including prerequisites, initial setup steps, and common scenarios.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: how-to
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Quality management setup and configuration

This article takes you through the initial setup and configuration of quality management features.

## Prerequisites

Before you set up Quality Management, ensure that you have:

- The Quality Management app installed.
- Administrative permissions in [!INCLUDE [prod_short](includes/prod_short.md)].
- Understood your quality control requirements.

## Initial setup steps

### Run the assisted setup guide

The Quality Management app includes an assisted setup guide that can help you configure basic settings.

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Assisted Setup**, and then choose the related link.
2. Find and run the **Set up Quality Management** guide.
3. Follow the steps in the guide. Learn more at [Assisted Setup Wizard](qms-assisted-setup-wizard.md).

### Configure base data

Ensure you configured base data in [!INCLUDE [prod_short](includes/prod_short.md)] as described in the following table.

|Data  |Description  |
|---------|---------|
|Locations     |- Configure the locations where you do quality testing.<br>- Set up warehouse handling, if necessary. For example, receipts, put-aways, and so on.<br>- Define bins for your quality testing areas.         |
|Items     |- Configure item tracking codes for lots, serials, or packages, as needed.<br>- Set up lot number series for automatic lot assignments.<br>- Ensure that the correct inventory posting groups are assigned to items. |
|Vendors and customers     |- Configure vendors for purchase receipt testing.<br>- If quality testing affects sales processes, set up customers.       |

### Set up Quality Management

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Management Setup**, and then choose the related link.
1. Configure general settings, as described in the following table.

   |Field  |Description  |
   |---------|---------|
   |**Quality Inspection Nos.** | Specify the default number series to use for quality inspection documents when there isn't a number series defined on a quality inspection template. The number series defined on a template takes precedence.  |
   |**Create Test Behavior** | Specify when to create a new test when existing tests happen:<br><br>- **Always create new test** creates a new test every time.<br>- **Create retest if matching test is finished** creates a retest only if an existing matching test completed.<br>- **Always create retest** always creates a retest when tests already exist.<br>- **Use existing open test if available** reuses an existing open test if one exists.<br>- **Use any existing test if available** reuses any existing test, regardless of status.        |
   |**Find Existing Behavior** | Specifies the criteria the system looks for when it searches for existing tests.<br><br>- **By Standard Source Fields** uses standard source fields to find existing tests.<br>- **By Source Record** finds tests based on the source record.<br>- **By Item Tracking** uses item tracking information such as lot and serial numbers.<br>- **By Document and Item only** searches only by document and item and ignores other criteria.        |
   |**Conditional Lot Find Behavior**| Specifies the tests to consider when evaluating whether a document-specific transaction is blocked.<br><br>- **Any test that matches** considers any test.<br>- **Only the most recently modified test** uses the most recently modified test.<br>- **Only the newest test/re-test** uses the test with the highest retest number.<br>- **Any finished test that matches** considers any finished test.<br>- **Only the most recently modified finished test** uses the most recently modified finished test.<br>- **Only the newest finished test/re-test** uses the finished test with the highest retest number.        |
   |**COA Contact No.** | Specifies the contact details that appear on the **Certificate of Analysis** report when supplied.        |
   |**Maximum Rows To Fetch on Field Lookups** | Specifies the maximum number of rows to fetch on data lookups. Keep the number as low as possible to increase usability and performance.        |
   |**Show Test Behavior** | Specifies whether to show the **Quality Inspection Test** page after a test is made.<br><br>- **Automatic and manually created tests** shows tests created both automatically and manually.<br>- **Only manually created tests** shows only tests created manually.<br>- **Do not show created tests** never automatically shows created tests.    |
   |**Picture Upload Behavior** | Specifies what to do with pictures.<br><br>- **Do nothing** means not to take an action with pictures.<br>- **Attach document** attaches the picture as a document.<br>- **Attach and upload to OneDrive** attaches the picture and uploads it to OneDrive.        |
   |**Workflow Integration Enabled** | When enabled, this option provides the events and responses for quality management that you need to work with workflows and approvals.        |

1. Configure settings for receiving, as described in the following table.

   |Field  |Description  |
   |---------|---------|
   |**Warehouse Receipts** | Specifies the default warehouse receipt trigger value for test generation rules.<br><br>- **Never** means no automatic test creation.<br>- **When Whse. Receipt is created** creates a test when you create a warehouse receipt.<br>- **When Whse. Receipt is posted** creates a test when you post a warehouse receipt.        |
   |**Purchase Orders** | Specify a default purchase trigger value for test generation rules.<br><br>- **Never** means no automatic test creation.<br>- **When Purchase Order is received** creates a test when you post a purchase order receipt.<br>- **When Purchase Order is posted** creates a test when you release a purchase order.        |
   |**Sales Returns** | Specifies a default sales return trigger value for test generation rules.<br><br>- **Never** means no automatic test creation.<br>- **When Sales Return is received** creates a test when you post a sales return order receipt.        |
   |**Transfer Orders** | Specifies a default transfer trigger value for test generation rules.<br><br>- **Never** means no automatic test creation.<br>- **When Transfer Order is received** creates a test when you post a transfer order receipt.        |

1. Configure settings for production, as described in the following table.

   |Column1  |Column2  |
   |---------|---------|
   |**Production - Create Test** | Specify a default production-related trigger value for test generation rules.<br><br>- **Never** means no automatic test creation.- **When Output is posted**: Creates a test when you post production output.<br- **When Order is released** creates a test when you release a production order.<br>- **When a released order is refreshed** creates a test when you refresh a released order.        |
   |**Auto Output Configuration** | Specify options for when to create a test automatically during the production process.<br><br>- **Any Output Entry**: Creates a test on any output.- **Any Quantity Output** creates a test when you post a quantity.<br>- **Only with Quantity** creates a test only when you post a quantity.<br>- **Only with Scrap** creates a test only when you post scrap.        |
   |**Assembly - Create Test**  | Specify a default assembly-related trigger value for test generation rules.<br><br>- **Never** means no automatic test creation.<br>- **When Output is posted** creates a test when you post assembly output.        |

1. Configure settings for inventory and warehousing, as described in the following table.

   | Field | Description   |
   |---------------------|-------|
   | **Create Test** | Specify a default warehousing-related trigger value for test generation rules.<br><br>- **Never** means no automatic test creation<br>- **Movement into Bin** creates a test when you register a warehouse movement. |
   | **Batch Name (Bin Movements)** | Specify the batch to use for bin movements and reclassifications for nondirected pick and putaway locations. |
   | **Whse. Batch Name (Bin Movements)** | Specify the batch to use for bin movements and reclassifications for directed pick and putaway locations. |
   | **Whse. Worksheet Name**| Specify the worksheet to use for warehouse movements for directed pick and putaway locations.            |
   | **Batch Name (Inventory Adjustments)** | Specify the batch to use for negative inventory adjustment item journals.                              |
   | **Whse. Batch Name (Inventory Adjustments)** | Specify the batch to use for negative inventory adjustment warehouse item journals.                  |

1. To configure settings for item tracking, in the **Tracking Before Finishing** field, specify whether to require item tracking before finishing a test

   - **Allow missing item tracking** allows tests without lot or serial numbers.
   - **Posted Item Tracking only** requires you to post lot or serial numbers.
   - **Reservation or posted** allows lot or serial numbers that exist but aren't posted yet.
   - **Any non-empty value** allows any nonempty lot or serial value, even if they aren't in inventory.

## Next steps

After you complete the initial setup, there are still a few things to do. To learn more, go to:

1. [Create Quality Inspection Templates](qms-quality-templates.md)
2. [Set Up Test Generation Rules](qms-test-generation-rules.md)
3. [Configure Workflows (Optional)](qms-quality-workflows.md)
<!--4. [Test Your Configuration](./testing-configuration.md)-->

## Typical setup scenarios

The following sections offer things to think about when you set up the app for certain scenarios.

### Purchase receipt testing only

- Focus on purchase trigger configuration.
- Create templates for inspecting incoming goods.
- Set up rules for vendor-specific or item-specific testing.

### Production output testing only

- Focus on production trigger configuration
- Create templates for finished goods inspection
- Set up rules for routing-specific or work center-specific testing

### Comprehensive quality system

- Configure both purchase and production triggers.
- Create multiple templates for different types of inspections.
- Set up workflows to automatically block and unblock lots.

## Troubleshooting setup issues

The following sections describe typical issues and suggest solutions.

### Quality tests aren't created automatically

- Verify the trigger settings on the **Quality Management Setup** page.
- Double-check that your test generation rules are correctly configured.
- Ensure that you assigned templates to your test generation rules.

### Workflow events aren't available

- Verify that the **Enable Workflow Integration** is enabled on the **Quality Management Setup** page.
- Check that users are assigned the appropriate permissions.

## Related information

[Assisted Setup Wizard](qms-assisted-setup-wizard.md)  
[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Quality Management Overview](qms-overview.md)