// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

table 237 "Job Journal Batch"
{
    Caption = 'Project Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Job Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Job Journal Template";
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
                    JobJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    JobJnlLine.SetRange("Journal Batch Name", Name);
                    JobJnlLine.ModifyAll("Reason Code", "Reason Code");
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
                if "No. Series" <> '' then begin
                    JobJnlTemplate.Get("Journal Template Name");
                    if JobJnlTemplate.Recurring then
                        Error(
                          Text000,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        Validate("Posting No. Series", '');
                end;
            end;
        }
        field(6; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
                JobJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                JobJnlLine.SetRange("Journal Batch Name", Name);
                JobJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
                Modify();
            end;
        }
        field(22; Recurring; Boolean)
        {
            CalcFormula = lookup("Job Journal Template".Recurring where(Name = field("Journal Template Name")));
            Caption = 'Recurring';
            Editable = false;
            FieldClass = FlowField;
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
        JobJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", Name);
        JobJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        JobJnlTemplate.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        JobJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while JobJnlLine.FindFirst() do
            JobJnlLine.Rename("Journal Template Name", Name, JobJnlLine."Line No.");
    end;

    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewBatch()
    begin
        JobJnlTemplate.Get("Journal Template Name");
        "No. Series" := JobJnlTemplate."No. Series";
        "Posting No. Series" := JobJnlTemplate."Posting No. Series";
        "Reason Code" := JobJnlTemplate."Reason Code";
    end;
}
