#pragma warning disable AA0247
page 26569 "Stat. Report Data Change Log"
{
    Caption = 'Stat. Report Data Change Log';
    Editable = false;
    PageType = List;
    SourceTable = "Stat. Report Data Change Log";

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Date and Time"; Rec."Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time of the statutory report data change log.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new value of the statutory report data change log.';
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the old value of the statutory report data change log.';
                }
            }
        }
    }

    actions
    {
    }
}

