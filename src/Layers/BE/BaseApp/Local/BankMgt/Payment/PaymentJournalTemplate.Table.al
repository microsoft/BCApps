// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.AuditCodes;
using System.Reflection;

table 2000000 "Payment Journal Template"
{
    Caption = 'Payment Journal Template';
    DataCaptionFields = Name;
    LookupPageID = "EB Payment Journal Templates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Page));
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                PaymentJnlLine.SetRange("Journal Template Name", Name);
                PaymentJnlLine.ModifyAll("Source Code", "Source Code");
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(15; "Test Report Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            TableRelation = "Bank Account";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PaymJnlBatch.SetRange("Journal Template Name", Name);
        PaymJnlBatch.DeleteAll(true);
        PaymentJnlLine.SetRange("Journal Template Name", Name);
        PaymentJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
        SourceCodeSetup.Get();
        "Source Code" := SourceCodeSetup."Payment Journal";
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
}

