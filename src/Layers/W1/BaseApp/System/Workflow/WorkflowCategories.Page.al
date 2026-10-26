namespace System.Automation;

page 1508 "Workflow Categories"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Categories';
    AboutTitle = 'About Workflow Categories';
    AboutText = 'Define categories to group related workflows, such as sales, purchasing, or finance. Use categories to make workflows and workflow templates easier to find, filter, and organize.';
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

