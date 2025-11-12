// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 838 "Reminder Terms Setup"
{
    Caption = 'Reminder Terms Setup';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Reminder Terms";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    Caption = 'Reminder Terms Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this set of reminder terms.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the reminder terms.';
                }
                field("Max. No. of Reminders"; Rec."Max. No. of Reminders")
                {
                    Caption = 'Maximum Number of Reminders';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum number of reminders that can be created for an invoice.';
                }
                field("Post Interest"; Rec."Post Interest")
                {
                    Caption = 'Post Interest';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to post any interest listed on the reminder to the general ledger and customer accounts.';
                    Importance = Additional;
                }
                field("Post Additional Fee"; Rec."Post Additional Fee")
                {
                    Caption = 'Post Additional Fee';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to post any additional fee listed on the reminder to the general ledger and customer accounts';
                    Importance = Additional;
                }
                field("Post Add. Fee per Line"; Rec."Post Add. Fee per Line")
                {
                    Caption = 'Post Additional Fee per Line';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to post any additional fee listed on the finance charge memo to the general ledger and customer accounts when the memo is issued.';
                    Importance = Additional;
                }
                field("Minimum Amount (LCY)"; Rec."Minimum Amount (LCY)")
                {
                    Caption = 'Minimum Amount (LCY)';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum amount for which a reminder will be created.';
                    Importance = Additional;
                }
                group(LanguagesCustomerCommunicationsGroup)
                {
                    ShowCaption = false;
                    field("Languages Customer Communications"; LanguagesCustomerCommunications)
                    {
                        Caption = 'Languages with customer communications';
                        ToolTip = 'Specifies the languages with customer communications for this reminder. The list of languages with attachment texts and email texts is displayed in the format Attachments: <list of languages with attachment texts>, Emails: <list of languages with email texts>.';
                        ApplicationArea = Basic, Suite;
                        MultiLine = true;
                        Editable = false;
                        Enabled = false;
                    }
                }
            }
            part(ReminderLevelSetup; "Reminder Level Setup")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Reminder Terms Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CustomerCommunication)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Communication';
                ToolTip = 'View or edit customer communications for this reminder. Customer communications include texts added to the reminders document and email texts.';
                Image = Text;
                RunObject = Page "Reminder Term Communication";
                RunPageLink = Code = field(Code);
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(CustomerCommunication_Promoted; CustomerCommunication)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ReminderCommunication: Codeunit "Reminder Communication";
    begin
        LanguagesCustomerCommunications := ReminderCommunication.ExtractAttachmentAndEmailLanguages(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ReminderCommunication: Codeunit "Reminder Communication";
    begin
        exit(not ReminderCommunication.CheckMissMatchBetweenLanguages(Rec));
    end;

    var
        LanguagesCustomerCommunications: Text;
}