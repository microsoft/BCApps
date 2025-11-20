// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.GeneralLedger.Setup;

page 1351 "Posted Purch. Invoice - Update"
{
    Caption = 'Posted Purch. Invoice - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Purch. Inv. Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posted invoice number.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who shipped the items.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the purchase header was posted.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the payment of the purchase invoice.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                    Visible = IsPaymentMethodCodeVisible;
                }
                field("Creditor No."; Rec."Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the number of the vendor.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Address Code';
                    Editable = true;
                    ToolTip = 'Specifies the address on purchase orders shipped with a drop shipment directly from the vendor to a customer.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xPurchInvHeader := Rec;
        GLSetup.Get();
        IsPaymentMethodCodeVisible := not GLSetup."Hide Payment Method Code";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Purch. Inv. Header - Edit", Rec);
    end;

    var
        xPurchInvHeader: Record "Purch. Inv. Header";
        GLSetup: Record "General Ledger Setup";
        IsPaymentMethodCodeVisible: Boolean;

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
            (Rec."Payment Reference" <> xPurchInvHeader."Payment Reference") or
            (Rec."Payment Method Code" <> xPurchInvHeader."Payment Method Code") or
            (Rec."Creditor No." <> xPurchInvHeader."Creditor No.") or
            (Rec."Ship-to Code" <> xPurchInvHeader."Ship-to Code") or
            (Rec."Posting Description" <> xPurchInvHeader."Posting Description");

        OnAfterRecordChanged(Rec, xRec, IsChanged, xPurchInvHeader);
    end;

    procedure SetRec(PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Rec := PurchInvHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var PurchInvHeader: Record "Purch. Inv. Header"; xPurchInvHeader: Record "Purch. Inv. Header"; var IsChanged: Boolean; xPurchInvHeaderGlobal: Record "Purch. Inv. Header")
    begin
    end;
}

