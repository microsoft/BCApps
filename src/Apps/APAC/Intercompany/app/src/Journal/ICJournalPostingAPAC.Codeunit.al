// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 8557 "IC Journal Posting APAC"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnBeforePost', '', false, false)]
    local procedure CheckAdjustmentAppliesTo(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.CheckAdjustmentAppliesto();
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnAfterPost', '', false, false)]
    local procedure CommitAfterPosting()
    begin
        Commit();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calculate GST Settlement", 'OnAfterInitGenJnlLine', '', false, false)]
    local procedure InitSettlementLine(var GenJournalLine: Record "Gen. Journal Line"; IsICPartner: Boolean)
    begin
        if IsICPartner then
            GenJournalLine.Validate("IC Account No.", '');
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calculate GST Settlement", 'OnAfterInitializeGenJournalLineForInterCompany', '', false, false)]
    local procedure InitializeSettlementPartner(var GenJournalLine: Record "Gen. Journal Line"; ICPartnerGLAccount: Code[20]; PartnerCode: Code[20])
    begin
        if GenJournalLine."IC Account Type" = "IC Journal Account Type"::"G/L Account" then
            GenJournalLine.Validate("IC Account No.", ICPartnerGLAccount);
        GenJournalLine."IC Partner Code" := PartnerCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertGenJournalWHT', '', false, false)]
    local procedure InitializeWithholdingTaxPartner(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."IC Partner Code" := PurchaseHeader."Pay-to IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertGenJournalWHT', '', false, false)]
    local procedure InitializeSalesWithholdingTaxPartner(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
    end;
}
