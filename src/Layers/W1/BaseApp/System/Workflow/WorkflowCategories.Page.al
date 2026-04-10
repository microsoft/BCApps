namespace System.Automation;

page 1508 "Workflow Categories"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Categories';
    PageType = List;
    SourceTable = "Workflow Category";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the workflow category.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow category.';
                }
            }
        }
    }

    actions
    {
    }
}

