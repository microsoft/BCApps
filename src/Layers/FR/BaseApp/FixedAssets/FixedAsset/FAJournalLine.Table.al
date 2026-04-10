// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

table 5621 "FA Journal Line"
{
    Caption = 'FA Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "FA Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "FA Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                if ("FA No." = '') or ("Depreciation Book Code" = '') then
                    exit;
                FADeprBook.Get("FA No.", "Depreciation Book Code");
                "FA Posting Group" := FADeprBook."FA Posting Group";
            end;
        }
        field(5; "FA Posting Type"; Enum "FA Journal Line FA Posting Type")
        {
            Caption = 'FA Posting Type';
            ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFAPostingType(Rec, IsHandled, CurrFieldNo);
                if not IsHandled then begin
                    if "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" then
                        TestField("Insurance No.", '');
                    if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                        TestField("Maintenance Code", '');
                end;
            end;
        }
        field(6; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            ToolTip = 'Specifies the number of the related fixed asset.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                if "FA No." = '' then begin
                    CreateDimFromDefaultDim();
                    exit;
                end;

                FA.Get("FA No.");
                FA.TestField(Blocked, false);
                FA.TestField(Inactive, false);
                Description := FA.Description;
                if "Depreciation Book Code" = '' then
                    "Depreciation Book Code" := GetFADeprBook("FA No.");
                if "Depreciation Book Code" <> '' then begin
                    FADeprBook.Get("FA No.", "Depreciation Book Code");
                    "FA Posting Group" := FADeprBook."FA Posting Group";
                end;
                OnValidateFANoOnAfterInitFields(Rec);

                CreateDimFromDefaultDim();
            end;
        }
        field(7; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the same date as the FA Posting Date field when the line is posted.';
        }
        field(9; "Document Type"; Enum "FA Journal Line Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the appropriate document type for the amount you want to post.';
        }
        field(10; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies a document number for the journal line.';
        }
        field(12; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the fixed asset.';
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount the journal line consists of.';

            trigger OnValidate()
            var
                Currency: Record Currency;
            begin
                Clear(Currency);
                Currency.InitRoundingPrecision();
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                if ((Amount > 0) and (not Correction)) or
                   ((Amount < 0) and Correction)
                then begin
                    "Debit Amount" := Amount;
                    "Credit Amount" := 0
                end else begin
                    "Debit Amount" := 0;
                    "Credit Amount" := -Amount;
                end;
            end;
        }
        field(15; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent debits.';

            trigger OnValidate()
            begin
                Correction := ("Debit Amount" < 0);
                Amount := "Debit Amount";
                Validate(Amount);
            end;
        }
        field(16; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent credits.';

            trigger OnValidate()
            begin
                Correction := ("Credit Amount" < 0);
                Amount := -"Credit Amount";
                Validate(Amount);
            end;
        }
        field(17; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Salvage Value';
            ToolTip = 'Specifies the estimated residual value of a fixed asset when it can no longer be used.';
        }
        field(18; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(19; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(20; "No. of Depreciation Days"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
            ToolTip = 'Specifies the number of depreciation days if you have selected the Depreciation or Custom 1 option in the FA Posting Type field.';
        }
        field(21; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            ToolTip = 'Specifies if depreciation was calculated until the FA posting date of the line.';
        }
        field(22; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
            ToolTip = 'Specifies if, when this line was posted, the additional acquisition cost posted on the line was depreciated in proportion to the amount by which the fixed asset had already been depreciated.';
        }
        field(24; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(26; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            ToolTip = 'Specifies a maintenance code.';
            TableRelation = Maintenance;

            trigger OnValidate()
            begin
                if "Maintenance Code" <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::Maintenance);
            end;
        }
        field(27; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(28; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(30; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            ToolTip = 'Specifies an insurance code if you have selected the Acquisition Cost option in the FA Posting Type field.';
            TableRelation = Insurance;

            trigger OnValidate()
            begin
                CheckInsuranceFAPostingType();
            end;
        }
        field(31; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            ToolTip = 'Specifies the number of a fixed asset with the Budgeted Asset check box selected. When you post the journal or document line, an additional entry is created for the budgeted fixed asset where the amount has the opposite sign.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            begin
                if "Budgeted FA No." = '' then
                    exit;
                FA.Get("Budgeted FA No.");
                FA.TestField("Budgeted Asset", true);
            end;
        }
        field(32; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            ToolTip = 'Specifies whether the line is to be posted to all depreciation books, using different journal batches and with a check mark in the Part of Duplication List field.';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(33; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            ToolTip = 'Specifies a depreciation book code if you want the journal line to be posted to that depreciation book, as well as to the depreciation book in the Depreciation Book Code field.';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(34; "FA Reclassification Entry"; Boolean)
        {
            Caption = 'FA Reclassification Entry';
            ToolTip = 'Specifies if the entry was generated from a fixed asset reclassification journal.';
        }
        field(35; "FA Error Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Error Entry No.';
            ToolTip = 'Specifies the number of a posted FA ledger entry to mark as an error entry.';
            TableRelation = "FA Ledger Entry";
        }
        field(36; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(37; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(38; "Recurring Method"; Option)
        {
            Caption = 'Recurring Method';
            ToolTip = 'Specifies a recurring method, if you have indicated that the journal is recurring.';
            OptionCaption = ' ,F Fixed,V Variable';
            OptionMembers = " ","F Fixed","V Variable";
        }
        field(39; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
            ToolTip = 'Specifies a recurring frequency if you indicated that the journal is a recurring.';
        }
        field(41; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            ToolTip = 'Specifies the last date on which the recurring journal will be posted.';
        }
        field(42; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
            ToolTip = 'Specifies whether to post an indexation.';
        }
        field(43; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
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
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        FAJnlSetup.SetFAJnlTrailCodes(Rec);

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        FASetup: Record "FA Setup";
        FA: Record "Fixed Asset";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAJnlLine: Record "FA Journal Line";
        FAJnlSetup: Record "FA Journal Setup";
        FADeprBook: Record "FA Depreciation Book";
        DimMgt: Codeunit DimensionManagement;

    procedure ConvertToLedgEntry(var FAJnlLine: Record "FA Journal Line"): Option
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        case FAJnlLine."FA Posting Type" of
            FAJnlLine."FA Posting Type"::"Acquisition Cost":
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Acquisition Cost";
            FAJnlLine."FA Posting Type"::Depreciation:
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Depreciation;
            FAJnlLine."FA Posting Type"::"Write-Down":
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Write-Down";
            FAJnlLine."FA Posting Type"::Appreciation:
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Appreciation;
            FAJnlLine."FA Posting Type"::"Custom 1":
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Custom 1";
            FAJnlLine."FA Posting Type"::"Custom 2":
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Custom 2";
            FAJnlLine."FA Posting Type"::Disposal:
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Proceeds on Disposal";
            FAJnlLine."FA Posting Type"::"Salvage Value":
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Salvage Value";
            FAJnlLine."FA Posting Type"::Derogatory:
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Derogatory;
            FAJnlLine."FA Posting Type"::"Bonus Depreciation":
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Bonus Depreciation";
            else
                OnConvertToLedgEntryCase(FALedgEntry, FAJnlLine);
        end;
        exit(FALedgEntry."FA Posting Type".AsInteger());
    end;

    procedure SetUpNewLine(LastFAJnlLine: Record "FA Journal Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        FAJnlTemplate.Get("Journal Template Name");
        FAJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        FAJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        FAJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if FAJnlLine.FindFirst() then begin
            "FA Posting Date" := LastFAJnlLine."FA Posting Date";
            "Document No." := LastFAJnlLine."Document No.";
        end else begin
            "FA Posting Date" := WorkDate();
            if FAJnlBatch."No. Series" <> '' then
                "Document No." := NoSeries.PeekNextNo(FAJnlBatch."No. Series", "FA Posting Date");
        end;
        "Recurring Method" := LastFAJnlLine."Recurring Method";
        "Source Code" := FAJnlTemplate."Source Code";
        "Reason Code" := FAJnlBatch."Reason Code";
        "Posting No. Series" := FAJnlBatch."Posting No. Series";
        OnAfterSetUpNewLine(Rec, FAJnlTemplate, FAJnlBatch, LastFAJnlLine);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, DefaultDimSource);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        OnAfterCreateDim(Rec, CurrFieldNo, xRec, OldDimSetID, DefaultDimSource);
    end;

    local procedure GetFADeprBook(FANo: Code[20]) DepreciationBookCode: Code[10]
    var
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

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        FAJournalBatch: Record "FA Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                FAJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            FAJournalBatch.SetFilter(Name, BatchFilter);
            FAJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure CheckInsuranceFAPostingType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInsuranceFAPostingType(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Insurance No." <> '' then
            TestField("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Fixed Asset", Rec."FA No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    procedure IsAcquisitionCost(): Boolean
    var
        AcquisitionCost: Boolean;
    begin
        AcquisitionCost := "FA Posting Type" = "FA Posting Type"::"Acquisition Cost";
        OnAfterIsAcquisitionCost(Rec, AcquisitionCost);
        exit(AcquisitionCost);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var FAJournalLine: Record "FA Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var FAJournalLine: Record "FA Journal Line"; var IsHandled: Boolean; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var FAJournalLine: Record "FA Journal Line"; CurrFieldNo: Integer; xFAJournalLine: Record "FA Journal Line"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var FAJournalLine: Record "FA Journal Line"; FAJnlTemplate: Record "FA Journal Template"; FAJnlBatch: Record "FA Journal Batch"; LastFAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FAJournalLine: Record "FA Journal Line"; var xFAJournalLine: Record "FA Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInsuranceFAPostingType(var FAJournalLine: Record "FA Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var FAJournalLine: Record "FA Journal Line"; var xFAJournalLine: Record "FA Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertToLedgEntryCase(var FALedgerEntry: Record "FA Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFANoOnAfterInitFields(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFAPostingType(var FAJournalLine: Record "FA Journal Line"; var IsHandled: Boolean; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAcquisitionCost(var FAJournalLine: Record "FA Journal Line"; var AcquisitionCost: Boolean);
    begin
    end;
}

