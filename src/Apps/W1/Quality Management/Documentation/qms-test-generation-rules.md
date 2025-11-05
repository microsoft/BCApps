---
title: Set up test generation rules
description: Learn how to configure test generation rules to automate quality inspections based on business transactions.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Set up test generation rules

Test generation rules define when and how to automatically create quality inspection tests in response to business transactions. These rules connect your quality inspection templates to specific business processes.

A test generation rule defines when you want to ask a set of questions or collect the data you want. You define the questions and data, such as measurements, in your quality inspection template. You connect a template to a source table, and set the criteria to use that template with the table filter. When the filter criteria are met, it chooses that template. When there are multiple matches, it uses the first template that it finds, based on the sort order.

Test generation rules control the following aspects:

- When to create tests (triggers).
- Which templates to use for testing.
- Which items, locations, or documents create tests.
- How to create tests, that is, either automatically or manually.

## Rule components

This section describes the components that make up a test generation rule.

### Types of source documents

You can create test generation rules for various types of source documents.

**Purchase**:

- Creates tests based on purchase order transactions.
- Triggers when you post purchase receipts.
- Supports filters for vendors and items.

**Production order routing**:

- Creates tests based on production output.
- Triggers when you post output.
- Supports filters for routes, work centers, and operations.

**Warehouse journals**:

- Creates tests for warehouse-specific operations.
- Supports put-away and movement testing.
- Integrates with warehouse workflows.

You can also create rules for **Sales Return**, **Warehouse Receipt**, **Warehouse Movement**, **Transfer**, and **Assembly** documents.

### Trigger configuration

**Activation trigger**:

- **Disabled**: No automatic test creation.
- **Automatic Only**: Automatic creation when you post a receipt.
- **Manual Only**: Only allow manual test creation.
- **Both Manual and Automatic**: Both methods are enabled.

**Purchase trigger**:

- **Never**: No automatic test creation.
- **When Purchase Order is Received**: Automatic creation when you post a receipt.
- **When Purchase Order is Released**: Automatic creation when you release a purchase order.

**Production trigger**:

- **Never**: No automatic test creation.
- **When Output is Posted**: Automatic creation when you post production output.
- **When Order is Released**: Automatic creation when you change the status of a production order to **Released**.
- **When a Released Order is Refreshed**: Automatic creation when you refresh a released production order.

## Create test generation rules

There are several ways to create test generation rules, depending on their purpose. 

### Create a receiving rule (purchases)

This rule is best for testing purchase receipts.

1. [!INCLUDE [prod_short](includes/prod_short.md)], enter **Quality Inspection Test Generation Rules**, and then choose the related link.
2. Choose **Create Receiving Rule**.
3. Fill in the fields, as follows:
   - **Template Code**: Select a quality template.
   - **Receiving Rule**: Automatically set to **Purchase Line**.
   - **Location, Vendor No., Purchasing Code, Specific Item, Category, Inventory Posting Group**: Specify which items, groups of items, locations, and so on, can create tests.
   - **Automatically Create Test**: Specify a trigger to automatically create a test when you receive a product for a purchase order.

### Create a production rule

This rule is best for testing production output.

1. [!INCLUDE [prod_short](includes/prod_short.md)], enter **Quality Inspection Test Generation Rules**, and then choose the related link.
2. Choose **Create Production Rule**.
3. Fill in these fields, as follows:
   - **Template Code**: Select a quality template/
   - **Source Type**: Automatically set to **Production Orders**.
   - **Filters**: Configure the filters, as needed.
   - **Automatically Create Test**: Select a type of trigger.

### Create a rule manually

This rule is best when you have custom or complex filtering requirements.

1. [!INCLUDE [prod_short](includes/prod_short.md)], enter **Test Generation Rules**, and then choose the related link.
2. Choose **New** to create a new rule.
3. Configure all fields manually.

## Configure filters

The following table describes filter fields that are often used.


|Type of filter  |Use  |
|---------|---------|
|Item Filters     |  - **Item No. Filter**: Specific items requiring testing.<br>- **Item Category Filter**: Groups of related items.<br>- **Inventory Posting Group Filter**: Items with similar characteristics.    |
|Location Filters     | **Location Code Filter**: Specific locations that require testing.        |
|Vendor/Customer Filters     |  - **Vendor No. Filter**: Vendor-specific quality requirements.<br>- **Customer No. Filter**: Customer-specific testing needs.       |
|Production Filters     |  - **Routing No. Filter**: Test specific production processes.<br>- **Work Center No. Filter**: Test specific work centers.<br>- **Machine Center No. Filter**: Test specific machines.       |

