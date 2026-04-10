// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Temporary table for previewing G/L entries before posting with same structure as G/L Entry table.
/// Used in posting preview functionality to show expected G/L entries without committing to database.
/// </summary>
/// <remarks>
/// TableType = Temporary. Contains same field structure as G/L Entry table for preview purposes.
/// Used by posting preview processes to simulate G/L entry creation before actual posting.
/// Enables users to verify posting results before committing transactions.
/// </remarks>
table 1570 "G/L Entry Posting Preview"
{
    Caption = 'G/L Entry';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for the preview G/L entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// G/L account number that this preview transaction would affect.
        /// </summary>
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            ToolTip = 'Specifies the number of the account that the entry has been posted to.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Date when the transaction would be posted to the general ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
            ClosingDates = true;
        }
        /// <summary>
        /// Type of document that would originate this G/L entry.
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the Document Type that the entry belongs to.';
        }
        /// <summary>
        /// Document number that would originate this preview G/L entry.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the entry''s Document No.';
        }
        /// <summary>
        /// Description text for the preview G/L entry transaction.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry or record.';
        }
        /// <summary>
        /// Balancing account number for the preview G/L entry when using balanced journal entries.
        /// </summary>
        field(10; "Bal. Account No."; Code[20])
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
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Bal. Account Type" = const(Employee)) Employee;
        }
        /// <summary>
        /// Amount in local currency for the preview G/L entry transaction.
        /// </summary>
        field(17; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the Amount of the entry.';
        }
        /// <summary>
        /// First global dimension code for the preview G/L entry.
        /// </summary>
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Second global dimension code for the preview G/L entry.
        /// </summary>
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// User ID of the person who would create this preview G/L entry.
        /// </summary>
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Source code identifying the journal or process that would create this preview entry.
        /// </summary>
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Indicates whether this preview entry would be created automatically by the system.
        /// </summary>
        field(29; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        /// <summary>
        /// Indicates whether this preview entry would be for a prior fiscal year.
        /// </summary>
        field(30; "Prior-Year Entry"; Boolean)
        {
            Caption = 'Prior-Year Entry';
        }
        /// <summary>
        /// Project number associated with this preview G/L entry for job costing.
        /// </summary>
        field(41; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        /// <summary>
        /// Quantity associated with this preview G/L entry transaction.
        /// </summary>
        field(42; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// VAT amount for this preview G/L entry transaction.
        /// </summary>
        field(43; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
        }
        /// <summary>
        /// Business unit code for this preview G/L entry for consolidation purposes.
        /// </summary>
        field(45; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// Journal batch name that would originate this preview G/L entry.
        /// </summary>
        field(46; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        /// <summary>
        /// Reason code explaining the purpose of this preview G/L entry.
        /// </summary>
        field(47; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// General posting type (Purchase, Sale, Settlement) for this preview G/L entry.
        /// </summary>
        field(48; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            ToolTip = 'Specifies the type of transaction.';
        }
        /// <summary>
        /// General business posting group for this preview G/L entry.
        /// </summary>
        field(49; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for this preview G/L entry.
        /// </summary>
        field(50; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Type of balancing account for this preview G/L entry.
        /// </summary>
        field(51; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
        }
        /// <summary>
        /// Transaction number grouping related preview G/L entries.
        /// </summary>
        field(52; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Debit amount for this preview G/L entry (positive amounts on debit side).
        /// </summary>
        field(53; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent debits.';
        }
        /// <summary>
        /// Credit amount for this preview G/L entry (positive amounts on credit side).
        /// </summary>
        field(54; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent credits.';
        }
        /// <summary>
        /// Document date for this preview G/L entry transaction.
        /// </summary>
        field(55; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        /// <summary>
        /// External document number for this preview G/L entry (e.g., vendor invoice number).
        /// </summary>
        field(56; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Type of source entity for this preview G/L entry (Customer, Vendor, etc.).
        /// </summary>
        field(57; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        /// <summary>
        /// Source entity number for this preview G/L entry based on source type.
        /// </summary>
        field(58; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Source Type" = const(Employee)) Employee;
        }
        /// <summary>
        /// Number series used for automatic numbering of this preview G/L entry.
        /// </summary>
        field(59; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Tax area code for sales tax calculation in this preview G/L entry.
        /// </summary>
        field(60; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether this preview G/L entry is subject to sales tax.
        /// </summary>
        field(61; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Tax group code for sales tax calculation in this preview G/L entry.
        /// </summary>
        field(62; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether this preview G/L entry uses use tax calculation.
        /// </summary>
        field(63; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// VAT business posting group for this preview G/L entry.
        /// </summary>
        field(64; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for this preview G/L entry.
        /// </summary>
        field(65; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Amount in additional reporting currency for this preview G/L entry.
        /// </summary>
        field(68; "Additional-Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            ToolTip = 'Specifies the general ledger entry that is posted if you post in an additional reporting currency.';
        }
        /// <summary>
        /// Debit amount in additional reporting currency for this preview G/L entry.
        /// </summary>
        field(69; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Debit Amount';
        }
        /// <summary>
        /// Credit amount in additional reporting currency for this preview G/L entry.
        /// </summary>
        field(70; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Credit Amount';
        }
        /// <summary>
        /// Dimension set ID for close income statement functionality in this preview entry.
        /// </summary>
        field(71; "Close Income Statement Dim. ID"; Integer)
        {
            Caption = 'Close Income Statement Dim. ID';
        }
        /// <summary>
        /// Intercompany partner code for this preview G/L entry.
        /// </summary>
        field(72; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Indicates whether this preview G/L entry would be reversed.
        /// </summary>
        field(73; Reversed; Boolean)
        {
            Caption = 'Reversed';
            ToolTip = 'Specifies if the entry has been part of a reverse transaction (correction) made by the Reverse function.';
        }
        /// <summary>
        /// Entry number of the reversing entry for this preview G/L entry.
        /// </summary>
        field(74; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// Entry number of the entry being reversed by this preview G/L entry.
        /// </summary>
        field(75; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// G/L account name for this preview entry (FlowField from G/L Account table).
        /// </summary>
        field(76; "G/L Account Name"; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account No.")));
            Caption = 'G/L Account Name';
            ToolTip = 'Specifies the name of the account that the entry has been posted to.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Dimension Set ID linking to the dimension combination for this preview G/L entry.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Third shortcut dimension code for this preview G/L entry (FlowField).
        /// </summary>
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
        /// <summary>
        /// Fourth shortcut dimension code for this preview G/L entry (FlowField).
        /// </summary>
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
        /// <summary>
        /// Fifth shortcut dimension code for this preview G/L entry (FlowField).
        /// </summary>
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
        /// <summary>
        /// Sixth shortcut dimension code for this preview G/L entry (FlowField).
        /// </summary>
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
        /// <summary>
        /// Seventh shortcut dimension code for this preview G/L entry (FlowField).
        /// </summary>
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
        /// <summary>
        /// Eighth shortcut dimension code for this preview G/L entry (FlowField).
        /// </summary>
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

        /// <summary>
        /// Entry number of the last dimension correction made to this preview G/L entry.
        /// </summary>
        field(495; "Last Dim. Correction Entry No."; Integer)
        {
            Caption = 'Last Dim. Correction Entry No.';
            Editable = false;
        }

        /// <summary>
        /// Node identifier for the last dimension correction made to this preview G/L entry.
        /// </summary>
        field(496; "Last Dim. Correction Node"; Integer)
        {
            Caption = 'Last Dim. Correction Node';
            Editable = false;
        }

        /// <summary>
        /// Count of dimension changes made to this preview G/L entry.
        /// </summary>
        field(497; "Dimension Changes Count"; Integer)
        {
            Caption = 'Count of Dimension Changes';
            Editable = false;
        }
        /// <summary>
        /// Indentation level for hierarchical display of this preview G/L entry.
        /// </summary>
        field(1570; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        /// <summary>
        /// Reference to the original G/L entry number for this preview entry.
        /// </summary>
        field(1571; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            MinValue = 0;
        }
        /// <summary>
        /// Production order number associated with this preview G/L entry.
        /// </summary>
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        /// <summary>
        /// Type of fixed asset entry related to this preview G/L entry.
        /// </summary>
        field(5600; "FA Entry Type"; Option)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Entry Type';
            ToolTip = 'Specifies the number of the fixed asset entry.';
            OptionCaption = ' ,Fixed Asset,Maintenance';
            OptionMembers = " ","Fixed Asset",Maintenance;
        }
        /// <summary>
        /// Fixed asset entry number related to this preview G/L entry.
        /// </summary>
        field(5601; "FA Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Entry No.';
            ToolTip = 'Specifies the number of the fixed asset entry.';
            TableRelation = if ("FA Entry Type" = const("Fixed Asset")) "FA Ledger Entry"
            else
            if ("FA Entry Type" = const(Maintenance)) "Maintenance Ledger Entry";
        }
        /// <summary>
        /// Comment text for this preview G/L entry providing additional context.
        /// </summary>
        field(5618; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        /// <summary>
        /// System ID of the G/L account for this preview entry (FlowField).
        /// </summary>
        field(8001; "Account Id"; Guid)
        {
            CalcFormula = lookup("G/L Account".SystemId where("No." = field("G/L Account No.")));
            Caption = 'Account Id';
            FieldClass = FlowField;
            TableRelation = "G/L Account".SystemId;
        }
        /// <summary>
        /// Date and time when this preview G/L entry was last modified.
        /// </summary>
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "G/L Account No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;
        DocumentTxt: Label '%1 %2', Locked = true;

    /// <summary>
    /// Opens the dimensions window to show the dimension set for this preview G/L entry.
    /// </summary>
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo(DocumentTxt, TableCaption(), "Entry No."), 1, 250));
    end;

    /// <summary>
    /// Retrieves the additional reporting currency code from General Ledger Setup.
    /// </summary>
    /// <returns>Code[10]: The additional reporting currency code.</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;
}
