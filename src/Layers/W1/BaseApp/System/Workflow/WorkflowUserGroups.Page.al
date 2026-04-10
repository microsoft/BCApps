namespace System.Automation;

page 1533 "Workflow User Groups"
{
    ApplicationArea = Suite;
    Caption = 'Workflow User Groups';
    CardPageID = "Workflow User Group";
    PageType = List;
    SourceTable = "Workflow User Group";
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
                    ToolTip = 'Specifies the workflow user group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow user group.';
                }
            }
        }
    }

    actions
    {
    }
}

