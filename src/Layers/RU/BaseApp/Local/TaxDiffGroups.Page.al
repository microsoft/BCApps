#pragma warning disable AA0247
page 17334 "Tax Diff. Groups"
{
    Caption = 'Tax Diff. Groups';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Diff. Group";

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
                    ToolTip = 'Specifies the deferral code associated with the tax differences group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax differences group.';
                }
                field("Tax Diff. Code"; Rec."Tax Diff. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences code associated with the tax differences group.';
                }
                field("Calculation Type"; Rec."Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculation type associated with the tax differences group.';
                }
            }
        }
    }

    actions
    {
    }
}

