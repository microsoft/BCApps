// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Sales.History;

page 12165 "Posted Transfer Shpt. - Update"
{
    Caption = 'Posted Transfer Shpt. - Update';
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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
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
                    ToolTip = 'Specifies the posting date for this document.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Transport Reason Code"; Rec."Transport Reason Code")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the transport reason codes in the Transfer Shipment Header table.';
                }
                field("Goods Appearance"; Rec."Goods Appearance")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies a goods appearance code.';
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the gross weight of an item in the Transfer Shipment Header table.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Parcel Units"; Rec."Parcel Units")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the number of packages on a subcontractor transfer shipment order.';
                }
                field(Volume; Rec.Volume)
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the volume of one unit of the item.';
                }
                field("Shipping Notes"; Rec."Shipping Notes")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the product''s shipping notes on a subcontractor transfer order.';
                }
                field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; Rec."3rd Party Loader No.")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
                }
                field("Shipping Starting Date"; Rec."Shipping Starting Date")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the date that the transfer shipment order is expected to ship.';
                }
                field("Shipping Starting Time"; Rec."Shipping Starting Time")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the time that the transfer shipment order is expected to ship.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the tracking number of a package on a subcontractor order.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
                }
                field("Additional Notes"; Rec."Additional Notes")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for the shipment.';
                }
                field("Additional Instructions"; Rec."Additional Instructions")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for the shipment.';
                }
                field("TDD Prepared By"; Rec."TDD Prepared By")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the transfer shipment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xTransferShptHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ShptHeaderEdit: Codeunit "Shipment Header - Edit";
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                ShptHeaderEdit.ModifyTransferShipment(Rec);
    end;

    var
        xTransferShptHeader: Record "Transfer Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Transport Reason Code" <> xTransferShptHeader."Transport Reason Code") or
          (Rec."Goods Appearance" <> xTransferShptHeader."Goods Appearance") or
          (Rec."Gross Weight" <> xTransferShptHeader."Gross Weight") or
          (Rec."Net Weight" <> xTransferShptHeader."Net Weight") or
          (Rec."Parcel Units" <> xTransferShptHeader."Parcel Units") or
          (Rec.Volume <> xTransferShptHeader.Volume) or
          (Rec."Shipping Notes" <> xTransferShptHeader."Shipping Notes") or
          (Rec."3rd Party Loader Type" <> xTransferShptHeader."3rd Party Loader Type") or
          (Rec."3rd Party Loader No." <> xTransferShptHeader."3rd Party Loader No.") or
          (Rec."Shipping Starting Date" <> xTransferShptHeader."Shipping Starting Date") or
          (Rec."Shipping Starting Time" <> xTransferShptHeader."Shipping Starting Time") or
          (Rec."Package Tracking No." <> xTransferShptHeader."Package Tracking No.") or
          (Rec."Additional Information" <> xTransferShptHeader."Additional Information") or
          (Rec."Additional Notes" <> xTransferShptHeader."Additional Notes") or
          (Rec."Additional Instructions" <> xTransferShptHeader."Additional Instructions") or
          (Rec."TDD Prepared By" <> xTransferShptHeader."TDD Prepared By");

        OnAfterRecordChanged(Rec, xTransferShptHeader, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(TransferShptHeader: Record "Transfer Shipment Header")
    begin
        Rec := TransferShptHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var TransferShptHeader: Record "Transfer Shipment Header"; xTransferShptHeader: Record "Transfer Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}

