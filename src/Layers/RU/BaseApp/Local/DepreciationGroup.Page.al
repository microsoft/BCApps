#pragma warning disable AA0247
page 12489 "Depreciation Group"
{
    ApplicationArea = FixedAssets;
    Caption = 'Depreciation Group';
    PageType = List;
    SourceTable = "Depreciation Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for this depreciation group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the description of the fixed asset depreciation group.';
                }
                field("Tax Depreciation Rate"; Rec."Tax Depreciation Rate")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the tax depreciation rate for a depreciation group.';
                }
                field("Depreciation Factor"; Rec."Depreciation Factor")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the depreciation factor for a depreciation group.';
                }
                field("Depr. Bonus %"; Rec."Depr. Bonus %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an additional depreciation amount on fixed assets that enables you to include capital investments in the expenses of the period.';
                }
            }
        }
    }

    actions
    {
    }
}

