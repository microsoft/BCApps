// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Manages finance charge memos for customers with overdue payments, including interest calculation and fee assessment.
/// </summary>
/// <remarks>
/// <para><b>Key Capabilities:</b></para>
/// <list type="bullet">
///   <item>Finance charge memo creation and issuance</item>
///   <item>Interest calculation on overdue customer ledger entries</item>
///   <item>Additional fee configuration and application</item>
///   <item>Finance charge terms and conditions management</item>
///   <item>Cancellation of issued finance charge memos</item>
///   <item>Multi-currency finance charge support</item>
/// </list>
/// <para><b>Core Subsystems:</b></para>
/// <list type="bullet">
///   <item><c>Finance Charge Memo Header</c> - Main document header table</item>
///   <item><c>Finance Charge Memo Line</c> - Individual charge lines</item>
///   <item><c>Finance Charge Terms</c> - Interest rates and fee configuration</item>
///   <item><c>Issued Fin. Charge Memo Header</c> - Posted finance charge memos</item>
/// </list>
/// <para><b>Entry Points:</b> Use <c>Finance Charge Memo</c> page for document creation,
/// <c>Finance Charge Terms</c> page for configuration, <c>FinChrgMemo-Issue</c> codeunit for posting.</para>
/// </remarks>
namespace Microsoft.Sales.FinanceCharge;
