// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 12111 "WHT Gen. Journal Line IT"
{

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAccountNoOnValidateOnBeforeCreateDim', '', true, false)]
    local procedure OnAccountNoOnValidateOnBeforeCreateDim(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.DeleteTmpWithhSocSec();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterDeleteEvent', '', true, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Gen. Journal Line")
    begin
        Rec.DeleteTmpWithhSocSec();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Document Date', true, false)]
    local procedure DocumentDateOnAfterValidate(var Rec: Record "Gen. Journal Line")
    begin
        Rec.UpdateTmpWithholdingContribution();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeApplyVendEntriesGetRecord', '', true, false)]
    local procedure OnBeforeApplyVendEntriesGetRecord(var Rec: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        Rec.CheckWithholdingContributionChange();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeaderPrepmt', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Fiscal Code" := SalesHeader."Fiscal Code";
        GenJournalLine."Individual Person" := SalesHeader."Individual Person";
        GenJournalLine.Resident := SalesHeader.Resident;
        GenJournalLine."First Name" := SalesHeader."First Name";
        GenJournalLine."Last Name" := SalesHeader."Last Name";
        GenJournalLine."Date of Birth" := SalesHeader."Date of Birth";
        GenJournalLine."Place of Birth" := SalesHeader."Place of Birth";
        GenJournalLine."Tax Representative Type" := GenJournalLine.ConvertSalesTaxRepresentativeTypeToGenJnlLine(SalesHeader."Tax Representative Type");
        GenJournalLine."Tax Representative No." := SalesHeader."Tax Representative No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeaderPrepmt', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmt(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Fiscal Code" := PurchaseHeader."Fiscal Code";
        GenJournalLine."Individual Person" := PurchaseHeader."Individual Person";
        GenJournalLine.Resident := PurchaseHeader.Resident;
        GenJournalLine."First Name" := PurchaseHeader."First Name";
        GenJournalLine."Last Name" := PurchaseHeader."Last Name";
        GenJournalLine."Date of Birth" := PurchaseHeader."Date of Birth";
        GenJournalLine."Place of Birth" := PurchaseHeader."Birth City";
        GenJournalLine."Tax Representative Type" := GenJournalLine.ConvertSalesTaxRepresentativeTypeToGenJnlLine(PurchaseHeader."Tax Representative Type");
        GenJournalLine."Tax Representative No." := PurchaseHeader."Tax Representative No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetCustomerAccount', '', true, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
        GenJournalLine."Individual Person" := Customer."Individual Person";
        GenJournalLine.Resident := Customer.Resident;
        GenJournalLine."Tax Representative Type" := GenJournalLine.ConvertSalesTaxRepresentativeTypeToGenJnlLine(Customer."Tax Representative Type");
        GenJournalLine."Tax Representative No." := Customer."Tax Representative No.";
        GenJournalLine."Fiscal Code" := Customer."Fiscal Code";
        GenJournalLine."VAT Registration No." := Customer."VAT Registration No.";
        GenJournalLine."First Name" := Customer."First Name";
        GenJournalLine."Last Name" := Customer."Last Name";
        GenJournalLine."Date of Birth" := Customer."Date of Birth";
        GenJournalLine."Place of Birth" := Customer."Place of Birth";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetVendorAccount', '', true, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
    begin
        GenJournalLine."Individual Person" := Vendor."Individual Person";
        GenJournalLine.Resident := Vendor.Resident;
        GenJournalLine."Tax Representative Type" := GenJournalLine.ConvertPurchTaxRepresentativeTypeToGenJnlLine(Vendor."Tax Representative Type");
        GenJournalLine."Tax Representative No." := Vendor."Tax Representative No.";
        GenJournalLine."Fiscal Code" := Vendor."Fiscal Code";
        GenJournalLine."VAT Registration No." := Vendor."VAT Registration No.";
        GenJournalLine."First Name" := Vendor."First Name";
        GenJournalLine."Last Name" := Vendor."Last Name";
        GenJournalLine."Date of Birth" := Vendor."Date of Birth";
        GenJournalLine."Place of Birth" := Vendor."Birth City";
    end;
}