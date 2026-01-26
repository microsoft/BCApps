// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

page 1350 "Posted Sales Shipment - Update"
{
    Caption = 'Posted Sales Shipment - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Shipment Header";
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
                    ToolTip = 'Specifies the number of the record.';
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
                    ToolTip = 'Specifies the posting date for the entry.';
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
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for this shipment.';
                }
                field("Additional Notes"; Rec."Additional Notes")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for this shipment.';
                }
                field("Additional Instructions"; Rec."Additional Instructions")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for this shipment.';
                }
                field("TDD Prepared By"; Rec."TDD Prepared By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted sales shipment.';
                }
                field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; Rec."3rd Party Loader No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the ID of the vendor or contact who is responsible for loading the items for this document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Shipment Header - Edit", Rec);
    end;

    var
        xSalesShipmentHeader: Record "Sales Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Shipping Agent Code" <> xSalesShipmentHeader."Shipping Agent Code") or
          (Rec."Package Tracking No." <> xSalesShipmentHeader."Package Tracking No.") or
          (Rec."Shipping Agent Service Code" <> xSalesShipmentHeader."Shipping Agent Service Code") or
          (Rec."Additional Information" <> xSalesShipmentHeader."Additional Information") or
          (Rec."Additional Notes" <> xSalesShipmentHeader."Additional Notes") or
          (Rec."Additional Instructions" <> xSalesShipmentHeader."Additional Instructions") or
          (Rec."TDD Prepared By" <> xSalesShipmentHeader."TDD Prepared By") or
          (Rec."3rd Party Loader Type" <> xSalesShipmentHeader."3rd Party Loader Type") or
          (Rec."3rd Party Loader No." <> xSalesShipmentHeader."3rd Party Loader No.");

        OnAfterRecordChanged(Rec, xSalesShipmentHeader, IsChanged);
    end;

    procedure SetRec(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        Rec := SalesShipmentHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesShipmentHeader: Record "Sales Shipment Header"; xSalesShipmentHeader: Record "Sales Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}

