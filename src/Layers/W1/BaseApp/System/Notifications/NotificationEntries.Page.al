namespace System.Environment.Configuration;

page 1511 "Notification Entries"
{
    ApplicationArea = Suite;
    Caption = 'Notification Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Notification Entry";
    SourceTableView = sorting("Created Date-Time")
                      order(ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the notification entry.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of notification.';
                }
                field("Recipient User ID"; Rec."Recipient User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who received the notification.';
                }
#pragma warning disable AA0100
                field("FORMAT(""Triggered By Record"")"; Format(Rec."Triggered By Record"))
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Triggered By Record';
                    ToolTip = 'Specifies the record that triggered the notification.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the notification was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who created the notification.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an error that relates to the notification entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}

