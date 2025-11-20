// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

table 5634 "Insurance Journal Batch"
{
    Caption = 'Insurance Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Insurance Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Insurance Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                if "Reason Code" <> xRec."Reason Code" then begin
                    InsuranceJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    InsuranceJnlLine.SetRange("Journal Batch Name", Name);
                    InsuranceJnlLine.ModifyAll("Reason Code", "Reason Code");
                    Modify();
                end;
            end;
        }
        field(5; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("No. Series" <> '') and ("No. Series" = "Posting No. Series") then
                    Validate("Posting No. Series", '');
            end;
        }
        field(6; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text000, "Posting No. Series"));
                InsuranceJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                InsuranceJnlLine.SetRange("Journal Batch Name", Name);
                InsuranceJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
                Modify();
            end;
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
        InsuranceJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        InsuranceJnlLine.SetRange("Journal Batch Name", Name);
        InsuranceJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        InsuranceJnlTempl.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        InsuranceJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        InsuranceJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while InsuranceJnlLine.FindFirst() do
            InsuranceJnlLine.Rename("Journal Template Name", Name, InsuranceJnlLine."Line No.");
    end;

    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlLine: Record "Insurance Journal Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewBatch()
    begin
        InsuranceJnlTempl.Get("Journal Template Name");
        "No. Series" := InsuranceJnlTempl."No. Series";
        "Posting No. Series" := InsuranceJnlTempl."Posting No. Series";
        "Reason Code" := InsuranceJnlTempl."Reason Code";
    end;
}

