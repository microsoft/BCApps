namespace System.Security.User;

page 9819 "User Setup FactBox"
{
    Caption = 'User Setup';
    Editable = false;
    PageType = CardPart;
    SourceTable = "User Setup";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Allow Posting From"; Rec."Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post to the company.';
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the user is allowed to post to the company.';
                }
                field("Register Time"; Rec."Register Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to register the user''s time usage defined as the time spent from when the user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded.';
                }
                field("Time Sheet Admin."; Rec."Time Sheet Admin.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a user is a time sheet administrator. A time sheet administrator can access any time sheet and then edit, change, or delete it.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.HideExternalUsers();
    end;
}

