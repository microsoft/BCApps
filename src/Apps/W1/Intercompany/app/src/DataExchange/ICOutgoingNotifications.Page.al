// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

page 655 "IC Outgoing Notifications"
{
    ApplicationArea = Intercompany;
    Caption = 'IC Outgoing Notifications';
    PageType = List;
    SourceTable = "IC Outgoing Notification";
    Editable = false;
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Notifications)
            {
                field("Operation ID"; Rec."Operation ID")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the unique identifier of the notification.';
                }
                field("Source IC Partner Code"; Rec."Source IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the IC partner that sent this notification.';
                }
                field("Target IC Partner Code"; Rec."Target IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the IC partner that should receive this notification.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the current processing status of this notification.';
                    StyleExpr = StatusStyle;
                }
                field("Notified DateTime"; Rec."Notified DateTime")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies when the notification was sent or last processed.';
                }
                field(ErrorMessage; ErrorMessageText)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Error Message';
                    ToolTip = 'Specifies the error message if the notification failed.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetErrorMessage(ErrorMessageText);
        if Rec.Status in [Rec.Status::Failed, Rec.Status::"Scheduled for deletion failed"] then
            StatusStyle := 'Unfavorable'
        else
            StatusStyle := '';
    end;

    var
        ErrorMessageText: Text;
        StatusStyle: Text;
}
