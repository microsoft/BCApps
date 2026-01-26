#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 12166 "Posted Service Shpt. - Update"
{
    Caption = 'Posted Service Shpt. - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Shipment Header";
    SourceTableTemporary = true;
    ObsoleteReason = 'Replaced by W1 page PostedServiceShipUpdate';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

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
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
                }
                field("Additional Notes"; Rec."Additional Notes")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for the shipment.';
                }
                field("Additional Instructions"; Rec."Additional Instructions")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for the shipment.';
                }
                field("TDD Prepared By"; Rec."TDD Prepared By")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted service shipment.';
                }
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
                field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; Rec."3rd Party Loader No.")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
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
        ServShipmentHeaderEdit: Codeunit "Service Shipment Header - Edit";
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                ServShipmentHeaderEdit.ModifyServiceShipment(Rec);
    end;

    var
        xServiceShipmentHeader: Record "Service Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Additional Information" <> xServiceShipmentHeader."Additional Information") or
          (Rec."Additional Notes" <> xServiceShipmentHeader."Additional Notes") or
          (Rec."Additional Instructions" <> xServiceShipmentHeader."Additional Instructions") or
          (Rec."TDD Prepared By" <> xServiceShipmentHeader."TDD Prepared By") or
          (Rec."Shipment Method Code" <> xServiceShipmentHeader."Shipment Method Code") or
          (Rec."Shipping Agent Code" <> xServiceShipmentHeader."Shipping Agent Code") or
          (Rec."3rd Party Loader Type" <> xServiceShipmentHeader."3rd Party Loader Type") or
          (Rec."3rd Party Loader No." <> xServiceShipmentHeader."3rd Party Loader No.");

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
#endif
