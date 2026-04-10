// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;

/// <summary>
/// Stores reminder terms configurations that define posting rules, fee settings, and minimum amounts for customer reminders.
/// </summary>
table 292 "Reminder Terms"
{
    Caption = 'Reminder Terms';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Reminder Terms List";

    fields
    {
        /// <summary>
        /// Specifies the unique identifier code for the reminder terms.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code to identify this set of reminder terms.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies a description of the reminder terms.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the reminder terms.';
        }
        /// <summary>
        /// Indicates whether interest charges are posted when reminders using these terms are issued.
        /// </summary>
        field(3; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
            ToolTip = 'Specifies whether to post any interest listed on the reminder to the general ledger and customer accounts.';
        }
        /// <summary>
        /// Indicates whether additional fees are posted when reminders using these terms are issued.
        /// </summary>
        field(4; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
            ToolTip = 'Specifies whether to post any additional fee listed on the reminder to the general ledger and customer accounts';
        }
        /// <summary>
        /// Specifies the maximum number of reminders that can be sent for an overdue entry before escalation stops.
        /// </summary>
        field(5; "Max. No. of Reminders"; Integer)
        {
            Caption = 'Max. No. of Reminders';
            ToolTip = 'Specifies the maximum number of reminders that can be created for an invoice.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the minimum outstanding amount in local currency required for a reminder to be generated.
        /// </summary>
        field(6; "Minimum Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Minimum Amount (LCY)';
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether line fees are posted when reminders using these terms are issued.
        /// </summary>
        field(7; "Post Add. Fee per Line"; Boolean)
        {
            Caption = 'Post Add. Fee per Line';
            ToolTip = 'Specifies whether to post any additional fee listed on the finance charge memo to the general ledger and customer accounts when the memo is issued.';
        }
        /// <summary>
        /// Specifies a note about line fees that will appear on printed reminder reports.
        /// </summary>
        field(8; "Note About Line Fee on Report"; Text[150])
        {
            Caption = 'Note About Line Fee on Report';
            ToolTip = 'Specifies that any notes about line fees will be added to the reminder.';
        }
        /// <summary>
        /// Links to the reminder attachment text configuration for PDF documents.
        /// </summary>
        field(20; "Reminder Attachment Text"; Guid)
        {
            Caption = 'Reminder Attachment Text';
            TableRelation = "Reminder Attachment Text".Id;
        }
        /// <summary>
        /// Links to the reminder email text configuration for email communications.
        /// </summary>
        field(21; "Reminder Email Text"; Guid)
        {
            Caption = 'Reminder Email Text';
            TableRelation = "Reminder Email Text".Id;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
        Customer: Record Customer;
    begin
        ReminderLevel.SetRange("Reminder Terms Code", Code);
        ReminderLevel.DeleteAll(true);

        ReminderTermsTranslation.SetRange("Reminder Terms Code", Code);
        ReminderTermsTranslation.DeleteAll(true);

        ReminderAttachmentText.SetRange(Id, "Reminder Attachment Text");
        ReminderAttachmentText.DeleteAll(true);

        ReminderEmailText.SetRange(Id, "Reminder Email Text");
        ReminderEmailText.DeleteAll(true);

        Customer.SetRange("Reminder Terms Code", Code);
        if not Customer.IsEmpty() then
            Customer.ModifyAll("Reminder Terms Code", '');
    end;

    trigger OnRename()
    begin
        ReminderTermsTranslation.SetRange("Reminder Terms Code", xRec.Code);
        while ReminderTermsTranslation.FindFirst() do
            ReminderTermsTranslation.Rename(
              Code, ReminderTermsTranslation."Language Code");

        ReminderLevel.SetRange("Reminder Terms Code", xRec.Code);
        while ReminderLevel.FindFirst() do
            ReminderLevel.Rename(Code, ReminderLevel."No.");
    end;

    var
        ReminderTermsTranslation: Record "Reminder Terms Translation";
        ReminderLevel: Record "Reminder Level";

    /// <summary>
    /// Sets visibility flags for account fields based on which reminder posting options are enabled.
    /// </summary>
    /// <param name="InterestVisible">Returns true if any reminder terms have interest posting enabled.</param>
    /// <param name="AdditionalFeeVisible">Returns true if any reminder terms have additional fee posting enabled.</param>
    /// <param name="AddFeePerLineVisible">Returns true if any reminder terms have per-line fee posting enabled.</param>
    procedure SetAccountVisibility(var InterestVisible: Boolean; var AdditionalFeeVisible: Boolean; var AddFeePerLineVisible: Boolean)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.SetRange("Post Interest", true);
        InterestVisible := not ReminderTerms.IsEmpty();

        ReminderTerms.SetRange("Post Interest");
        ReminderTerms.SetRange("Post Additional Fee", true);
        AdditionalFeeVisible := not ReminderTerms.IsEmpty();

        ReminderTerms.SetRange("Post Additional Fee");
        ReminderTerms.SetRange("Post Add. Fee per Line", true);
        AddFeePerLineVisible := not ReminderTerms.IsEmpty();
    end;
}

