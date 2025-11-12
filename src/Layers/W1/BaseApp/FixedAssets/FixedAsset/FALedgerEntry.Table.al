// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 5601 "FA Ledger Entry"
{
    Caption = 'FA Ledger Entry';
    DrillDownPageID = "FA Ledger Entries";
    LookupPageID = "FA Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry";
        }
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            ToolTip = 'Specifies the number of the related fixed asset.';
            TableRelation = "Fixed Asset";
        }
        field(4; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the entry document type.';
        }
        field(7; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the entry document date.';
        }
        field(8; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number on the entry.';
        }
        field(9; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry.';
        }
        field(11; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(12; "FA Posting Category"; Enum "FA Ledger Posting Category")
        {
            Caption = 'FA Posting Category';
            ToolTip = 'Specifies the posting category assigned to the entry when it was posted.';
        }
        field(13; "FA Posting Type"; Enum "FA Ledger Entry FA Posting Type")
        {
            Caption = 'FA Posting Type';
            ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the entry amount in currency.';
        }
        field(15; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(16; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(17; "Reclassification Entry"; Boolean)
        {
            Caption = 'Reclassification Entry';
            ToolTip = 'Specifies whether the entry was made to reclassify a fixed asset, for example, to change the dimension the fixed asset is linked to.';
        }
        field(18; "Part of Book Value"; Boolean)
        {
            Caption = 'Part of Book Value';
        }
        field(19; "Part of Depreciable Basis"; Boolean)
        {
            Caption = 'Part of Depreciable Basis';
        }
        field(20; "Disposal Calculation Method"; Option)
        {
            Caption = 'Disposal Calculation Method';
            OptionCaption = ' ,Net,Gross';
            OptionMembers = " ",Net,Gross;
        }
        field(21; "Disposal Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Disposal Entry No.';
        }
        field(22; "No. of Depreciation Days"; Integer)
        {
            Caption = 'No. of Depreciation Days';
        }
        field(23; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(24; "FA No./Budgeted FA No."; Code[20])
        {
            Caption = 'FA No./Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(25; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(26; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(27; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            ToolTip = 'Specifies the FA posting group of the related fixed asset transaction.';
            TableRelation = "FA Posting Group";
        }
        field(28; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(29; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(32; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(33; "Depreciation Method"; Enum "FA Depreciation Method")
        {
            Caption = 'Depreciation Method';
            ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';
        }
        field(34; "Depreciation Starting Date"; Date)
        {
            Caption = 'Depreciation Starting Date';
            ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';
        }
        field(35; "Straight-Line %"; Decimal)
        {
            Caption = 'Straight-Line %';
            DecimalPlaces = 1 : 1;
        }
        field(36; "No. of Depreciation Years"; Decimal)
        {
            Caption = 'No. of Depreciation Years';
            DecimalPlaces = 0 : 3;
        }
        field(37; "Fixed Depr. Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Fixed Depr. Amount';
        }
        field(38; "Declining-Balance %"; Decimal)
        {
            Caption = 'Declining-Balance %';
            DecimalPlaces = 1 : 1;
        }
        field(39; "Depreciation Table Code"; Code[10])
        {
            Caption = 'Depreciation Table Code';
            TableRelation = "Depreciation Table Header";
        }
        field(40; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(41; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(43; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(44; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(45; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(46; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(47; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(48; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(49; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(50; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(51; "FA Exchange Rate"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'FA Exchange Rate';
        }
        field(52; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(53; "Result on Disposal"; Option)
        {
            Caption = 'Result on Disposal';
            OptionCaption = ' ,Gain,Loss';
            OptionMembers = " ",Gain,Loss;
        }
        field(54; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(55; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(56; "Canceled from FA No."; Code[20])
        {
            Caption = 'Canceled from FA No.';
            TableRelation = "Fixed Asset";
        }
        field(57; "Depreciation Ending Date"; Date)
        {
            Caption = 'Depreciation Ending Date';
            ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';
        }
        field(58; "Use FA Ledger Check"; Boolean)
        {
            Caption = 'Use FA Ledger Check';
        }
        field(59; "Automatic Entry"; Boolean)
        {
            Caption = 'Automatic Entry';
        }
        field(60; "Depr. Starting Date (Custom 1)"; Date)
        {
            Caption = 'Depr. Starting Date (Custom 1)';
        }
        field(61; "Depr. Ending Date (Custom 1)"; Date)
        {
            Caption = 'Depr. Ending Date (Custom 1)';
        }
        field(62; "Accum. Depr. % (Custom 1)"; Decimal)
        {
            Caption = 'Accum. Depr. % (Custom 1)';
            DecimalPlaces = 1 : 1;
        }
        field(63; "Depr. % this year (Custom 1)"; Decimal)
        {
            Caption = 'Depr. % this year (Custom 1)';
            DecimalPlaces = 1 : 1;
        }
        field(64; "Property Class (Custom 1)"; Option)
        {
            Caption = 'Property Class (Custom 1)';
            OptionCaption = ' ,Personal Property,Real Property';
            OptionMembers = " ","Personal Property","Real Property";
        }
        field(65; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(66; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(67; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(68; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(69; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(70; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(71; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(72; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(73; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(74; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "FA Ledger Entry";
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
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(6210; "Non-Ded. VAT FA Cost"; Boolean)
        {
            Caption = 'Non-Deductible VAT FA Cost';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "FA No.", "Depreciation Book Code", "FA Posting Date")
        {
            SumIndexFields = Amount;
            IncludedFields = Amount;
        }
        key(Key3; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Part of Book Value", "Reclassification Entry")
        {
            SumIndexFields = Amount;
        }
        key(Key4; "FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key5; "FA No.", "Depreciation Book Code", "Part of Depreciable Basis", "FA Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key6; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key7; "Canceled from FA No.", "Depreciation Book Code", "FA Posting Date")
        {
        }
        key(Key8; "Document No.", "Posting Date")
        {
        }
        key(Key9; "G/L Entry No.")
        {
        }
        key(Key10; "Document Type", "Document No.")
        {
        }
        key(Key11; "Transaction No.")
        {
        }
        key(Key12; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Document No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "FA No.", "FA Posting Date", "FA Posting Type", "Document Type")
        {
        }
    }

    var
        FAJnlSetup: Record "FA Journal Setup";
        DimMgt: Codeunit DimensionManagement;
        NextLineNo: Integer;

    [InherentPermissions(PermissionObjectType::TableData, Database::"FA Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure MoveToGenJnl(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        NextLineNo := GenJnlLine."Line No.";
        GenJnlLine."Line No." := 0;
        GenJnlLine.Init();
        IsHandled := false;
        OnMoveToGenJnlLineOnAfterInit(GenJnlLine, Rec, IsHandled);
        if IsHandled then
            exit;
        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
        GenJnlLine."FA Posting Type" := Enum::"Gen. Journal Line FA Posting Type".FromInteger(ConvertPostingType() + 1);
        GenJnlLine."Posting Date" := "Posting Date";
        GenJnlLine."FA Posting Date" := "FA Posting Date";
        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
            GenJnlLine."FA Posting Date" := 0D;
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Fixed Asset");
        GenJnlLine.Validate("Account No.", "FA No.");
        GenJnlLine.Validate("Depreciation Book Code", "Depreciation Book Code");
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine.Validate(Correction, Correction);
        GenJnlLine."Document Type" := "Document Type";
        GenJnlLine."Document No." := "Document No.";
        GenJnlLine."Document Date" := "Document Date";
        GenJnlLine."External Document No." := "External Document No.";
        GenJnlLine.Quantity := Quantity;
        GenJnlLine."No. of Depreciation Days" := "No. of Depreciation Days";
        GenJnlLine."FA Reclassification Entry" := "Reclassification Entry";
        GenJnlLine."Index Entry" := "Index Entry";
        GenJnlLine."Line No." := NextLineNo;
        GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := "Dimension Set ID";

        OnAfterMoveToGenJnlLine(GenJnlLine, Rec);
    end;

    procedure MoveToFAJnl(var FAJnlLine: Record "FA Journal Line")
    var
        IsHandled: Boolean;
    begin
        NextLineNo := FAJnlLine."Line No.";
        FAJnlLine."Line No." := 0;
        FAJnlLine.Init();
        IsHandled := false;
        OnMoveToFAJnlLineOnAfterInit(FAJnlLine, Rec, IsHandled);
        if IsHandled then
            exit;
        FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(ConvertPostingType());
        FAJnlLine."Posting Date" := "Posting Date";
        FAJnlLine."FA Posting Date" := "FA Posting Date";
        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
            FAJnlLine."Posting Date" := 0D;
        FAJnlLine.Validate("FA No.", "FA No.");
        FAJnlLine.Validate("Depreciation Book Code", "Depreciation Book Code");
        FAJnlLine.Validate(Amount, Amount);
        FAJnlLine.Validate(Correction, Correction);
        FAJnlLine.Quantity := Quantity;
        FAJnlLine."Document Type" := "Document Type";
        FAJnlLine."Document No." := "Document No.";
        FAJnlLine."Document Date" := "Document Date";
        FAJnlLine."External Document No." := "External Document No.";
        FAJnlLine."No. of Depreciation Days" := "No. of Depreciation Days";
        FAJnlLine."FA Reclassification Entry" := "Reclassification Entry";
        FAJnlLine."Index Entry" := "Index Entry";
        FAJnlLine."Line No." := NextLineNo;
        FAJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
        FAJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
        FAJnlLine."Dimension Set ID" := "Dimension Set ID";

        OnAfterMoveToFAJnlLine(FAJnlLine, Rec);
    end;

    procedure ConvertPostingType(): Option
    var
        FAJnlLine: Record "FA Journal Line";
    begin
        case "FA Posting Type" of
            "FA Posting Type"::"Acquisition Cost":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Acquisition Cost";
            "FA Posting Type"::Depreciation:
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Depreciation;
            "FA Posting Type"::"Write-Down":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Write-Down";
            "FA Posting Type"::Appreciation:
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Appreciation;
            "FA Posting Type"::"Custom 1":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Custom 1";
            "FA Posting Type"::"Custom 2":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Custom 2";
            "FA Posting Type"::"Proceeds on Disposal":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Disposal;
            "FA Posting Type"::"Salvage Value":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Salvage Value";
            else
                OnAfterConvertPostingTypeElse(FAJnlLine, Rec);
        end;
        exit(FAJnlLine."FA Posting Type".AsInteger());
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
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
    local procedure OnAfterConvertPostingTypeElse(var FAJournalLine: Record "FA Journal Line"; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveToFAJnlLine(var FAJournalLine: Record "FA Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAcquisitionCost(var FALedgerEntry: Record "FA Ledger Entry"; var AcquisitionCost: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveToGenJnlLineOnAfterInit(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveToFAJnlLineOnAfterInit(var FAJournalLine: Record "FA Journal Line"; Rec: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

