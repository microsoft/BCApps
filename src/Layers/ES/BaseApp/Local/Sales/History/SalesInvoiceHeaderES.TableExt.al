// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Customer;

#pragma warning disable AS0088
tableextension 10720 "Sales Invoice Header ES" extends "Sales Invoice Header"
{
    fields
    {
        field(7000001; "Cust. Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust. Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Address is taken from the fields Bill-to Address, Bill-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    var
        CorrInvDoesNotExistErr: Label 'The Corrected Invoice No. does not exist. \Identification fields and values:\Corrected Invoice No. = %1.', Comment = '%1 = number of document';

    [Scope('OnPrem')]
    procedure LookupInvoice(CustNo: Code[20]) Selected: Boolean
    var
        PostedSalesInvoices: Page "Posted Sales Invoices";
    begin
        SetCurrentKey("No.");
        SetRange("Bill-to Customer No.", CustNo);

        PostedSalesInvoices.SetTableView(Rec);
        PostedSalesInvoices.SetRecord(Rec);
        PostedSalesInvoices.LookupMode(true);
        if PostedSalesInvoices.RunModal() = ACTION::LookupOK then begin
            PostedSalesInvoices.GetRecord(Rec);
            Selected := true;
        end;
        Clear(PostedSalesInvoices);
        exit(Selected);
    end;

    [Scope('OnPrem')]
    procedure CheckCorrectedDocumentExist(CustNo: Code[20]; CorrInvNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCorrectedDocumentExist(CustNo, CorrInvNo, IsHandled);
        if IsHandled then
            exit;

        SetRange("Bill-to Customer No.", CustNo);
        SetRange("No.", CorrInvNo);
        if not FindFirst() then
            Error(CorrInvDoesNotExistErr, CorrInvNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCorrectedDocumentExist(CustNo: Code[20]; CorrInvNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}
