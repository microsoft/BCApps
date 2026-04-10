// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

page 8892 "Email Retry Detail"
{
    PageType = List;
    Caption = 'Email Attempt Detail';
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Email Retry";
    Permissions = tabledata "Email Retry" = r;
    RefreshOnActivate = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(RetryDetail)
            {
                field("Retry No."; Rec."Retry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Attempt No.';
                    ToolTip = 'Specifies how many times the email has been attempted.';
                }
                field("Status"; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the email retry.';
                }
                field("Date Sending"; Rec."Date Sending")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the email was sent.';
                }
                field("Date Failed"; Rec."Date Failed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the email was processed.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if the email retry failed.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(ShowError)
            {
                ApplicationArea = All;
                Image = Error;
                Caption = 'Show Error';
                ToolTip = 'Show Error.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = FailedStatus;

                trigger OnAction()
                begin
                    Message(Rec."Error Message");
                end;
            }

            action(ShowErrorCallStack)
            {
                ApplicationArea = All;
                Image = ShowList;
                Caption = 'Investigate Error';
                ToolTip = 'View technical details about the error callstack to troubleshoot email errors.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = FailedStatus;

                trigger OnAction()
                var
                    EmailImpl: Codeunit "Email Impl";
                begin
                    Message(EmailImpl.FindErrorCallStackWithMsgIDAndRetryNo(Rec."Message Id", Rec."Retry No."));
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FailedStatus := Rec.Status = Rec.Status::Failed;
    end;

    var
        FailedStatus: Boolean;
}
