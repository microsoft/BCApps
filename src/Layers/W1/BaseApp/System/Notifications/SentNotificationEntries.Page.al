namespace System.Environment.Configuration;

page 1514 "Sent Notification Entries"
{
    ApplicationArea = Suite;
    Caption = 'Sent Notification Entries';
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Sent Notification Entry";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the sent notification entry.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the sent notification was made, such as by email.';
                }
                field("Recipient User ID"; Rec."Recipient User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who received the sent notification.';
                }
#pragma warning disable AA0100
                field("FORMAT(""Triggered By Record"")"; Format(Rec."Triggered By Record"))
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Triggered By Record';
                    ToolTip = 'Specifies the record that triggered the sent notification.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the sent notification was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who created the notification.';
                }
                field("Sent Date-Time"; Rec."Sent Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time when the notification was sent.';
                }
                field("Notification Method"; Rec."Notification Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the notification was sent by email or as a note.';
                }
                field("Aggregated with Entry"; Rec."Aggregated with Entry")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the other sent approval entry that this approval entry is aggregated with.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ExportContent)
            {
                ApplicationArea = Suite;
                Caption = 'Export Notification Content';
                Image = ExportFile;
                ToolTip = 'Download the notification content to your machine in .htm or .doc format.';

                trigger OnAction()
                begin
                    Rec.ExportContent(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ExportContent_Promoted; ExportContent)
                {
                }
            }
        }
    }
}

