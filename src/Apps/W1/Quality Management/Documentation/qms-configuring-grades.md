---
title: Configure quality inspection grades
description: Learn how to configure and manage quality inspection grades, including grade setup, priority rules, and business process integration.
author: brentholtorf
ms.author: bholtorf
ms.reviewer: bholtorf
ms.topic: overview
ms.search.form: 
ms.date: 10/20/2025
ms.service: dynamics-365-business-central
ms.custom: bap-template

---

# Configure quality inspection grades

This guide explains how to configure and use quality inspection grades in quality management. Grades are configurable states that determine test results and control business processes based on quality outcomes.

## Overview

Quality inspection grades represent the possible outcomes of quality tests. Typical grades are incomplete, fail, and pass, however you can configure as many grades as you want, and in what circumstances. Grades with a lower number in the **Priority** field are evaluated first. If you're unsure what to configure, use the three defaults. To learn more about the defaults, go to [Grade concepts](#grade-concepts). Document-specific lot blocking is for combinations of items, variants, lots, serial numbers, and package numbers, and you can use it for serial-only tracking, or package-only tracking.

### Grade concepts

**Default grades**:

- **In Progress** (Priority 0): The test is incomplete or in progress.
- **Fail** (Priority 1): The test failed to meet quality criteria.  
- **Pass** (Priority 2): The test met quality criteria.

**Custom grades**:

- Create multiple passing grades. For example, Excellent, Good, and Acceptable.
- Create multiple failing grades. For example, Minor Defect, Major Defect, and Critical Failure.
- Create gray state grades. For example, Under Review and Conditional Pass.

## Configuring available grades

### Step 1: Access quality inspection grades

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Grades**, and then choose the related link.
2. Review the existing grades and their order of priority. Grades display from lowest to highest priority.

### Step 2: Understand the default grade structure

The following table shows an example of a configuration.

| Grade Code | Description | Priority | Copy Behavior      | Allow Sales | Allow Purchase |
| ---------- | ----------- | -------- | ------------------ | ----------- | -------------- |
| INPROGRESS | In Progress | 0        | Automatically Copy | Block       | Allow          |
| FAIL       | Fail        | 1        | Automatically Copy | Block       | Allow          |
| PASS       | Pass        | 2        | Automatically Copy | Allow       | Allow          |

In this example, sales transactions for a lot are restricted until the quality test is complete and passes all criteria. If the test is incomplete or fails, sales are blocked. Purchase transactions, however, are always allowed.

### Step 3: Grade priority rules

**Priority 0 (incomplete or in progress)**:

- Represents incomplete or ongoing tests.
- Default condition should be blank (matches any value including empty).
- Evaluated first in grade determination.

**Priority 1+ (failure states)**:

- Represents various failure conditions.
- Must have a higher priority than incomplete grades.
- Must have a lower priority than pass grades.

**Highest priority (pass states)**:

- Represents successful test outcomes.
- Evaluated last in grade determination.
- Must have the highest priority numbers.

### Step 4: Copy behavior configuration

**Automatically Copy the Grade**:

- Grade is automatically added to new templates.
- Default behavior for standard grades.
- Ensures consistent grade availability.

**Do Not Copy**:

- You must manually add the grade to templates.
- Use for specialized or conditional grades.
- Allows selective grade application.

### Step 5: Available transactions control

- **Allow Sales**: Enable or disable sales document posting.
- **Allow Purchase**: Enable or disable purchase document posting.
- **Allow Transfer**: Enable or disable transfer order posting.
- **Allow Consumption**: Enable or disable material consumption in production.
- **Allow Pick**: Enable or disable warehouse picks.
- **Allow Put-away**: Enable or disable warehouse put-aways.
- **Allow Movement**: Enable or disable warehouse movements.
- **Allow Output**: Enable or disable production output posting.

## Configure grade conditions

You can configure grades at the field and template levels. Configure grates at the template-level when you have:

- Different acceptance criteria for same measurement.
- Template-specific quality standards.
- Customer-specific requirements.

### Field-level grade configuration

