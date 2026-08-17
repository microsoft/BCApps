#pragma warning disable AA0247
page 14920 "Assessed Tax Allowances"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Assessed Tax Allowances';
    PageType = List;
    SourceTable = "Assessed Tax Allowance";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an assessed tax allowance.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of an assessed tax allowance on fixed assets.';
                }
            }
        }
    }

    actions
    {
    }
}

