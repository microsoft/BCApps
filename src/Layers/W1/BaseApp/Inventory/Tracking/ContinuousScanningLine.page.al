// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 6533 "Continuous Scanning Line"
{
    PageType = ListPart;
    ApplicationArea = ItemTracking;
    SourceTable = "Tracking Specification";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                Editable = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ToolTip = 'Specifies the serial number associated with the entry.';
                    Visible = (SourceItemTrackingEntryType = "Item Tracking Entry Type"::"Serial No.");
                    Editable = false;
                    ExtendedDatatype = Barcode;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ToolTip = 'Specifies the lot number of the item being handled for the associated document line.';
                    Visible = (SourceItemTrackingEntryType = "Item Tracking Entry Type"::"Lot No.");
                    Editable = false;
                    ExtendedDatatype = Barcode;
                }
                field("Package No."; Rec."Package No.")
                {
                    ToolTip = 'Specifies the package number of the item being handled for the associated document line.';
                    Visible = (SourceItemTrackingEntryType = "Item Tracking Entry Type"::"Package No.");
                    Editable = false;
                    ExtendedDatatype = Barcode;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ToolTip = 'Specifies the quantity on the line expressed in base units of measure.';
                    Editable = false;
                    BlankZero = true;
                }
            }
        }
    }

    var
        TempTrackSpecificationFromSourcePage: Record "Tracking Specification" temporary;
        SourceItemTrackingEntryType: Enum "Item Tracking Entry Type";

    procedure InitContinuousScanningLine(var NewTrackSpecificationFromSourcePage: Record "Tracking Specification" temporary; ItemTrackingEntryType: Enum "Item Tracking Entry Type")
    begin
        TempTrackSpecificationFromSourcePage.Copy(NewTrackSpecificationFromSourcePage, true);
        SourceItemTrackingEntryType := ItemTrackingEntryType;
    end;

    trigger OnOpenPage()
    begin
        Rec.Copy(TempTrackSpecificationFromSourcePage, true);
    end;

    internal procedure GetSumQty(): Decimal
    begin
        Rec.CalcSums("Quantity (Base)");
        exit(Rec."Quantity (Base)");
    end;

    internal procedure CountRecord(): Integer
    begin
        exit(Rec.Count());
    end;
}
