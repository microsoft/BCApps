---
title: Manual test creation
description: Learn how to manually create quality inspection tests for reactive testing, investigations, and spot checks.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: concept-article
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Manual test creation

This article explains various ways to manually create quality inspection tests. Manual test creation provides flexibility for:

- Reactive testing, where you create tests in response to discovered quality issues.
- Investigating specific lots or items due to concerns.
- Spot checking, where you do random quality verification.
- Investigating customer complaints, where your tests are related to external feedback.

Manual tests use the same templates and configurations as automatic tests.

## Prerequisites

There are a few things to set up before you can manually create tests.

- Set up quality inspection templates. Learn more at [Create quality inspection templates](qms-quality-templates.md).
- Set up test generation rules with manual triggers. Learn more at [Set up test generation rules](qms-test-generation-rules.md).
- Make items available for testing.
- Assign the **Quality Inspection** permission sets to users.

## Configure test generation rules

You can set up rules for generating tests manually, or manually and automatically. This section describes how.

### Manual-only rules

Create rules specifically for manual test creation:

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Test Generation Rules**, and then choose the related link.
2. Create or modify rules, as follows:

   - **Purchase Trigger**: "Manual Only"
   - **Production Trigger**: "Manual Only"  
   - **Template Assignment**: Appropriate template
   - **Source Type**: Purchase Line, Production Order Routing Line, and so on.

### Manual rules versus automatic rules

**Manual only rules**:

- Tests are created only when you choose the **Create Test** action.
- Tests aren't automatically created when you post.
- Manual tests are ideal for reactive testing scenarios.

**Manual and automatic rules**:

- You can create tests automatically and manually.
- Provide flexibility for both proactive and reactive testing.
- Represents the most comprehensive approach to testing.

## Create tests manually

The following sections describe ways to manually create quality tests.

### Create a test from item tracking lines

This method is best for lot-specific testing when item tracking is already configured. It offers several advantages:

- Lot numbers automatically populated
- Quantities automatically assigned
- Direct connection to source document

1. Open a source document, such as a purchase order, production order, and so on.
2. Choose the **Item Tracking Lines** action.
3. Select specific lot/serial number lines.
4. Choose the **Create Test** action.

### Create a test from purchase or production lines

This method is best for testing untracked items without specific lot requirements. Information from the source document is prefilled, but you might have to enter lot numbers manually.

1. Open a source document, and select a line.
2. Choose the **Create Test** action from the line.
3. Select the appropriate template, if you're prompted to.
4. Manually specify a lot number, if necessary.

### Create a test from quality inspection templates

This method is best for creating tests that are independent of specific documents. It has several advantages:

- Complete flexibility in test configuration
- Not tied to specific business transactions
- Ideal for investigation and spot-checking

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Templates**, and then choose the related link.
2. Select the template to use.
3. Choose the **Create Test** action.
4. Set up parameters for your test, as follows:

   - **Source**: Optionally, enter the source document reference.
   - **Item Number**: Select the item to test.
   - **Lot/Serial Number**: Enter a lot or serial number, if needed.
   - **Quantity**: Specify the test quantity.

## Scenarios where you might create tests manually

The following sections offer high-level, sample scenarios in which you might manually create quality tests.

### Reactive testing from a purchase

Reactive testing is typically done in situations where you discover a quality issue after you receive goods from a purchase. In this case, you create the test from item tracking lines.

1. **Locate the purchase order**: Find the original purchase receipt.
2. **Access item tracking details**: Open item tracking lines.
3. **Select the problematic lots**: Choose the specific lots that have quality issues.
4. **Create a test**: Generate a test for investigation.
5. **Complete the test**: Perform a detailed quality evaluation.

### Production quality investigations

For example, if a customer complains about a finished good you produced, you might want to test the quality of your production output. In this case, you create the test from a quality template.

1. **Select a template**: Choose the appropriate quality template.
2. **Create a test**: Choose the **Create Test** action.
3. **Configure the details**:

   - Item: Finished goods item
   - Lot: Customer-reported lot number
   - Quantity: Representative sample
4. **Complete the test**: Perform a detailed quality evaluation.

### Spot check inspections

Some businesses do spot-checks to verify quality at random times. In this case, you create tests from purchase lines.

1. **Identify the items**: Select the items for spot checking.
2. **Access the document**: Open the relevant purchase order.
3. **Create a test**: Select the line, and then choose the **Create Test** action.
4. **Specify parameters**: Add lot information, if needed.
5. **Complete the test**: Perform a detailed quality evaluation.

## Configuration options for tests

The following sections describe the options for configuring tests.

### Template selection

When you create tests manually:

- **Automatic**: Test generation rules determine the template.
- **Manual Selection**: Choose a template that suits the situation.
- **Multiple Templates**: Create multiple tests with different templates.

### Link to source documents

With a source document:

- The test links to the originating transaction.
- You maintain traceability.
- The source information is prepopulated.

Without a source document:

- You do an independent quality test that isn't linked to a specific transaction.
- You must manually configure the test.

### Item tracking specifications

For lot-tracked items:

- Specify the lot number when you create the test.
- [!INCLUDE [prod_short](includes/prod_short.md)] verifies that the lot exists.
- The lot information displays in the test.

For items you track with serial numbers:

- Enter the specific serial numbers.
- Run an individual test per serial number.
- Maintain detailed traceability.

For nontracked items:

- Create the test without tracking information.
- Run quantity-based testing that's suitable for bulk materials.

## Best practices for manual testing

The following sections offer tips and best practices for doing manual testing.

### Documentation requirements

Record the reason that you chose to create tests manually, and document the quality concerns or triggers. It's a good idea to maintain an audit trail.

It's also important to document the results. Fill in all fields on the template, add notes about unusual findings, and link to corrective actions, if needed.

### Process integration

The workflow for reactive testing might look as follows:

1. Identify a quality issue.
2. Manually create a test.
3. Do your investigation and analysis.
4. Take corrective actions.
5. Verify the test.

The following are some recommendations for investigation protocol:

- Use consistent testing methods.
- Test appropriate sample sizes.
- Create good documentation.
- Use follow-up procedures.

## Troubleshoot manual test creation

The following sections describe typical issues and suggest solutions.

### The Create Test action isn't available

- Configure manual-enabled test generation rules.
- Verify your template assignments.
- Verify that you assigned the right permissions to your users.

### I'm missing template options

- Verify that you have templates and that they're properly configured.
- Double-check your test generation rule filters.
- Ensure that you filled in the required fields on your templates.

### I'm having problems with item selection

- Confirm that the item exists and is properly configured for quality management.
- Check whether your item tracking setup uses lot or serial numbers.
- Verify your item permissions.

### I'm missing source document details in my test information

- Create the test from the appropriate source document.
- Manually enter source information, if needed.
- Verify the document posting status.

### I'm having issues related to item tracking

- Confirm that you have lot or serial numbers.
- Double-check your item tracking code configuration.
- Verify the quantity allocations.

## Integration with automated testing

### Complementary approaches

**Automatic testing**: Proactive quality control

- Routine inspections
- Process compliance
- Prevention-focused

**Manual testing**: Reactive quality investigation

- Problem investigation
- Customer complaint resolution
- Corrective action verification

### Unified results management

Both manual and automatic tests:

- Use the same templates and measurement criteria.
- Generate comparable results.
- Integrate with lot blocking and workflows.
- Support comprehensive quality reporting.

## Related information

[Purchase Receipt Testing Without Warehouse Tracking](qms-purchase-receipt-testing-simple.md)  
[Production Output Quality Testing](qms-production-output-testing.md)  
[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Quality Management Overview](qms-overview.md)