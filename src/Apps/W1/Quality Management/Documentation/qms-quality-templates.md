---
title: Create quality inspection templates
description: Learn how to create and configure quality inspection templates to streamline quality testing processes and ensure compliance with quality standards.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Create quality inspection templates

Quality inspection templates define the measurements and attributes you want to collect during quality testing. Templates serve as the foundation for all quality tests, and contain:

- A **Template Code**, which is the unique identifier for the template.
- A **Description** that provides an idea of the purpose of the template.
- Fields and measurements, which are the individual quality measurements to collect.
- Pass/fail criteria, which are the acceptable ranges for each measurement.

## Create a new template

The following sections describe how to set up a quality inspection template.

### Step 1: Fill in the template header

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Templates**, and then choose the related link.
2. Choose **New** to create a new template.
3. Fill in the **Template Code** field. For example, enter EXAMPLE or INCOMING-PARTS.
4. Fill in the **Description** field. For example, enter Example Template or Incoming Parts Inspection.

### Step 2: Add fields and measurements

Follow these steps for each quality measurement you want to collect:

1. On the quality inspection template, choose **Add field(s) to this template**.
2. Configure the field properties, as follows:
   - **Description**: Enter a short description of the measurement. For example, enter Example Measurement, Weight, or Dimension.
   - **Allowable Values**: Range of values that can be entered.
   - **Default Value**: The default value to set on a test.
   - **Pass Values**: Range of values that constitute a passing result.

### Field Configuration Example

The following are sample settings for a measurement field:

- **Description**: "Example Measurement"
- **Allowed Values**: 5 to 90 (the system accepts any value in this range)
- **Pass Values**: 10..20 - values between 10 and 20 result in a passing grade.

The following are the results of the sample settings:

- No value entered: "In Progress" grade (default).
- Values 5-9: "Fail" grade. The value is outside the pass range but within the allowed values.
- Values 10-20: "Pass" grade (meets pass criteria).
- Values 21-90: "Fail" grade because the value is outside the pass range but within the allowed values.
- Values outside 5-90: [!INCLUDE [prod_short](includes/prod_short.md)] rejects the entry because it's outside the allowed values.

## Best practices for template design 

### Measurement selection

Consider the following when you choose your measurements:

- Include only essential quality characteristics.
- Focus on critical-to-quality parameters.
- Consider measurement time and complexity.

### Template organization

Consider the following when you organize your templates:

- Create specific templates for different types of inspections.
- Group related measurements together.
- Use descriptive field names.
- Document any template-specific grade overrides.

## Typical template scenarios

The following sections describe typical uses for templates.

### Incoming material inspections

A typical use is to inspect purchased materials. Some examples of fields are:

- Dimension measurements
- Visual appearance checks
- Material compliance verification

### Production output inspections

A typical use is to test the finished goods that you produce. Some examples of fields are:

- Functional performance tests
- Assembly quality checks
- Final dimension verification

### In-process inspections

A typical use is to do quality checks during production. Some examples of fields are:

- Intermediate measurements
- Process parameter verification
- Work-in-progress quality gates

## Manage templates

You can copy templates to create new templates based on their settings. Select a template, and then choose the **Copy** action to create a duplicate. You can modify the fields on the new template to suit your needs.

> [!NOTE]
> Before you activate a template and use it in production, validate its setup and results.

Templates connect to automated test creation through test generation rules:

1. **Template Assignment**: Each test generation rule references a specific template.
2. **Automatic Application**: When rules trigger, the associated template creates the test structure.
3. **Data Collection**: Test users fill in the template fields during inspection.

## Troubleshooting templates

The following sections describe typical issues and suggest solutions.

### Tests aren't creating

- Verify that your test generation rules reference the template.
- Double-check that your template configuration is complete.
- Ensure that your field definitions are correct.

### My pass/fail results are incorrect

- Review your pass value ranges.
- Verify that your allowed value ranges include pass values.
- Double-check your field type configuration.

### There are issues with performance

- Minimize the number of complex fields.
- Optimize your field calculations.
- Consider whether you can simplify your template.

## Related information

[Configuring Quality Inspection Grades](qms-configuring-grades.md)  
[Setting Up Test Generation Rules](qms-test-generation-rules.md)  
[Manual Test Creation](qms-manual-test-creation.md)  
[Quality Management Setup and Configuration](qms-quality-management-setup.md)  
[Quality Management Overview](qms-overview.md)