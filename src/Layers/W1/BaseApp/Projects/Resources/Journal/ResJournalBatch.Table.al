// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

table 236 "Res. Journal Batch"
{
    Caption = 'Res. Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Resource Jnl. Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Res. Journal Template";
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
                    ResJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    ResJnlLine.SetRange("Journal Batch Name", Name);
                    ResJnlLine.ModifyAll("Reason Code", "Reason Code");
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
                    ResJnlTemplate.Get("Journal Template Name");
                    if ResJnlTemplate.Recurring then
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
                ResJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                ResJnlLine.SetRange("Journal Batch Name", Name);
                ResJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
                Modify();
            end;
        }
        field(22; Recurring; Boolean)
        {
            CalcFormula = lookup("Res. Journal Template".Recurring where(Name = field("Journal Template Name")));
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
        ResJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", Name);
        ResJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        ResJnlTemplate.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        ResJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while ResJnlLine.FindFirst() do
            ResJnlLine.Rename("Journal Template Name", Name, ResJnlLine."Line No.");
    end;

    var
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlLine: Record "Res. Journal Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewBatch()
    begin
        ResJnlTemplate.Get("Journal Template Name");
        "No. Series" := ResJnlTemplate."No. Series";
        "Posting No. Series" := ResJnlTemplate."Posting No. Series";
        "Reason Code" := ResJnlTemplate."Reason Code";
    end;
}
