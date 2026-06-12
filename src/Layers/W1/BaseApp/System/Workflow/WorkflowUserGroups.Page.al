namespace System.Automation;

page 1533 "Workflow User Groups"
{
    ApplicationArea = Suite;
    Caption = 'Workflow User Groups';
    CardPageID = "Workflow User Group";
    PageType = List;
    AboutTitle = 'About Workflow User Groups';
    AboutText = 'Specify where a participant engages in an approval workflow by entering a number in the **Sequence No.** field. For example, you can specify that users engage in a sequential order, such as a chain of approvers. You can also specify a flat list of approvers by entering the same number. In the latter case, only one of the approvers must approve a request.';
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

