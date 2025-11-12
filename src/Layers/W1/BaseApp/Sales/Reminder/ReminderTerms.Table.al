// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;

table 292 "Reminder Terms"
{
    Caption = 'Reminder Terms';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Reminder Terms List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
        }
        field(4; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
        }
        field(5; "Max. No. of Reminders"; Integer)
        {
            Caption = 'Max. No. of Reminders';
            MinValue = 0;
        }
        field(6; "Minimum Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Minimum Amount (LCY)';
            MinValue = 0;
        }
        field(7; "Post Add. Fee per Line"; Boolean)
        {
            Caption = 'Post Add. Fee per Line';
        }
        field(8; "Note About Line Fee on Report"; Text[150])
        {
            Caption = 'Note About Line Fee on Report';
        }
        field(20; "Reminder Attachment Text"; Guid)
        {
            Caption = 'Reminder Attachment Text';
            TableRelation = "Reminder Attachment Text".Id;
        }
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

