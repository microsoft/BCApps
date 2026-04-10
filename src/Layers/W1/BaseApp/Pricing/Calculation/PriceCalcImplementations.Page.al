// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

page 7028 "Price Calc. Implementations"
{
    Caption = 'Available Implementations';
    PageType = List;
    SourceTable = "Price Calculation Setup";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Implementation; Rec.Implementation)
                {
                    ToolTip = 'The name of the implementation codeunit or extension that will do the price calculation.';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    procedure SetData(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        Rec.Copy(TempPriceCalculationSetup, true);
    end;
}