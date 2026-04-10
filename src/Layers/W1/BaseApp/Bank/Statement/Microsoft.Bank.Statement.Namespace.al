// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides bank statement import, processing, and reconciliation functionality for Business Central.
/// Enables automated bank statement processing with transaction matching and ledger entry application workflows.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The bank statement system uses a data exchange framework approach where bank statements are imported through configurable formats,
/// processed into statement header and line records, and integrated with bank reconciliation workflows for transaction matching.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Statement Import:</b></term>
/// <description>Import bank statement files through data exchange definitions, parse XML/CSV formats, and create statement records</description>
/// </item>
/// <item>
/// <term><b>Transaction Processing:</b></term>
/// <description>Process statement lines, apply transactions to bank account and check ledger entries, and calculate differences</description>
/// </item>
/// <item>
/// <term><b>Reconciliation Management:</b></term>
/// <description>Manage posted statements, support undo operations, and maintain reconciliation history</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with Bank Account management for account configuration, Bank Reconciliation for matching algorithms,
/// and Data Exchange Framework for file import processing. Connects to General Ledger through bank ledger entries.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include import processing events, statement line validation hooks, and application matching customization.
/// Supports custom import formats through data exchange definitions and validation through integration events.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> <c>Microsoft.Bank.BankAccount</c>, <c>Microsoft.Bank.Ledger</c>, <c>System.IO</c><br/>
/// <i>Optional:</i> <c>Microsoft.Bank.Reconciliation</c>, <c>Microsoft.Bank.Check</c>, <c>Microsoft.Finance.GeneralLedger.Journal</c>
/// </para>
/// </remarks>
namespace Microsoft.Bank.Statement;
