namespace System.Automation;

page 1532 "Workflow User Group Members"
{
    Caption = 'Workflow User Group Members';
    PageType = ListPart;
    SourceTable = "Workflow User Group Member";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Suite;
                    LookupPageID = "Approval User Setup";
                    ToolTip = 'Specifies the name of the workflow user.';
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the order of approvers when an approval workflow involves more than one approver.';
                }
            }
        }
    }

    actions
    {
    }
}

