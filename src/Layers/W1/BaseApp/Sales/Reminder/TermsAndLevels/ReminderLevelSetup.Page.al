// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 1896 "Reminder Level Setup"
{
    Caption = 'Reminder Level';
    PageType = ListPart;
    SourceTable = "Reminder Level";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    Caption = 'No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    trigger OnAfterLookup(Selected: RecordRef)
                    var
                        ReminderLevel: Record "Reminder Level";
                        ReminderCommunication: Codeunit "Reminder Communication";
                    begin
                        Selected.SetTable(ReminderLevel);
                        LanguagesCustomerCommunications := ReminderCommunication.ExtractAttachmentAndEmailLanguages(Rec);
                    end;
                }
                field("Grace Period"; Rec."Grace Period")
                {
                    Caption = 'Grace Period';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the grace period for this reminder level.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    Caption = 'Due Date Calculation';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that determines how to calculate the due date on the reminder.';
                }
                field("Calculate Interest"; Rec."Calculate Interest")
                {
                    Caption = 'Calculate Interest';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether interest should be calculated on the reminder lines.';
                }
                field("Add. Fee Calculation Type"; Rec."Add. Fee Calculation Type")
                {
                    Caption = 'Add. Fee Calculation Type';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the additional fee is calculated. Fixed: The Additional Fee values on the line on the Reminder Levels page are used. Dynamics Single: The per-line values on the Additional Fee Setup page are used. Accumulated Dynamic: The values on the Additional Fee Setup page are used.';
                    Editable = false;
                }
                field("Customer Communications"; HasCustomerCommunications)
                {
                    Caption = 'Customer Communications';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the reminder level has customer communications. If the reminder level has customer communications, the field is set to Yes; otherwise, it is set to No.';
                    Editable = false;
                    Enabled = false;
                }
            }
            group(LanguagesCustomerCommunicationsGroup)
            {
                ShowCaption = false;
                field("Languages Customer Communications"; LanguagesCustomerCommunications)
                {
                    Caption = 'Languages with customer communications';
                    ToolTip = 'Specifies the languages with customer communications for this reminder level. The list of languages with attachment texts and email texts is displayed in the format Attachments: <list of languages with attachment texts>, Emails: <list of languages with email texts>.';
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    Editable = false;
                    Enabled = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReminderLevelFeeSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reminder Level Fees';
                Image = InsertStartingFee;
                RunObject = Page "Reminder Level Fee Setup";
                RunPageLink = "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "No." = field("No.");
                ToolTip = 'View or edit fees for this reminder level.';
            }
            action(CustomerCommunications)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Communication';
                ToolTip = 'View or edit customer communications for this reminder level. Customer communications include texts added to the reminders document and email texts.';
                Image = Text;
                RunObject = Page "Reminder Level Communication";
                RunPageLink = "Reminder Terms Code" = field("Reminder Terms Code"),
                              "No." = field("No.");
            }
            action(Currencies)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Currencies';
                Image = Currency;
                RunObject = Page "Currencies for Reminder Level";
                RunPageLink = "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "No." = field("No.");
                ToolTip = 'View or edit additional fees in additional currencies.';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ReminderCommunication: Codeunit "Reminder Communication";
    begin
        if IsNullGuid(Rec."Reminder Attachment Text") and IsNullGuid(Rec."Reminder Email Text") then
            HasCustomerCommunications := false
        else
            HasCustomerCommunications := true;

        LanguagesCustomerCommunications := ReminderCommunication.ExtractAttachmentAndEmailLanguages(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    var
        LanguagesCustomerCommunications: Text;
        HasCustomerCommunications: Boolean;
}