// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.Address;

page 1352 "Posted Return Shpt. - Update"
{
    Caption = 'Posted Return Shpt. - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Return Shipment Header";
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
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                group(ShipToCounty)
                {
                    ShowCaption = false;
                    Visible = IsShipToCountyVisible;
                    field("Ship-to County"; Rec."Ship-to County")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Ship-to County';
                        Editable = true;
                    }
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Ship-to Country/Region';
                    Editable = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ActivateFields();
    end;

    trigger OnOpenPage()
    begin
        xReturnShipmentHeader := Rec;
        ActivateFields();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Return Shipment Header - Edit", Rec);
    end;

    var
        xReturnShipmentHeader: Record "Return Shipment Header";
        FormatAddress: Codeunit "Format Address";
        IsShipToCountyVisible: Boolean;

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
            (Rec."Ship-to County" <> xReturnShipmentHeader."Ship-to County") or
            (Rec."Ship-to Country/Region Code" <> xReturnShipmentHeader."Ship-to Country/Region Code");

        OnAfterRecordChanged(Rec, xRec, IsChanged, xReturnShipmentHeader);
    end;

    procedure SetRec(ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        Rec := ReturnShipmentHeader;
        Rec.Insert();
    end;

    local procedure ActivateFields()
    begin
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var ReturnShipmentHeader: Record "Return Shipment Header"; xReturnShipmentHeader: Record "Return Shipment Header"; var IsChanged: Boolean; xReturnShipmentHeaderGlobal: Record "Return Shipment Header");
    begin
    end;
}
