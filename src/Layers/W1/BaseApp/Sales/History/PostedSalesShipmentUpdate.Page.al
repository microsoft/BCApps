// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Provides editing capabilities for specific fields on posted sales shipments that can be modified after posting.
/// </summary>
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
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Suite;
                    Editable = true;
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
          (Rec."Shipping Agent Service Code" <> xSalesShipmentHeader."Shipping Agent Service Code");

        OnAfterRecordChanged(Rec, xSalesShipmentHeader, IsChanged);
    end;

    /// <summary>
    /// Sets the record for this page to edit.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header to edit.</param>
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

