namespace System.Environment.Configuration;

using System.Integration;
page 3302 "EE Activity Logs"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Business Event Activity Log';
    PageType = List;
    PopulateAllFields = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "External Event Activity Log";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Status';
                    ToolTip = 'Specifies the Activity Status.';
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Creeated at';
                    ToolTip = 'Specifies creation time';
                }
                field(CompanyName; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies Company Name';
                }
                field(ActivityMessage; Rec."Activity Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Message';
                    ToolTip = 'Specifies the Activity Message.';
                }
                field(NotificationUrl; Rec."Notification Url")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Notification Url';
                    ToolTip = 'Specifies the Notification Url.';
                }
            }
        }
    }
}