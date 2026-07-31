// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 28011 "WHT Sales Post Invoice"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', true, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header")
    begin
        GenJnlLine."WHT Business Posting Group" := SalesHeader."WHT Business Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPostBalancingEntryOnAfterInitNewLine', '', true, false)]
    local procedure OnPostBalancingEntryOnAfterInitNewLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."WHT Business Posting Group" := SalesHeader."WHT Business Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnAfterInitGenJnlLineAmountFieldsFromTotalLines', '', true, false)]
    local procedure OnAfterInitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GenJnlLine.Amount += SalesHeader."WHT Amount";
        GenJnlLine."Source Currency Amount" += SalesHeader."WHT Amount";
        if (SalesHeader."WHT Amount" <> 0) and (SalesHeader."Currency Code" <> '') then
            GenJnlLine."Amount (LCY)" +=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        SalesHeader."Posting Date", SalesHeader."Currency Code", SalesHeader."WHT Amount", SalesHeader."Currency Factor"))
        else
            GenJnlLine."Amount (LCY)" += SalesHeader."WHT Amount";
    end;


}