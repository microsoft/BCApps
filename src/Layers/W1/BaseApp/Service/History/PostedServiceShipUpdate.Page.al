// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 1358 "Posted Service Ship. - Update"
{
    Caption = 'Posted Service Shipment - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Shipment Header";
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
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the code for the shipment method that is associated with the posted service shipment.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the code of the shipping agent for the posted service shipment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xServiceShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ServiceShipmentHeaderEdit: Codeunit "Service Shipment Header - Edit";
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                ServiceShipmentHeaderEdit.ModifyServiceShipment(Rec);
    end;

    var
        xServiceShipmentHeader: Record "Service Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Shipment Method Code" <> xServiceShipmentHeader."Shipment Method Code") or
          (Rec."Shipping Agent Code" <> xServiceShipmentHeader."Shipping Agent Code");

		  OnAfterRecordChanged(Rec, xServiceShipmentHeader, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceShptHeader: Record "Service Shipment Header")
    begin
        Rec := ServiceShptHeader;
        Rec.Insert();
    end;
	
	[IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var ServiceShipmentHeader: Record "Service Shipment Header"; xServiceShipmentHeader: Record "Service Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}

