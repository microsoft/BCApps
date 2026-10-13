// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// Read-only list of the emails that currently have more than one copy stored in the Email Inbox.
/// </summary>
page 3326 "PA Email Duplicates"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    Extensible = false;
    Editable = false;
    SourceTable = "PA Email Duplicate Buffer";
    SourceTableTemporary = true;
    Caption = 'Affected Emails';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Sender Address"; Rec."Sender Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sender of the email that was stored more than once.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Subject';
                    ToolTip = 'Specifies the subject of the email that was stored more than once.';
                }
                field("Duplicate Count"; Rec."Duplicate Count")
                {
                    ApplicationArea = All;
                    Caption = 'Copies stored';
                    Style = Attention;
                    ToolTip = 'Specifies how many Email Inbox rows are stored for this email.';
                }
                field("Redundant Count"; Rec."Redundant Count")
                {
                    ApplicationArea = All;
                    Caption = 'Redundant copies';
                    ToolTip = 'Specifies how many copies would be deleted for this email. The oldest copy is always kept.';
                }
                field("Skipped Count"; Rec."Skipped Count")
                {
                    ApplicationArea = All;
                    Caption = 'Copies to skip';
                    ToolTip = 'Specifies how many copies are left untouched (skipped) because their email message is shared with another inbox row, or has been sent or queued to send.';
                }
                field("Oldest Received DateTime"; Rec."Oldest Received DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the received date of the oldest stored copy.';
                }
                field("Newest Received DateTime"; Rec."Newest Received DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the received date of the newest stored copy.';
                }
                field("External Message Id"; Rec."External Message Id")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the external message id shared by all copies of this email.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Re-scan the Email Inbox and rebuild the list of affected emails.';

                trigger OnAction()
                begin
                    Reload();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reload();
    end;

    local procedure Reload()
    var
        Cleanup: Codeunit "PA Email Cleanup";
    begin
        Cleanup.BuildDuplicateGroups(Rec);
        CurrPage.Update(false);
    end;
}
