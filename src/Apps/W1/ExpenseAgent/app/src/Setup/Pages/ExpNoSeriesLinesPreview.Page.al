// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;

page 7073 "Exp. No. Series Lines Preview"
{
    Caption = 'Number series lines';
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    SourceTable = "No. Series Line";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Starting No."; Rec."Starting No.")
                {
                    ToolTip = 'Specifies the starting number in the series.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ToolTip = 'Specifies the ending number in the series.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ToolTip = 'Specifies the increment that is used for each new number in the series.';
                }
                field(Implementation; Rec.Implementation)
                {
                    ToolTip = 'Specifies the implementation used for this series.';
                }
            }
        }
    }

    internal procedure Load(var TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempNoSeriesLine.FindSet() then
            repeat
                Rec := TempNoSeriesLine;
                Rec.Insert();
            until TempNoSeriesLine.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}