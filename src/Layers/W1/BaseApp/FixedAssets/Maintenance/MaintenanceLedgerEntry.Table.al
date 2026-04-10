// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

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
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 5625 "Maintenance Ledger Entry"
{
    Caption = 'Maintenance Ledger Entry';
    DrillDownPageID = "Maintenance Ledger Entries";
    LookupPageID = "Maintenance Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Entry No.';
            ToolTip = 'Specifies the G/L number for the entry that was created for this maintenance transaction.';
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
            ToolTip = 'Specifies the document type that the entry belongs to.';
        }
        field(7; "Document Date"; Date)
        {
            Caption = 'Document Date';
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
        field(12; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            ToolTip = 'Specifies the amount of the entry.';
        }
        field(13; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent debits.';
        }
        field(14; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent credits.';
        }
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(16; "FA No./Budgeted FA No."; Code[20])
        {
            Caption = 'FA No./Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(17; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(18; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(19; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(20; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(21; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(24; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(25; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(27; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(28; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(29; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
        }
        field(30; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
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
        field(31; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
        }
        field(32; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(33; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(34; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(35; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(36; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
            TableRelation = "Depreciation Book";
        }
        field(37; "FA Exchange Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'FA Exchange Rate';
        }
        field(38; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
        }
        field(39; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            ToolTip = 'Specifies the maintenance code that the entry is linked to.';
            TableRelation = Maintenance;
        }
        field(40; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(41; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(42; "Automatic Entry"; Boolean)
        {
            Caption = 'Automatic Entry';
        }
        field(43; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(44; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(45; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(46; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(47; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(48; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(49; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(50; Reversed; Boolean)
        {
            Caption = 'Reversed';
            ToolTip = 'Specifies whether the entry has been part of a reverse transaction (correction) made by the Reverse function.';
        }
        field(51; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            ToolTip = 'Specifies the number of the correcting entry.';
            TableRelation = "Maintenance Ledger Entry";
        }
        field(52; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
            TableRelation = "Maintenance Ledger Entry";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
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
        }
        key(Key3; "FA No.", "Depreciation Book Code", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key4; "FA No.", "Depreciation Book Code", "Maintenance Code", "FA Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key5; "FA No.", "Depreciation Book Code", "Maintenance Code", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "G/L Entry No.")
        {
        }
        key(Key8; "Transaction No.")
        {
        }
        key(Key9; "FA No.", "Depreciation Book Code", "Document No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "FA No.", "FA Posting Date")
        {
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;
}

