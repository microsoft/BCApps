// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

#pragma warning disable AS0088
tableextension 10721 "Purch. Inv. Header ES" extends "Purch. Inv. Header"
{
    var
        CorrInvDoesNotExistErr: Label 'The Corrected Invoice No. does not exist. \Identification fields and values:\Corrected Invoice No. = %1.', Comment = '%1 = number of document';

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
