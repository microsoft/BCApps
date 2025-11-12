// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 6532 "Continuous Item Tracking"
{
    PageType = StandardDialog;
    ApplicationArea = ItemTracking;
    Caption = 'Scan multiple';
    SourceTable = "Tracking Specification";
    SourceTableTemporary = true;
    DataCaptionExpression = '';

    layout
    {
        area(content)
        {
            group("Input Area")
            {
                field("Scanning Area"; LastInput)
                {
                    Caption = 'Input';
                    Editable = true;
                    Lookup = true;
                    ToolTip = 'Specifies the content scanned to input.';

                    trigger OnValidate()
                    begin
                        if ContinuousScanningMode then
                            CurrPage.Close();
                    end;
                }
                field("Available Qty."; AvailableQty)
                {
                    Caption = 'Available Qty.';
                    DecimalPlaces = 0 : 5;
                    Visible = true;
                    Editable = false;
                    ToolTip = 'Specifies the remaining quantity which has not been defined.';
                }
            }
            group("Scan Result")
            {
                Editable = false;
                part("Result"; "Continuous Scanning Line")
                {

                }
            }
        }
    }

    trigger OnOpenPage()
    var
        TempQty: Decimal;
    begin
        Rec.Copy(TempTrackSpecificationFromSourcePage, true);

        CurrPage.Result.Page.InitContinuousScanningLine(Rec, SourceItemTrackingEntryType);

        TempQty := Rec."Quantity (Base)";
        Rec.CalcSums("Quantity (Base)");
        CurrentQty := Rec."Quantity (Base)";
        AvailableQty := TotalQty - CurrentQty;
        Rec."Quantity (Base)" := TempQty;
    end;

    var
        TempTrackSpecificationFromSourcePage: Record "Tracking Specification" temporary;
        SourceItemTrackingEntryType: Enum "Item Tracking Entry Type";
        LastInput: Text;
        ContinuousScanningMode: Boolean;
        TotalQty: Decimal;
        CurrentQty: Decimal;
        AvailableQty: Decimal;

    procedure GetInput(): Text
    begin
        exit(LastInput);
    end;

    internal procedure SetInput(ExtInput: Text)
    begin
        LastInput := ExtInput;
    end;

    internal procedure SetContinuousScanningMode(DestMode: Boolean)
    begin
        ContinuousScanningMode := DestMode;
    end;

    procedure InitContinuousItemTracking(var NewTrackSpecificationFromSourcePage: Record "Tracking Specification" temporary; TotalQtyFromSourcePage: Decimal; ItemTrackingEntryType: Enum "Item Tracking Entry Type"; DestMode: Boolean)
    begin
        TotalQty := TotalQtyFromSourcePage;
        SourceItemTrackingEntryType := ItemTrackingEntryType;
        TempTrackSpecificationFromSourcePage.Copy(NewTrackSpecificationFromSourcePage, true);
        ContinuousScanningMode := DestMode;
    end;
}
