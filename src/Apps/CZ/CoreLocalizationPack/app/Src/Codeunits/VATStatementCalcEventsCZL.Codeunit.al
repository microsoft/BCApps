// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Publishes integration events used to extend VAT statement calculation.
/// </summary>
codeunit 11775 "VAT Statement Calc. Events CZL"
{
    /// <summary>
    /// Raised after filters are set on G/L entries and before opening the General Ledger Entries page from VAT statement line drill-down.
    /// </summary>
    /// <param name="GLEntry">The G/L Entry record with prepared filters that can be adjusted before the page is opened.</param>
    /// <param name="VATStatementLine">The VAT statement line currently being processed.</param>
    /// <param name="VATStmtCalcParametersCZL">The VAT statement calculation parameters for the current run.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnRunGeneralLedgerEntriesOnAfterSetGLEntryFilters(var GLEntry: Record "G/L Entry"; VATStatementLine: Record "VAT Statement Line"; VATStmtCalcParametersCZL: Record "VAT Stmt. Calc. Parameters CZL")
    begin
    end;

    /// <summary>
    /// Raised after filters are set on VAT entries and before opening the VAT Entries page from VAT statement line drill-down.
    /// This event is raised only when VAT report number filtering is not used.
    /// </summary>
    /// <param name="VATEntry">The VAT Entry record with prepared filters that can be adjusted before the page is opened.</param>
    /// <param name="VATStatementLine">The VAT statement line currently being processed.</param>
    /// <param name="VATStmtCalcParametersCZL">The VAT statement calculation parameters for the current run.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnRunVATEntriesOnAfterSetVATEntryFilters(var VATEntry: Record "VAT Entry"; VATStatementLine: Record "VAT Statement Line"; VATStmtCalcParametersCZL: Record "VAT Stmt. Calc. Parameters CZL")
    begin
    end;

    /// <summary>
    /// Raised when drill-down encounters an unsupported VAT statement line type so subscribers can provide custom handling.
    /// </summary>
    /// <param name="VATStatementLine">The VAT statement line that requires custom handling.</param>
    /// <param name="VATStmtCalcParametersCZL">The VAT statement calculation parameters for the current run.</param>
    /// <param name="IsHandled">Set to true when the line type is handled by a subscriber to prevent the default error.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnHandleAnotherLineType(VATStatementLine: Record "VAT Statement Line"; VATStmtCalcParametersCZL: Record "VAT Stmt. Calc. Parameters CZL"; var IsHandled: Boolean)
    begin
    end;
}