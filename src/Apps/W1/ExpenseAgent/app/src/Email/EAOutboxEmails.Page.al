// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

page 7087 "EA Outbox Emails"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "EA Outbox Email";
    Caption = 'EA Outbox Emails';
    Editable = false;
    SourceTableView = sorting(Id) order(descending);

    layout
    {
        area(Content)
        {
            repeater(Emails)
            {
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies when the outbox email was created.';
                }
                field("Notification Type"; Rec."Notification Type")
                {
                }
                field(Subject; Rec.Subject)
                {
                    ToolTip = 'Specifies the subject of the outbox email.';
                }
                field(ToLine; Rec.ToLine)
                {
                    ToolTip = 'Specifies the recipients of the outbox email.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies whether the outbox email is pending, sent, failed, or rejected.';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ToolTip = 'Specifies how many times delivery has been attempted.';
                }
                field("Correlation Id"; Rec."Correlation Id")
                {
                    Visible = false;
                }
            }
        }
    }
}
