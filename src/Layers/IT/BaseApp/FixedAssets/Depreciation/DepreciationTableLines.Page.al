// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

page 5660 "Depreciation Table Lines"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Depreciation Table Line";
    AboutTitle = 'About Depreciation Table Line';
    AboutText = 'In the **Depreciation Table Line**, you specify information about the number of depreciation periods, depreciation percentage to apply to the period and the no. of units produced by the asset during the period.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Enter Period No.';
                    AboutText = 'Specifies the number of the depreciation period.';
                    ToolTip = 'Specifies the number of the depreciation period that this line applies to.';
                }
                field("Period Depreciation %"; Rec."Period Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Enter Period Depreciation %';
                    AboutText = 'Specifies the depreciation percentage to apply to the period for this line.';
                    ToolTip = 'Specifies the depreciation percentage to apply to the period for this line.';

                    trigger OnValidate()
                    begin
                        TotalDeprPercent := CalcDeprPerc(Rec."Depreciation Table Code");
                        CurrPage.Update(true);
                    end;
                }
                field("No. of Units in Period"; Rec."No. of Units in Period")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Enter No. of Units in Period';
                    AboutText = 'Specifies the no. of units produced by the asset during the period to calculate the depreciation.';
                    ToolTip = 'Specifies the units produced by the asset this depreciation table applies to, during the period when this line applies.';
                }
                field("Anticipated %"; Rec."Anticipated %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the anticipated depreciation percentage.';

                    trigger OnValidate()
                    begin
                        TotalDeprPercent := CalcDeprPerc(Rec."Depreciation Table Code");
                        CurrPage.Update(true);
                    end;
                }
                field("Accelerated/Reduced %"; Rec."Accelerated/Reduced %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the accelerated or reduced depreciation percent.';

                    trigger OnValidate()
                    begin
                        TotalDeprPercent := CalcDeprPerc(Rec."Depreciation Table Code");
                        CurrPage.Update(true);
                    end;
                }
            }
            group(DeprPanel)
            {
                Caption = 'Depreciation Information';
                field(TotalDepreciationPct; TotalDeprPercent)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Total Depreciation %';
                    Editable = false;
                    ToolTip = 'Specifies the total depreciation percent as the sum of the percentages for period depreciation, anticipated depreciation, and accelerated/reduced depreciation.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        TotalDeprPercent := CalcDeprPerc(Rec."Depreciation Table Code");
    end;

    trigger OnAfterGetRecord()
    begin
        CalcDeprPerc(Rec."Depreciation Table Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    var
        TotalDeprPercent: Decimal;

    [Scope('OnPrem')]
    procedure CalcDeprPerc(DeprCode: Code[10]) TotDepr: Decimal
    var
        DeprTableLine: Record "Depreciation Table Line";
    begin
        TotDepr := 0;

        DeprTableLine.Reset();
        DeprTableLine.SetRange("Depreciation Table Code", DeprCode);
        if DeprTableLine.Find('-') then
            repeat
                TotDepr += DeprTableLine."Period Depreciation %" +
                  DeprTableLine."Anticipated %" +
                  DeprTableLine."Accelerated/Reduced %";
            until DeprTableLine.Next() = 0;
    end;
}

