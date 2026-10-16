namespace System.Automation;

page 1508 "Workflow Categories"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Categories';
    AboutTitle = 'About Workflow Categories';
    AboutText = 'Define categories to group related workflows, such as sales, purchasing, or finance. Assign a category to a workflow to make it easier to find, filter, and organize workflows and workflow templates.';
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

