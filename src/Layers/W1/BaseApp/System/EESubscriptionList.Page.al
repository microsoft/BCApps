namespace System.Environment.Configuration;

using System.Integration;

page 3300 "EE Subscription List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Business Event Subscriptions';
    PageType = List;
    PopulateAllFields = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "External Event Subscription";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("ID"; Rec."ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription ID';
                    ToolTip = 'Specifies the ID of the subscription.';
                }
                field(SubscriptionType; Rec."Subscription Type")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Dataverse, Non-Dataverse';
                    Caption = 'Subscription Type';
                    ToolTip = 'Specifies the Subscription Type of the subscription.';

                }
                field(SubscriptionState; Rec."Subscription State")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription State';
                    ToolTip = 'Specifies the Subscription State of the subscription.';
                }
                field(AppId; Rec."App Id")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'App ID';
                    ToolTip = 'Specifies the App ID for the subscription.';
                }
                field(UserID; Rec."User Id")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the User ID of the subscription.';
                }
                field(EventName; Rec."Event Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event Name';
                    ToolTip = 'Specifies the Event Name of the subscription.';
                }
                field(EventVersion; Rec."Event Version")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event Version';
                    ToolTip = 'Specifies the Event Version of the subscription.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the Company Name of the subscription.';
                }
                field(NotificationUrl; Rec."Notification Url")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Notification Url';
                    ToolTip = 'Specifies the Notification Url of the subscription.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(Notification)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Notifications';
                Image = Interaction;
                RunObject = Page "EE Notification List";
                RunPageLink = "Subscription Id" = field(ID);
                ToolTip = 'View the history of Notification sent for the selected record.';
            }
            action(ActivityLogs)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Activity Log';
                Image = InteractionLog;
                RunObject = Page "EE Activity Logs";
                RunPageLink = "Subscription Id" = field(ID);
                ToolTip = 'View the log history for the selected record.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Related';

                actionref(Notification_Promoted; Notification)
                {
                }
                actionref(ActivityLogs_Promoted; ActivityLogs)
                {
                }
            }
        }
    }
}