### Examples of filters and rules

The following sections provide examples of test generation rules.

#### Create a basic, item-based rule

Use an item-based rule to test all receipts of a specific item.

- **Source Type**: **Purchase Line**
- **Item No. Filter**: <\enter the item number>
- **Purchase Trigger**: **When Purchase Order is Received**
- **Other Filters**: (blank for universal application)

#### Create a location-specific rule

Use a location-specific rule to test all items at a specific location.

- **Source Type**: **Purchase Line**
- **Location Code Filter**: <\enter a location code>
- **Purchase Trigger**: **When Purchase Order is Received**
- **Item Filter**: (blank for all items)

#### Create a vendor-specific rule

Use a vendor-specific rule for enhanced testing items from a specific vendor.

- **Source Type**: **Purchase Line**
- **Vendor No. Filter**: <\enter the vendor number>
- **Purchase Trigger**: **When Purchase Order is Received**
- **Template**: Enhanced inspection template

## Rule priority and order

When multiple rules could apply to the same transaction:

- **All matching rules execute**: Multiple tests can be created.
- **Rule ordering**: Managed through rule list sequence.
- **Template assignment**: Each rule uses its assigned template.

### Best practices for using multiple rules

When you have multiple rules, avoid overlaps. Design your rules to minimize unintended creation of multiple tests. Use specific filters for special cases, and maintain documentation of rule interactions

## Trigger configuration strategy

The following sections provide suggestions for best practices when you set up triggers for rules.

### Align rules with business processes

For proactive testing, automatic triggers provide the following benefits:

- They make quality requirements predictable.
- They make testing part of standard process.
- They ensure that resources are available for immediate testing.

For reactive testing, manual triggers provide the following benefits:

- They base testing on risk assessment.
- They require limited quality resources.
- They make testing driven by investigations.

You can also use a hybrid approach and combine both methods to gain maximum flexibility:

- Automatic for routine quality control.
- Manual for special investigations.

### Remember organizational considerations

Think about keeping roles separate:

- Use automatic triggers when different people post versus test.
- Use manual triggers when the same person does both.
- Consider workflow and responsibility assignments.

Manage your resources:

- Automatic triggers require dedicated quality resources.
- Manual triggers allow resource optimization.
- Balance coverage with capacity.

## Test your rule configuration

This section describes high-level steps to validate your rule configuration.

1. Create a test scenario:

   - Configure a rule with specific filters.
   - Create a matching business transaction.
   - Verify that a test is created as expected.

2. Double-check your rule logic:

   - Confirm that filters work as you expect.
   - Verify that you assigned the correct template.
   - Test the trigger behavior.

3. Review the results:

   - Validate the test content and structure.
   - Check links to source documents.
   - Confirm item tracking integration.

### Troubleshooting test generation rules

The following sections describe typical issues and suggest solutions.

#### No tests are created

- Double-check you filter configuration.
- Verify your trigger settings.
- Confirm that you assigned the correct template.

#### Too many tests are created

- Look for rules that overlap.
- Make your filters more specific.
- Double-check the order of your rules.

#### The wrong template is applied

- Verify the template assignment in the rule.
- Double-check your rule priority and order.
- Review your filter logic.

## Maintenance and updates

This section describes ways to maintain and update rules.

If you want to update existing rules, you can:

- Modify filters to expand or restrict their scope.
- Change templates for improved testing.
- Adjust triggers based on process changes.

If you want to use version control, you can:

- Document rule changes.
- Test your changes before you implement them.
- Maintain a backup of working configurations.

### Performance considerations

There are several things you can do to help ensure that things run quickly, and smoothly.

Think about filter efficiency:

- Use specific filters to improve performance.
- Avoid overly broad rules if they aren't needed.
- Monitor system performance if you have complex rules.

Consider how many rules you really need:

- Balance comprehensive coverage with system performance.
- Consolidate similar rules where possible.
- Regularly review your rules and clean up the ones you aren't using.

## Related information

[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Purchase Receipt Testing Without Warehouse Tracking](qms-purchase-receipt-testing-simple.md)  
[Production Output Quality Testing](qms-production-output-testing.md)  
[Manual Test Creation](qms-manual-test-creation.md)  
[Quality Management Overview](qms-overview.md)