// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive reminder management functionality for Business Central, enabling organizations to create, issue, and send payment reminders to customers with overdue invoices.
/// Supports configurable reminder terms and levels, interest calculation, additional fees, and automated reminder workflows.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The reminder system uses a document-based architecture with reminder headers containing customer and posting information,
/// reminder lines representing individual overdue entries, and reminder terms/levels defining escalation rules and fee structures.
/// The automation subsystem enables scheduled creation, issuing, and sending of reminders through configurable action groups.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Reminder Creation:</b></term>
/// <description>Create reminder documents manually or via batch processing, suggest overdue entries based on customer ledger data, calculate interest and fees according to reminder level configuration</description>
/// </item>
/// <item>
/// <term><b>Reminder Issuing:</b></term>
/// <description>Validate reminder data and dimensions, post interest and fees to G/L, create issued reminder records, update customer ledger entries with reminder level</description>
/// </item>
/// <item>
/// <term><b>Reminder Sending:</b></term>
/// <description>Generate PDF attachments with customizable text, send emails with level-specific content, track communication history and delivery status</description>
/// </item>
/// <item>
/// <term><b>Reminder Automation:</b></term>
/// <description>Configure action groups with create/issue/send actions, schedule via job queue for recurring execution, monitor progress and handle errors through logging system</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with Customer Ledger for overdue entry identification and interest calculation, General Ledger for fee and interest posting,
/// Finance Charge Terms for interest rate configuration, Currency Management for multi-currency reminders, and Dimension Management for financial reporting.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include <c>OnBeforeIssueReminder</c> for custom pre-issue validation, <c>OnAfterInsertReminderEntry</c> for custom entry processing,
/// <c>OnBeforeReminderRounding</c> for custom rounding logic, and the <c>Reminder Action</c> interface for implementing custom automation actions.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Sales.Customer</c>, <c>Microsoft.Sales.Receivables</c>, <c>Microsoft.Finance.GeneralLedger</c>, <c>Microsoft.Finance.Currency</c><br/>
/// <i>Optional:</i> <c>Microsoft.Sales.FinanceCharge</c>, <c>Microsoft.Finance.Dimension</c>, <c>Microsoft.Foundation.Reporting</c>, <c>System.Threading</c>
/// </para>
/// </remarks>
namespace Microsoft.Sales.Reminder;
