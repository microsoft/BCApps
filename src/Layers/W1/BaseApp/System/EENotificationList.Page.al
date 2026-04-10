namespace System.Environment.Configuration;

using System.Integration;
page 3301 "EE Notification List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Business Event Notifications';
    PageType = List;
    PopulateAllFields = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "External Event Notification";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Notification Status';
                    ToolTip = 'Specifies the Notification Status.';
                }
                field(LastRetryDateTime; Rec."Last Retry Date Time")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Retry';
                    ToolTip = 'Specifies the last retry.';
                }
                field(RetryCount; Rec."Retry Count")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Retry Count';
                    ToolTip = 'Specifies the retry count.';
                }
                field(NotBefore; Rec."Not Before")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Not Before';
                    ToolTip = 'Specifies the not before date time.';
                }
            }
        }
    }
}