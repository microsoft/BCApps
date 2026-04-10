namespace System.Automation;

page 1531 "Workflow User Group"
{
    Caption = 'Workflow User Group';
    PageType = Document;
    SourceTable = "Workflow User Group";

    layout
    {
        area(content)
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
            part(Control5; "Workflow User Group Members")
            {
                ApplicationArea = Suite;
                SubPageLink = "Workflow User Group Code" = field(Code);
            }
        }
    }

    actions
    {
    }
}

