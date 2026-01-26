// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

page 1354 "Pstd. Sales Cr. Memo - Update"
{
    Caption = 'Posted Sales Cr. Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Cr.Memo Header";
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
                    ToolTip = 'Specifies the posted credit memo number. You cannot change the number because the document has already been posted.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the sell-to address.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Suite;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
            }
            group("Cr. Memo Details")
            {
                Caption = 'Cr. Memo Details';
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
            }
            group(Payment)
            {
                Caption = 'Payment';
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
            }
            group("Electronic Document")
            {
                Caption = 'Electronic Document';
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesCrMemoHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Sales Credit Memo Hdr. - Edit", Rec);
    end;

    var
        xSalesCrMemoHeader: Record "Sales Cr.Memo Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Shipping Agent Code" <> xSalesCrMemoHeader."Shipping Agent Code") or
          (Rec."Shipping Agent Service Code" <> xSalesCrMemoHeader."Shipping Agent Service Code") or
          (Rec."Package Tracking No." <> xSalesCrMemoHeader."Package Tracking No.") or
          (Rec."Company Bank Account Code" <> xSalesCrMemoHeader."Company Bank Account Code") or
          (Rec."CFDI Cancellation Reason Code" <> xSalesCrMemoHeader."CFDI Cancellation Reason Code") or
          (Rec."Substitution Document No." <> xSalesCrMemoHeader."Substitution Document No.") or
          (Rec."Posting Description" <> xSalesCrMemoHeader."Posting Description");

        OnAfterRecordChanged(Rec, xSalesCrMemoHeader, IsChanged);
    end;

    procedure SetRec(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        Rec := SalesCrMemoHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; xSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsChanged: Boolean)
    begin
    end;
}

