// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

table 5623 "FA Reclass. Journal Batch"
{
    Caption = 'FA Reclass. Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "FA Reclass. Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "FA Reclass. Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the journal batch you are creating.';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the journal batch that you are creating.';
        }
        field(40; "No. of Lines"; Integer)
        {
            CalcFormula = count("FA Reclass. Journal Line" where("Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name)));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of lines in this journal batch.';
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
        FAReclassJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        FAReclassJnlLine.SetRange("Journal Batch Name", Name);
        FAReclassJnlLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        FAReclassJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        FAReclassJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while FAReclassJnlLine.FindFirst() do
            FAReclassJnlLine.Rename("Journal Template Name", Name, FAReclassJnlLine."Line No.");
    end;

    var
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
}

