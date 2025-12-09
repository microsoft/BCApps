// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Order Tax Lines (ID 30168).
/// </summary>
page 30168 "Shpfy Order Tax Lines"
{
    Caption = 'Shopify Order Tax Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Fulfillment,Inspect';
    SourceTable = "Shpfy Order Tax Line";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of the tax line.';
                }
                field(Rate; Rec.Rate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rate of the tax line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the tax line.';
                }
                field("Presentment Amount"; Rec."Presentment Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Presentment Amount';
                    ToolTip = 'Specifies the amount of the tax line in presentment currency.';
                    Visible = PresentmentCurrencyVisible;
                }
                field("Rate %"; Rec."Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rate percentage of the tax line.';
                }
                field("Channel Liable"; Rec."Channel Liable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the channel that submitted the tax line is liable for remitting.';
                }
            }
        }
    }

    var
        PresentmentCurrencyVisible: Boolean;

    trigger OnAfterGetRecord()
    begin
        this.SetShowPresentmentCurrencyVisibility();
    end;

    local procedure SetShowPresentmentCurrencyVisibility()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
    begin
        OrderLine.SetRange("Line Id", Rec."Parent Id");
        if not OrderLine.FindFirst() then
            exit;
        if not OrderHeader.Get(OrderLine."Shopify Order Id") then
            exit;

        PresentmentCurrencyVisible := OrderHeader.IsPresentmentCurrencyOrder();
    end;
}
