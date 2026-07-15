page 50012 "CWM Widget Log"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "CWM Widget Log Entry";
    Caption = 'Widget Log Entries';
    Editable = false;

    // Historical log page that opens oldest-first: no descending default sort.
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the log entry.';
                }
                field("Widget No."; Rec."Widget No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the widget the log entry relates to.';
                }
                field("Logged At"; Rec."Logged At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the log entry was created.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the log entry.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the log message.';
                }
            }
        }
    }
}
