// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.History;

using Microsoft.Inventory.Transfer;

page 10461 "Posted Transfer Shpt. - Update"
{
    Caption = 'Posted Transfer Shipment - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Transfer Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
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
        xTransferShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Transfer Shpt. Header - Edit", Rec);
    end;

    var
        xTransferShipmentHeader: Record "Transfer Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."CFDI Cancellation Reason Code" <> xTransferShipmentHeader."CFDI Cancellation Reason Code") or
          (Rec."Substitution Document No." <> xTransferShipmentHeader."Substitution Document No.");
    end;

    procedure SetRec(TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        Rec := TransferShipmentHeader;
        Rec.Insert();
    end;
}

