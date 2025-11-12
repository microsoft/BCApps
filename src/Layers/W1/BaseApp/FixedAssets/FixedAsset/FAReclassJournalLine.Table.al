// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

table 5624 "FA Reclass. Journal Line"
{
    Caption = 'FA Reclass. Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "FA Reclass. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "FA Reclass. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                if "FA No." = '' then
                    exit;
                FA.Get("FA No.");
                FA.TestField(Blocked, false);
                FA.TestField(Inactive, false);
                Description := FA.Description;
                if "Depreciation Book Code" = '' then
                    "Depreciation Book Code" := GetFADeprBook("FA No.");
            end;
        }
        field(5; "New FA No."; Code[20])
        {
            Caption = 'New FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                if "New FA No." = '' then
                    exit;
                FA.Get("New FA No.");
                FA.TestField(Blocked, false);
                FA.TestField(Inactive, false);
            end;
        }
        field(6; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(9; "Reclassify Acq. Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Reclassify Acq. Cost Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Reclassify Acq. Cost %" := 0;
            end;
        }
        field(10; "Reclassify Acq. Cost %"; Decimal)
        {
            Caption = 'Reclassify Acq. Cost %';
            DecimalPlaces = 0 : 8;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Reclassify Acq. Cost Amount" := 0;
            end;
        }
        field(11; "Reclassify Acquisition Cost"; Boolean)
        {
            Caption = 'Reclassify Acquisition Cost';
        }
        field(12; "Reclassify Depreciation"; Boolean)
        {
            Caption = 'Reclassify Depreciation';
        }
        field(13; "Reclassify Write-Down"; Boolean)
        {
            Caption = 'Reclassify Write-Down';
        }
        field(14; "Reclassify Appreciation"; Boolean)
        {
            Caption = 'Reclassify Appreciation';
        }
        field(15; "Reclassify Custom 1"; Boolean)
        {
            Caption = 'Reclassify Custom 1';
        }
        field(16; "Reclassify Custom 2"; Boolean)
        {
            Caption = 'Reclassify Custom 2';
        }
        field(17; "Reclassify Salvage Value"; Boolean)
        {
            Caption = 'Reclassify Salvage Value';
        }
        field(18; "Insert Bal. Account"; Boolean)
        {
            Caption = 'Insert Bal. Account';
        }
        field(19; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(22; "Calc. DB1 Depr. Amount"; Boolean)
        {
            Caption = 'Calc. DB1 Depr. Amount';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "FA Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        FAReclassJnlTempl.Get("Journal Template Name");
        FAReclassJnlBatch.Get("Journal Template Name", "Journal Batch Name");
    end;

    var
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlBatch: Record "FA Reclass. Journal Batch";

    procedure SetUpNewLine(LastFAReclassJnlLine: Record "FA Reclass. Journal Line")
    begin
        "FA Posting Date" := LastFAReclassJnlLine."FA Posting Date";

        OnAfterSetUpNewLine(Rec, LastFAReclassJnlLine);
    end;

    local procedure GetFADeprBook(FANo: Code[20]) DepreciationBookCode: Code[10]
    var
        FADeprBook: Record "FA Depreciation Book";
        DefaultFADeprBook: Record "FA Depreciation Book";
        SetFADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();

        DefaultFADeprBook.SetRange("FA No.", FANo);
        DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);

        SetFADeprBook.SetRange("FA No.", FANo);

        case true of
            SetFADeprBook.Count = 1:
                begin
                    SetFADeprBook.FindFirst();
                    DepreciationBookCode := SetFADeprBook."Depreciation Book Code";
                end;
            DefaultFADeprBook.FindFirst():
                DepreciationBookCode := DefaultFADeprBook."Depreciation Book Code";
            FADeprBook.Get("FA No.", FASetup."Default Depr. Book"):
                DepreciationBookCode := FASetup."Default Depr. Book"
            else
                DepreciationBookCode := '';
        end;
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                FAReclassJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            FAReclassJournalBatch.SetFilter(Name, BatchFilter);
            FAReclassJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; LastFAReclassJournalLine: Record "FA Reclass. Journal Line")
    begin
    end;
}

