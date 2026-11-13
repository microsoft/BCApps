// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.Reporting;
#if not CLEANSCHEMA25
using Microsoft.Purchases.Reports;
#endif
using Microsoft.Purchases.Vendor;

#pragma warning disable AS0088
tableextension 10721 "Purch. Inv. Header ES" extends "Purch. Inv. Header"
{
    fields
    {
        field(10700; "Autoinvoice No."; Code[20])
        {
            Caption = 'Autoinvoice No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7000001; "Vendor Bank Acc. Code"; Code[20])
        {
            Caption = 'Vendor Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Pay-to Vendor No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Pmt. Address".Code where("Vendor No." = field("Pay-to Vendor No."));
            ObsoleteReason = 'Address is taken from the fields Pay-to Address, Pay-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    var
        CorrInvDoesNotExistErr: Label 'The Corrected Invoice No. does not exist. \Identification fields and values:\Corrected Invoice No. = %1.', Comment = '%1 = number of document';

    [Scope('OnPrem')]
    procedure PrintRecordsAutoInv(ShowRequestForm: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        ReportSelection: Record "Report Selections";
    begin
        PurchInvHeader.Copy(Rec);
        ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.AutoInvoice");
        ReportSelection.SetFilter("Report ID", '<>0');
        ReportSelection.Find('-');
        repeat
            REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, PurchInvHeader);
        until ReportSelection.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure LookupInvoice(VendNo: Code[20]) Selected: Boolean
    var
        PostedPurchaseInvoices: Page "Posted Purchase Invoices";
    begin
        SetCurrentKey("No.");
        SetRange("Pay-to Vendor No.", VendNo);

        PostedPurchaseInvoices.SetTableView(Rec);
        PostedPurchaseInvoices.SetRecord(Rec);
        PostedPurchaseInvoices.LookupMode(true);
        if PostedPurchaseInvoices.RunModal() = ACTION::LookupOK then begin
            PostedPurchaseInvoices.GetRecord(Rec);
            Selected := true;
        end;
        Clear(PostedPurchaseInvoices);
        exit(Selected);
    end;

    [Scope('OnPrem')]
    procedure CheckCorrectedDocumentExist(VendNo: Code[20]; CorrInvNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCorrectedDocumentExist(VendNo, CorrInvNo, IsHandled);
        if IsHandled then
            exit;

        SetRange("Pay-to Vendor No.", VendNo);
        SetRange("No.", CorrInvNo);
        if not FindFirst() then
            Error(CorrInvDoesNotExistErr, CorrInvNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCorrectedDocumentExist(VendNo: Code[20]; CorrInvNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}
