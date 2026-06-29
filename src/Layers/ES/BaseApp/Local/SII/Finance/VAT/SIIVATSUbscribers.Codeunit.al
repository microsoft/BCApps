// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 7000129 "SII VAT Subscribers"
{

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", 'OnAfterCopyFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VATEntry."Do Not Send To SII" := GenJournalLine."Do Not Send To SII";
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Posting Setup", 'OnAfterValidateEvent', 'VAT Calculation Type', false, false)]
    local procedure OnAfterValidate(var Rec: Record "VAT Posting Setup")
    begin
        Rec."One Stop Shop Reporting" := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No Taxable Entry", 'OnUpdateOnAfterSetFilters', '', false, false)]
    local procedure OnUpdateOnAfterSetFilters(var Rec: Record "No Taxable Entry"; NoTaxableEntry: Record "No Taxable Entry")
    begin
        Rec.SetRange("Ignore In SII", NoTaxableEntry."Ignore In SII");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account Type', false, false)]
    local procedure GenJournalLineOnAfterValidateAccountType(var Rec: Record "Gen. Journal Line")
    begin
        Rec.ClearInvCrMemoTypeFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account No.', false, false)]
    local procedure GenJournalLineOnAfterValidateAccountNo(var Rec: Record "Gen. Journal Line")
    begin
        Rec.ClearInvCrMemoTypeFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Bal. Account Type', false, false)]
    local procedure GenJournalLineOnAfterValidateBalAccountType(var Rec: Record "Gen. Journal Line")
    begin
        Rec.ClearInvCrMemoTypeFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeader', '', false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Do Not Send To SII" := PurchaseHeader."Do Not Send To SII";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeader', '', false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Do Not Send To SII" := SalesHeader."Do Not Send To SII";
        GenJournalLine."Issued By Third Party" := SalesHeader."Issued By Third Party";
        GenJournalLine.SetSIIFirstSummaryDocNo(SalesHeader.GetSIIFirstSummaryDocNo());
        GenJournalLine.SetSIILastSummaryDocNo(SalesHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnInsertVATOnAfterCopyVATPostingSetupFields', '', false, false)]
    local procedure OnInsertVATOnAfterCopyVATPostingSetupFields(var VATPostingSetup: Record "VAT Posting Setup"; var VATEntry: Record "VAT Entry")
    begin
        VATEntry."Ignore In SII" := VATPostingSetup."Ignore In SII";
        VATEntry."One Stop Shop Reporting" := VATPostingSetup."One Stop Shop Reporting";
    end;
}