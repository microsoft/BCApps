// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;

page 5440 "Supply What-If Scenarios"
{
    Caption = 'Supply What-If Analysis';
    PageType = Card;
    SourceTable = "Supply What-If Scenario";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number for the what-if analysis.';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        Item: Record Item;
                    begin
                        if Item.Get(Rec."Item No.") then
                            Page.Run(Page::"Item Card", Item);
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for the what-if analysis.';
                    Editable = false;
                }
                field("Original Quantity"; Rec."Original Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the original quantity on the purchase line.';
                    Editable = false;
                    Style = StandardAccent;
                }
                field("What-If Quantity"; Rec."What-If Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the what-if quantity. Change this to see planning impact.';
                    Style = Favorable;
                }
                field("Quantity Change"; QuantityChange)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Change';
                    ToolTip = 'Shows the difference between what-if and original quantity.';
                    Editable = false;
                    StyleExpr = QuantityChangeStyleExpr;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                }
                field("Original Date"; Rec."Original Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the original expected receipt date.';
                    Editable = false;
                }
                field("What-If Date"; Rec."What-If Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the what-if expected receipt date. Change this to see timing impact.';
                }
            }
            part(WhatIfImpacts; "What-If Impacts")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(WhatIf)
            {
                ApplicationArea = All;
                Caption = 'Run What-If Analysis';
                Image = CalculateRegenerativePlan;
                ToolTip = 'Run planning calculation with the what-if scenarios to see planning impact.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    TempWhatIfImpact: Record "What-If Impact" temporary;
                    SupplyWhatIfPlanningEngine: Codeunit "Supply What-If Planning Engine";
                begin
                    SupplyWhatIfPlanningEngine.RunWhatIfAnalysis(Rec, TempWhatIfImpact);
                    CurrPage.WhatIfImpacts.Page.UpdateWhatIfImpacts(TempWhatIfImpact);
                    CurrPage.Update();
                    Error('');
                end;
            }
        }
    }

    var
        QuantityChange: Decimal;
        QuantityChangeStyleExpr: Text;

    trigger OnAfterGetRecord()
    begin
        CalculateQuantityChange();
        SetQuantityChangeStyle();
    end;

    local procedure CalculateQuantityChange()
    begin
        QuantityChange := Rec."What-If Quantity" - Rec."Original Quantity";
    end;

    local procedure SetQuantityChangeStyle()
    begin
        QuantityChangeStyleExpr := 'Standard';
        if QuantityChange > 0.01 then
            QuantityChangeStyleExpr := 'Favorable';
        if QuantityChange < -0.01 then
            QuantityChangeStyleExpr := 'Unfavorable';
    end;

    procedure SetData(var TempSourceScenario: Record "Supply What-If Scenario" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempSourceScenario.FindSet() then
            repeat
                Rec := TempSourceScenario;
                Rec.Insert();
            until TempSourceScenario.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    procedure GetData(var TempTargetScenario: Record "Supply What-If Scenario" temporary)
    begin
        TempTargetScenario.Reset();
        TempTargetScenario.DeleteAll();

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TempTargetScenario := Rec;
                TempTargetScenario.Insert();
            until Rec.Next() = 0;
    end;
}