You can configure default grade conditions for specific measurement fields.

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspector Fields**, and then choose the related link.
2. Select the field to configure.
3. On the **Grade Conditions** FastTab, configure conditions for the passing grade. To learn more about grade conditions, go to [Grade condition syntax](#grade-condition-syntax).

### Grade condition syntax

The following are examples of number field conditions:

- `20..24`: Range from 20 to 24
- `>=20`: Greater than or equal to 20
- `<>0`: Not equal to zero
- `10|20|30`: Equals 10, 20, or 30

The following are examples of text field conditions:

- `PASS|GOOD|OK`: Matches any of these values
- `<>""`: Not blank
- `A*`: Starts with "A"

The following are examples of date field conditions:

- `TODAY..TODAY+30D`: Today through 30 days from today
- `>=01/01/2024`: On or after specific date

### Template-level grade configuration

Override field defaults for specific template requirements:

1. [!INCLUDE [open-search](includes/open-search.md)], enter **Quality Inspection Templates**, and then choose the related link.
2. Edit the template.
3. Select the field to modify.
4. Configure conditions for the passing grade.

## Promote grades for better visibility

Promoting grates has the following benefits:

- They stand out in field configuration screens.
- They display inline when you configure templates.
- They display prominently when you run tests.
- They're featured in reports and certificates of analysis.

The following are examples of grates that are often promoted:

- **PASS**: Primary success indicator
- **FAIL**: Primary failure indicator
- Other customer-critical grades

### Effects of grade promotion

**Field configuration**:

- Extra columns for promoted grade conditions.
- Inline editing of promoted grade criteria.
- Quick access to most important conditions.

**Template configuration**:

- Promoted grades are editable inline.
- Replaces the traditional **Acceptable Values** field.
- Streamlines template set-up.

**Test execution**:

- Promoted grade conditions are visible during testing.
- Quick reference for inspectors.
- Reduced errors in test completion.

**Reporting**:

- **Certificate of Analysis** shows promoted grades.
- Quality reports highlight promoted results.
- Executive dashboards focus on key grades.

### Configure grade promotion

1. [!INCLUDE [prod_short](includes/prod_short.md)], enter **Quality Inspection Grades**, and then select the related link.
2. Choose the **Edit List** action.
3. Under **Grade Visibility**, turn on the **Promoted** toggle for important grades.
4. The first 10 promoted grades show in a descending order of priority.

## Advanced grade configurations

Quality management lets you add nuance to your quality inspection grades.

### Set up multiple passing grades

To allow for different levels of product quality, you can set up more than one grade that you consider as passing for your tests. The following are some examples:

- **EXCELLENT** (Priority 10): Premium quality standards
- **GOOD** (Priority 9): Standard quality standards  
- **ACCEPTABLE** (Priority 8): Minimum acceptable quality
- **FAIL** (Priority 1): Below minimum standards

The following are some examples of grade conditions for dimension measurement:

- **EXCELLENT**: 99.9..100.1 (tight tolerance)
- **GOOD**: 99.5..100.5 (standard tolerance)
- **ACCEPTABLE**: 99.0..101.0 (loose tolerance)
- **FAIL**: <>0 (any value outside acceptable range)

### Set up multiple failing grades

To allow for different severity levels of defects, you can set up more than one grade that you consider as failing for your tests. The following are some examples:

- **CRITICAL** (Priority 1): Safety or regulatory failure
- **MAJOR** (Priority 2): Functional failure
- **MINOR** (Priority 3): Cosmetic or minor defect
- **PASS** (Priority 10): Acceptable quality

The following are some examples for business process integration. To learn more about business process integration, go to [Workflow Integration](#workflow-integration).

- **CRITICAL**: Immediate recall, supplier notification
- **MAJOR**: Quarantine, rework evaluation
- **MINOR**: Conditional release, customer notification

### Set up conditional and gray state grades

You can set up conditional, or gray state, grades for items that require extra evaluation. The following are some examples:

- **UNDER_REVIEW** (Priority 5): Requires management decision.
- **CONDITIONAL** (Priority 6): Passes with limitations.
- **RETEST** (Priority 4): Requires more testing.

## Integrate with workflows

You can integrate grates with workflows so that grades trigger different workflow responses. To learn more about workflows, go to [Create workflows to connect tasks in business processes](across-how-to-create-workflows.md).

The following examples are workflow responses that specific grades might trigger:

- **FAIL** grade blocks the lot and creates a negative adjustment.
- **CRITICAL** grade immediately notifies the supplier.
- **RETEST** grade creates another test and schedules inspection.

### Document control integration

Grades control transaction permissions:

**Sales integration**:

- **PASS** grades allow sales shipments.
- **FAIL** grades block sales shipments.
- **CONDITIONAL** grades require approval.

**Production integration**:

- **PASS** grades allow consumption
- **FAIL** grades block material usage
- **UNDER_REVIEW** grades require supervisor approval

### Reporting and analytics

**Grade-based reporting**:

- Quality scorecards by grade distribution
- Trend analysis of grade patterns
- Vendor performance by grade outcomes
- Customer satisfaction correlation with grades

## Best practices for grade configuration

This section describes good design principles to consider when you set up your grades.

**Keep it simple**:

- Start with basic pass, fail, and in progress grades.
- Add complexity only when the business value is clear.
- Ensure that users understand the meanings of your grades

**Business alignment**:

- Align grades with business processes.
- Match grades to decision points.
- Consider customer and supplier perspectives.

**Consistent logic**:

- Use consistent condition syntax across fields.
- Maintain logical orders of priority.
- Document your grade definitions and how to use them.

### Change management

**Grade condition updates**:

- Understand that changes don't affect existing tests.
- Plan updates to happen during periods of low-activity.
- Communicate your changes to the quality team.

**Template migration**:

- Test grade changes on noncritical templates first..
- Provide training on the meanings of new grades.
- Monitor effect on quality processes.

### Performance considerations

The following are things to consider related to grade complexity:

- Complex conditions can affect test performance.
- Limit the number of active grades to business needs.
- Regularly clean up unused grades.

## Troubleshooting grades

The following sections describe typical issues and suggest solutions.

### Tests don't calculate the expected grades

- Review grade condition syntax.
- Check the order of priority.
- Verify the condition inheritance from fields to the template.

### Grades aren't available in templates

- Check your settings for grade copy behavior.
- Verify that the grade isn't set to **Do Not Copy**.
- Manually add the grade to the template, if needed.

### My workflow doesn't start

- Confirm that the workflow condition exactly matches the grade code.
- Check the grade code spelling and case sensitivity.
- Review the workflow activation status.

## Validate grades

The following are ways to test your grade logic:

- Use the **Value to Test** feature in grade configuration.
- Test your boundary conditions and edge cases.
- Validate grade calculations with sample data.

The following are ways to test your process:

- Create test scenarios for each grade outcome.
- Verify business process responses to grades.
- Confirm that your reports display grades correctly.

## Related information

[Creating Quality Inspection Templates](qms-quality-templates.md)  
[Lot Blocking and Unblocking](qms-lot-blocking-unblocking.md)  
[Configuring Workflows](qms-quality-workflows.md)  
[Quality Management Setup and Configuration](qms-setup.md)  
[Quality Management Overview](qms-overview.md)