// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;

table 2000021 "Domiciliation Journal Batch"
{
    Caption = 'Domiciliation Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Domiciliation Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Domiciliation Journal Template";
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
        field(10; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
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
        DomiciliationJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        DomiciliationJnlLine.SetRange("Journal Batch Name", Name);
        DomiciliationJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        DomiciliationJnlTemplate.Get("Journal Template Name");
        "Reason Code" := DomiciliationJnlTemplate."Reason Code";
    end;

    trigger OnRename()
    begin
        DomiciliationJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        DomiciliationJnlLine.SetRange("Journal Batch Name", xRec.Name);
        if DomiciliationJnlLine.FindFirst() then
            repeat
                DomiciliationJnlLine.Rename("Journal Template Name", Name, DomiciliationJnlLine."Line No.");
            until not DomiciliationJnlLine.FindFirst();
    end;

    var
        DomiciliationJnlTemplate: Record "Domiciliation Journal Template";
        DomiciliationJnlLine: Record "Domiciliation Journal Line";
}

