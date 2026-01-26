// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;

/// <summary>
/// Stores all general ledger transactions with complete audit trail and dimensional analysis capabilities.
/// Central table for financial reporting, analysis, and regulatory compliance with integrated VAT and tax tracking.
/// </summary>
/// <remarks>
/// Key relationships: G/L Account, Customer Ledger Entry, Vendor Ledger Entry, VAT Entry, Dimension Set Entry.
/// Extensible via table extensions for additional financial tracking and compliance requirements.
/// Primary keys: Entry No. Secondary keys: G/L Account No. + Posting Date, Transaction No.
/// </remarks>
table 17 "G/L Entry"
{
    Caption = 'G/L Entry';
    DrillDownPageID = "General Ledger Entries";
    LookupPageID = "General Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for the G/L entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// G/L account number that this transaction affects.
        /// </summary>
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                UpdateAccountID();
            end;
        }
        /// <summary>
        /// Date when the transaction was posted to the general ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        /// <summary>
        /// Type of document that originated this G/L entry.
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Number of the document that originated this G/L entry.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                IncomingDocument.HyperlinkToDocument("Document No.", "Posting Date");
            end;
        }
        /// <summary>
        /// Description text for the G/L entry transaction.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Balancing account number used in the original journal entry.
        /// </summary>
        field(10; "Bal. Account No."; Code[20])
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
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Bal. Account Type" = const(Employee)) Employee;
        }
        /// <summary>
        /// Transaction amount in local currency (LCY).
        /// </summary>
        field(17; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Transaction amount in the original currency before conversion to LCY.
        /// </summary>
        field(18; "Source Currency Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// VAT amount in the original currency before conversion to LCY.
        /// </summary>
        field(19; "Source Currency VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source VAT Currency Amount';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Currency code of the original transaction before conversion to LCY.
        /// </summary>
        field(20; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            TableRelation = Currency;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Primary global dimension code for analytical reporting and filtering.
        /// </summary>
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Secondary global dimension code for analytical reporting and filtering.
        /// </summary>
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// User ID of the person who posted this G/L entry.
        /// </summary>
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Source code indicating the journal or process that created this entry.
        /// </summary>
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Indicates whether this entry was created automatically by the system.
        /// </summary>
        field(29; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        /// <summary>
        /// Indicates whether this entry belongs to a prior fiscal year.
        /// </summary>
        field(30; "Prior-Year Entry"; Boolean)
        {
            Caption = 'Prior-Year Entry';
        }
        /// <summary>
        /// Project number associated with this G/L entry for project accounting.
        /// </summary>
        field(41; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        /// <summary>
        /// Quantity associated with this G/L transaction for unit-based reporting.
        /// </summary>
        field(42; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// VAT amount in local currency associated with this G/L entry.
        /// </summary>
        field(43; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
        }
        /// <summary>
        /// Business unit code for multi-company consolidation and reporting.
        /// </summary>
        field(45; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// Journal batch name from the original journal entry.
        /// </summary>
        field(46; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        /// <summary>
        /// Reason code explaining the purpose of this G/L entry.
        /// </summary>
        field(47; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// General posting type indicating purchase, sale, or settlement transaction.
        /// </summary>
        field(48; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        /// <summary>
        /// General business posting group for VAT and tax calculation purposes.
        /// </summary>
        field(49; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for VAT and tax calculation purposes.
        /// </summary>
        field(50; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Type of balancing account used in the original journal entry.
        /// </summary>
        field(51; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        /// <summary>
        /// Transaction number grouping related G/L entries from the same posting.
        /// </summary>
        field(52; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Debit amount in local currency when transaction increases account balance.
        /// </summary>
        field(53; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
        }
        /// <summary>
        /// Credit amount in local currency when transaction decreases account balance.
        /// </summary>
        field(54; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
        }
        /// <summary>
        /// Date of the original source document.
        /// </summary>
        field(55; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        /// <summary>
        /// External document number from vendor or customer invoice.
        /// </summary>
        field(56; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Type of source entity that originated this transaction.
        /// </summary>
        field(57; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        /// <summary>
        /// Number of the source entity (customer, vendor, etc.) that originated this transaction.
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
        /// Number series used for automatic document numbering.
        /// </summary>
        field(59; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Tax area code for sales tax calculation and reporting.
        /// </summary>
        field(60; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether this transaction is subject to tax.
        /// </summary>
        field(61; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Tax group code for sales tax calculation purposes.
        /// </summary>
        field(62; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether this is a use tax transaction.
        /// </summary>
        field(63; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// VAT business posting group for VAT calculation and reporting.
        /// </summary>
        field(64; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for VAT calculation and reporting.
        /// </summary>
        field(65; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Transaction amount in additional reporting currency.
        /// </summary>
        field(68; "Additional-Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
        }
        /// <summary>
        /// Debit amount in additional reporting currency.
        /// </summary>
        field(69; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Debit Amount';
        }
        /// <summary>
        /// Credit amount in additional reporting currency.
        /// </summary>
        field(70; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Credit Amount';
        }
        /// <summary>
        /// Dimension set ID for close income statement process.
        /// </summary>
        field(71; "Close Income Statement Dim. ID"; Integer)
        {
            Caption = 'Close Income Statement Dim. ID';
        }
        /// <summary>
        /// Intercompany partner code for intercompany transactions.
        /// </summary>
        field(72; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Indicates whether this entry has been reversed.
        /// </summary>
        field(73; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        /// <summary>
        /// Entry number of the reversing entry that canceled this transaction.
        /// </summary>
        field(74; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// Entry number of the original entry that was reversed by this transaction.
        /// </summary>
        field(75; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "G/L Entry";
        }
        /// <summary>
        /// Flow field displaying the name of the G/L account.
        /// </summary>
        field(76; "G/L Account Name"; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account No.")));
            Caption = 'G/L Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Journal template name from the original journal entry.
        /// </summary>
        field(78; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        /// <summary>
        /// VAT reporting date for VAT submission and compliance.
        /// </summary>
        field(79; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;
        }
        /// <summary>
        /// Dimension set ID linking to dimension combinations for this entry.
        /// </summary>
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
        /// <summary>
        /// Flow field showing shortcut dimension 3 code for quick dimension analysis.
        /// </summary>
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        /// <summary>
        /// Flow field showing shortcut dimension 4 code for quick dimension analysis.
        /// </summary>
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        /// <summary>
        /// Flow field showing shortcut dimension 5 code for quick dimension analysis.
        /// </summary>
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        /// <summary>
        /// Flow field showing shortcut dimension 6 code for quick dimension analysis.
        /// </summary>
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        /// <summary>
        /// Flow field showing shortcut dimension 7 code for quick dimension analysis.
        /// </summary>
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        /// <summary>
        /// Flow field showing shortcut dimension 8 code for quick dimension analysis.
        /// </summary>
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }

        /// <summary>
        /// Entry number of the last dimension correction applied to this G/L entry.
        /// </summary>
        field(495; "Last Dim. Correction Entry No."; Integer)
        {
            Caption = 'Last Dim. Correction Entry No.';
            Editable = false;
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Node identifier for the last dimension correction tracking.
        /// </summary>
        field(496; "Last Dim. Correction Node"; Integer)
        {
            Caption = 'Last Dim. Correction Node';
            Editable = false;
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Count of dimension changes applied to this G/L entry for audit tracking.
        /// </summary>
        field(497; "Dimension Changes Count"; Integer)
        {
            Caption = 'Count of Dimension Changes';
            Editable = false;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Allocation account number for cost and revenue allocation processes.
        /// </summary>
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// System ID linking to the original allocation journal line.
        /// </summary>
        field(2679; "Alloc. Journal Line SystemId"; Guid)
        {
            Caption = 'Allocation Journal Line SystemId';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Production order number for manufacturing cost tracking.
        /// </summary>
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        /// <summary>
        /// Type of fixed asset entry linked to this G/L entry.
        /// </summary>
        field(5600; "FA Entry Type"; Option)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Entry Type';
            OptionCaption = ' ,Fixed Asset,Maintenance';
            OptionMembers = " ","Fixed Asset",Maintenance;
        }
        /// <summary>
        /// Entry number of the related fixed asset ledger entry.
        /// </summary>
        field(5601; "FA Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Entry No.';
            TableRelation = if ("FA Entry Type" = const("Fixed Asset")) "FA Ledger Entry"
            else
            if ("FA Entry Type" = const(Maintenance)) "Maintenance Ledger Entry";
        }
        /// <summary>
        /// Additional comment text for the G/L entry.
        /// </summary>
        field(5618; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        /// <summary>
        /// Non-deductible VAT amount in local currency.
        /// </summary>
        field(6200; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount';
        }
        /// <summary>
        /// Non-deductible VAT amount in additional reporting currency.
        /// </summary>
        field(6201; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            Caption = 'Non-Deductible VAT Amount ACY';
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
        }
        /// <summary>
        /// Non-deductible VAT amount in source currency.
        /// </summary>
        field(6202; "Src. Curr. Non-Ded. VAT Amount"; Decimal)
        {
            Caption = 'Source Currency Non-Deductible VAT Amount';
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
        }
        /// <summary>
        /// Flow field containing the system ID of the related G/L account.
        /// </summary>
        field(8001; "Account Id"; Guid)
        {
            CalcFormula = lookup("G/L Account".SystemId where("No." = field("G/L Account No.")));
            Caption = 'Account Id';
            FieldClass = FlowField;
            TableRelation = "G/L Account".SystemId;

            trigger OnValidate()
            begin
                UpdateAccountNo();
            end;
        }
        /// <summary>
        /// Timestamp of the last modification to this G/L entry record.
        /// </summary>
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            Editable = false;
        }
#if not CLEANSCHEMA28
        field(3010536; "Amount (FCY)"; Decimal)
        {
            Caption = 'Amount (FCY)';
            ObsoleteReason = 'Replaced by W1 field Source Currency Amount';
#pragma warning disable AS0072
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#pragma warning restore AS0072
        }
#endif
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "G/L Account No.", "Posting Date")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", "VAT Amount", Quantity, "Source Currency Amount", "Source Currency VAT Amount";
            IncludedFields = Amount, "Additional-Currency Amount";
        }
        key(Key3; "G/L Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date", "VAT Reporting Date", "Source Currency Code")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", "VAT Amount", "Source Currency Amount", "Source Currency VAT Amount";
        }
        key(Key4; "G/L Account No.", "Business Unit Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount";
        }
        key(Key5; "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount";
        }
        key(Key6; "Document No.", "Posting Date")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", "VAT Amount";
        }
        key(Key7; "Transaction No.")
        {
        }
        key(Key8; "IC Partner Code")
        {
        }
        key(Key9; "G/L Account No.", "Job No.", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key10; "Posting Date", "G/L Account No.", "Dimension Set ID")
        {
            SumIndexFields = Amount;
        }
        key(Key11; "Gen. Bus. Posting Group", "Gen. Prod. Posting Group")
        {
        }
        key(Key12; "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
        }
        key(Key13; "Dimension Set ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, Amount, "G/L Account No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    /// <summary>
    /// Gets the highest entry number from the G/L Entry table.
    /// </summary>
    /// <returns>The last entry number used</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    /// <summary>
    /// Gets the last entry number and transaction number from the G/L Entry table.
    /// </summary>
    /// <param name="LastEntryNo">Returns the last entry number used</param>
    /// <param name="LastTransactionNo">Returns the last transaction number used</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Entry", 'r')]
    procedure GetLastEntry(var LastEntryNo: Integer; var LastTransactionNo: Integer)
    var
        FindRecordManagement: Codeunit "Find Record Management";
        FieldNoValues: List of [Integer];
    begin
        FieldNoValues.Add(FieldNo("Entry No."));
        FieldNoValues.Add(FieldNo("Transaction No."));
        FindRecordManagement.GetLastEntryIntFieldValues(Rec, FieldNoValues);
        LastEntryNo := FieldNoValues.Get(1);
        LastTransactionNo := FieldNoValues.Get(2);
    end;

#if not CLEAN27
    /// <summary>
    /// Gets the additional reporting currency code from General Ledger Setup.
    /// </summary>
    /// <returns>Additional reporting currency code</returns>
    [Obsolete('use GetAdditionalReportingCurrencyCode instead', '27.0')]
    procedure GetCurrencyCode(): Code[10]
    begin
        exit(GetAdditionalReportingCurrencyCode())
    end;
#endif
    /// <summary>
    /// Opens the Value Entries page showing item ledger entries related to this G/L entry.
    /// </summary>
    procedure ShowValueEntries()
    var
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        ValueEntry: Record "Value Entry";
        TempValueEntry: Record "Value Entry" temporary;
    begin
        OnBeforeShowValueEntries(ValueEntry, GLItemLedgRelation);

        GLItemLedgRelation.SetRange("G/L Entry No.", "Entry No.");
        if GLItemLedgRelation.FindSet() then
            repeat
                ValueEntry.Get(GLItemLedgRelation."Value Entry No.");
                TempValueEntry.Init();
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            until GLItemLedgRelation.Next() = 0;

        PAGE.RunModal(0, TempValueEntry);
    end;

    /// <summary>
    /// Opens the Dimension Set Entries page showing dimensions for this G/L entry.
    /// </summary>
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    /// <summary>
    /// Updates debit and credit amounts based on the amount and correction flag.
    /// </summary>
    /// <param name="Correction">Indicates whether this is a correction entry</param>
    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if ((Amount > 0) and (not Correction)) or
           ((Amount < 0) and Correction)
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
        end;

        if (("Additional-Currency Amount" > 0) and (not Correction)) or
           (("Additional-Currency Amount" < 0) and Correction)
        then begin
            "Add.-Currency Debit Amount" := "Additional-Currency Amount";
            "Add.-Currency Credit Amount" := 0
        end else begin
            "Add.-Currency Debit Amount" := 0;
            "Add.-Currency Credit Amount" := -"Additional-Currency Amount";
        end;

        OnAfterUpdateDebitCredit(Rec, Correction);
    end;

    /// <summary>
    /// Copies values from General Journal Line to G/L Entry fields.
    /// </summary>
    /// <param name="GenJnlLine">General journal line to copy from</param>
    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetVATDate(GenJnlLine);
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        Description := GenJnlLine.Description;
        Comment := GenJnlLine.Comment;
        "Business Unit Code" := GenJnlLine."Business Unit Code";
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Source Code" := GenJnlLine."Source Code";
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account" then begin
            if GenJnlLine."Source Type" = GenJnlLine."Source Type"::Employee then
                "Source Type" := "Source Type"::Employee
            else
                "Source Type" := GenJnlLine."Source Type";
            "Source No." := GenJnlLine."Source No.";
        end else begin
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee then
                "Source Type" := "Source Type"::Employee
            else
                "Source Type" := GenJnlLine."Account Type";
            "Source No." := GenJnlLine."Account No.";
        end;
        if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"IC Partner") or
           (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"IC Partner")
        then
            "Source Type" := "Source Type"::" ";
        "Job No." := GenJnlLine."Job No.";
        Quantity := GenJnlLine.Quantity;
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Reason Code" := GenJnlLine."Reason Code";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "No. Series" := GenJnlLine."Posting No. Series";
        "IC Partner Code" := GenJnlLine."IC Partner Code";
        "Prod. Order No." := GenJnlLine."Prod. Order No.";

        OnAfterCopyGLEntryFromGenJnlLine(Rec, GenJnlLine);
    end;

    /// <summary>
    /// Copies posting groups from another G/L Entry record.
    /// </summary>
    /// <param name="GLEntry">G/L entry to copy posting groups from</param>
    procedure CopyPostingGroupsFromGLEntry(GLEntry: Record "G/L Entry")
    begin
        "Gen. Posting Type" := GLEntry."Gen. Posting Type";
        "Gen. Bus. Posting Group" := GLEntry."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GLEntry."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GLEntry."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GLEntry."VAT Prod. Posting Group";
        "Tax Area Code" := GLEntry."Tax Area Code";
        "Tax Liable" := GLEntry."Tax Liable";
        "Tax Group Code" := GLEntry."Tax Group Code";
        "Use Tax" := GLEntry."Use Tax";

        OnAfterCopyPostingGroupsFromGLEntry(rec, GLEntry);
    end;

    /// <summary>
    /// Copies posting groups from VAT Entry record.
    /// </summary>
    /// <param name="VATEntry">VAT entry to copy posting groups from</param>
    procedure CopyPostingGroupsFromVATEntry(VATEntry: Record "VAT Entry")
    begin
        "Gen. Posting Type" := VATEntry.Type;
        "Gen. Bus. Posting Group" := VATEntry."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := VATEntry."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        "Tax Area Code" := VATEntry."Tax Area Code";
        "Tax Liable" := VATEntry."Tax Liable";
        "Tax Group Code" := VATEntry."Tax Group Code";
        "Use Tax" := VATEntry."Use Tax";

        OnAfterCopyPostingGroupsFromVATEntry(Rec, VATEntry);
    end;

    /// <summary>
    /// Copies posting groups from General Journal Line record.
    /// </summary>
    /// <param name="GenJnlLine">General journal line to copy posting groups from</param>
    procedure CopyPostingGroupsFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
        "Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
        "Tax Area Code" := GenJnlLine."Tax Area Code";
        "Tax Liable" := GenJnlLine."Tax Liable";
        "Tax Group Code" := GenJnlLine."Tax Group Code";
        "Use Tax" := GenJnlLine."Use Tax";

        OnAfterCopyPostingGroupsFromGenJnlLine(Rec, GenJnlLine);
    end;

    /// <summary>
    /// Copies posting groups from Detailed CV Ledger Entry Buffer record.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuf">Detailed CV ledger entry buffer to copy from</param>
    /// <param name="GenPostingType">General posting type option value</param>
    procedure CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenPostingType: Option " ",Purchase,Sale,Settlement)
    begin
        "Gen. Posting Type" := "General Posting Type".FromInteger(GenPostingType);
        "Gen. Bus. Posting Group" := DtldCVLedgEntryBuf."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := DtldCVLedgEntryBuf."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := DtldCVLedgEntryBuf."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := DtldCVLedgEntryBuf."VAT Prod. Posting Group";
        "Tax Area Code" := DtldCVLedgEntryBuf."Tax Area Code";
        "Tax Liable" := DtldCVLedgEntryBuf."Tax Liable";
        "Tax Group Code" := DtldCVLedgEntryBuf."Tax Group Code";
        "Use Tax" := DtldCVLedgEntryBuf."Use Tax";

        OnAfterCopyPostingGroupsFromDtldCVBuf(Rec, DtldCVLedgEntryBuf);
    end;

    /// <summary>
    /// Integration event raised after copying G/L entry from general journal line.
    /// Enables extensions to modify additional G/L entry fields during posting.
    /// </summary>
    /// <param name="GLEntry">G/L entry being created</param>
    /// <param name="GenJournalLine">Source general journal line</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGLEntryFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Copies values from Deferral Posting Buffer to G/L Entry fields.
    /// </summary>
    /// <param name="DeferralPostBuffer">Deferral posting buffer to copy from</param>
    procedure CopyFromDeferralPostBuffer(DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
        "System-Created Entry" := DeferralPostBuffer."System-Created Entry";
        "Gen. Posting Type" := DeferralPostBuffer."Gen. Posting Type";
        "Gen. Bus. Posting Group" := DeferralPostBuffer."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := DeferralPostBuffer."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := DeferralPostBuffer."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := DeferralPostBuffer."VAT Prod. Posting Group";
        "Tax Area Code" := DeferralPostBuffer."Tax Area Code";
        "Tax Liable" := DeferralPostBuffer."Tax Liable";
        "Tax Group Code" := DeferralPostBuffer."Tax Group Code";
        "Use Tax" := DeferralPostBuffer."Use Tax";

        OnAfterCopyFromDeferralPostBuffer(Rec, DeferralPostBuffer);
    end;

    /// <summary>
    /// Updates the Account ID field based on the G/L Account No.
    /// </summary>
    procedure UpdateAccountID()
    var
        GLAccount: Record "G/L Account";
    begin
        if "G/L Account No." = '' then begin
            Clear("Account Id");
            exit;
        end;

        if not GLAccount.Get("G/L Account No.") then
            exit;

        "Account Id" := GLAccount.SystemId;
    end;

    local procedure UpdateAccountNo()
    var
        GLAccount: Record "G/L Account";
    begin
        if IsNullGuid("Account Id") then
            exit;

        if not GLAccount.GetBySystemId("Account Id") then
            exit;

        "G/L Account No." := GLAccount."No.";
    end;

    local procedure SetVATDate(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."VAT Reporting Date" = 0D then
            "VAT Reporting Date" := GeneralLedgerSetup.GetVATDate(GenJnlLine."Posting Date", GenJnlLine."Document Date")
        else
            "VAT Reporting Date" := GenJnlLine."VAT Reporting Date";
    end;

    /// <summary>
    /// Integration event raised after copying G/L entry values from deferral posting buffer.
    /// Enables extensions to modify G/L entry fields during deferral posting.
    /// </summary>
    /// <param name="GLEntry">G/L entry being updated</param>
    /// <param name="DeferralPostingBuffer">Source deferral posting buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromDeferralPostBuffer(var GLEntry: Record "G/L Entry"; DeferralPostingBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying posting groups from detailed CV ledger entry buffer.
    /// Enables extensions to modify posting group assignments during CV entry processing.
    /// </summary>
    /// <param name="GLEntry">G/L entry being updated</param>
    /// <param name="DtldCVLedgEntryBuf">Source detailed CV ledger entry buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostingGroupsFromDtldCVBuf(var GLEntry: Record "G/L Entry"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying posting groups from another G/L entry.
    /// Enables extensions to modify posting group assignments during G/L entry processing.
    /// </summary>
    /// <param name="GLEntry">G/L entry being updated</param>
    /// <param name="FromGLEntry">Source G/L entry with posting groups to copy</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostingGroupsFromGLEntry(var GLEntry: Record "G/L Entry"; FromGLEntry: Record "G/L Entry");
    begin
    end;

    /// <summary>
    /// Integration event raised after copying posting groups from general journal line.
    /// Enables extensions to modify posting group assignments during journal posting.
    /// </summary>
    /// <param name="GLEntry">G/L entry being updated</param>
    /// <param name="GenJournalLine">Source general journal line</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostingGroupsFromGenJnlLine(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying posting groups from VAT entry.
    /// Enables extensions to modify posting group assignments during VAT processing.
    /// </summary>
    /// <param name="GLEntry">G/L entry being updated</param>
    /// <param name="VATEntry">Source VAT entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostingGroupsFromVATEntry(var GLEntry: Record "G/L Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after updating debit and credit amounts.
    /// Enables extensions to modify debit/credit calculations during posting.
    /// </summary>
    /// <param name="GLEntry">G/L entry with updated debit/credit amounts</param>
    /// <param name="Correction">Indicates whether this is a correction entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDebitCredit(var GLEntry: Record "G/L Entry"; Correction: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before showing related value entries.
    /// Enables extensions to modify value entry filtering and presentation.
    /// </summary>
    /// <param name="ValueEntry">Value entry record for filtering</param>
    /// <param name="GLItemLedgRelation">G/L item ledger relation record</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowValueEntries(var ValueEntry: Record "Value Entry"; var GLItemLedgRelation: Record "G/L - Item Ledger Relation")
    begin
    end;
}