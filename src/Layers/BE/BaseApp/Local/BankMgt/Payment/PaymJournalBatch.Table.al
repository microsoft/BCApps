// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.AuditCodes;

table 2000002 "Paym. Journal Batch"
{
    Caption = 'Paym. Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "EB Payment Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Payment Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            InitValue = " ";
            OptionCaption = ' ,,Processed,Posted';
            OptionMembers = " ",,Processed,Posted;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PaymentJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        PaymentJnlLine.SetRange("Journal Batch Name", Name);
        PaymentJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        PaymentJnlTemplate.Get("Journal Template Name");
        "Reason Code" := PaymentJnlTemplate."Reason Code";
    end;

    trigger OnRename()
    begin
        PaymentJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        PaymentJnlLine.SetRange("Journal Batch Name", xRec.Name);
        if PaymentJnlLine.FindSet() then
            repeat
                PaymentJnlLine.Rename("Journal Template Name", Name, PaymentJnlLine."Line No.");
            until (PaymentJnlLine.Next() = 0);
    end;

    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymentJnlLine: Record "Payment Journal Line";
}

