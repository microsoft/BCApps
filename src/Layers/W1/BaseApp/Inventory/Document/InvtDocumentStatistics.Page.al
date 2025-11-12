// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

page 6776 "Invt. Document Statistics"
{
    Caption = 'Item Document Statistics';
    Editable = false;
    PageType = Card;
    SourceTable = "Invt. Document Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many pieces of the item are processed.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the net weight of the item. You may need the net weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the gross weight, including the weight of any packaging, of the catalog item.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        ClearAll();

        InvtDocLine.SetRange("Document Type", Rec."Document Type");
        InvtDocLine.SetRange("Document No.", Rec."No.");
        if InvtDocLine.Find('-') then
            repeat
                LineQty := LineQty + InvtDocLine.Quantity;
                TotalNetWeight := TotalNetWeight + (InvtDocLine.Quantity * InvtDocLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (InvtDocLine.Quantity * InvtDocLine."Gross Weight");
                TotalVolume := TotalVolume + (InvtDocLine.Quantity * InvtDocLine."Unit Volume");
                if InvtDocLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(InvtDocLine.Quantity / InvtDocLine."Units per Parcel", 1, '>');
            until InvtDocLine.Next() = 0;
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

