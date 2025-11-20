// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

page 6029 "Invt. Order Tracking Lines"
{
    Caption = 'Invt. Order Tracking Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Invt. Order Tracking";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number.';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expiration date.';
                }
                field("Qty. Expected (Base)"; Rec."Qty. Expected (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected base quantity.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnClosePage()
    begin
        TempInvtOrderTracking := Rec;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempInvtOrderTracking.SetView(Rec.GetView());
        TempInvtOrderTracking := Rec;
        if not TempInvtOrderTracking.Find(Which) then
            exit(false);
        Rec := TempInvtOrderTracking;
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        CurrentSteps: Integer;
    begin
        TempInvtOrderTracking := Rec;
        CurrentSteps := TempInvtOrderTracking.Next(Steps);
        if CurrentSteps <> 0 then
            Rec := TempInvtOrderTracking;
        exit(CurrentSteps);
    end;

    var
        TempInvtOrderTracking: Record "Invt. Order Tracking" temporary;

    procedure SetSources(var InvtOrderTracking: Record "Invt. Order Tracking")
    begin
        TempInvtOrderTracking.Reset();
        TempInvtOrderTracking.DeleteAll();
        if InvtOrderTracking.Find('-') then
            repeat
                TempInvtOrderTracking := InvtOrderTracking;
                TempInvtOrderTracking.Insert();
            until InvtOrderTracking.Next() = 0;
    end;
}

