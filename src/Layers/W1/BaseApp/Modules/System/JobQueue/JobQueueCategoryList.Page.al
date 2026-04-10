namespace System.Threading;

page 671 "Job Queue Category List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Job Queue Categories';
    PageType = List;
    SourceTable = "Job Queue Category";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the category of job queue. You can enter a maximum of 10 characters, both numbers and letters.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the job queue category. You can enter a maximum of 30 characters, both numbers and letters.';
                }
            }
        }
    }

    actions
    {
    }
}

