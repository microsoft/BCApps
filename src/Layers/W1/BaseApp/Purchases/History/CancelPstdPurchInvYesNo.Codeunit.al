// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Utilities;

codeunit 1325 "Cancel PstdPurchInv (Yes/No)"
{
    Permissions = TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    begin
        CancelInvoice(Rec);
    end;

    var
        CancelPostedInvoiceQst: Label 'This invoice was posted from a purchase order. To cancel it, a purchase credit memo will be created and posted. The quantities from the original purchase order will be restored, provided the purchase order still exists.\ \Do you want to continue?';
        OpenPostedCreditMemoQst: Label 'A credit memo was successfully created. Do you want to open the posted credit memo?';

    procedure CancelInvoice(var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        IsHandled: Boolean;
    begin
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
        if Confirm(CancelPostedInvoiceQst) then
            if CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader) then
                if Confirm(OpenPostedCreditMemoQst) then begin
                    CancelledDocument.FindPurchCancelledInvoice(PurchInvHeader."No.");
                    PurchCrMemoHdr.Get(CancelledDocument."Cancelled By Doc. No.");
                    IsHandled := false;
                    OnBeforeShowPostedPurchaseCreditMemo(PurchCrMemoHdr, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
                    exit(true);
                end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;
}

