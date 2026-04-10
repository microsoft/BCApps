// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.IO;
using System.Threading;

/// <summary>
/// Table storing historical records of posted general journal lines for audit trail and reference purposes.
/// Maintains complete transaction history including account details, amounts, dimensions, and posting information.
/// </summary>
/// <remarks>
/// Archive table for posted general journal transactions providing comprehensive audit trail functionality.
/// Contains complete transaction details including account information, amounts, dimensions, VAT, and posting metadata.
/// Key features: Historical transaction tracking, audit trail compliance, transaction reconstruction capability.
/// Integration: Links to ledger entries via transaction numbers, maintains posting batch relationships.
/// </remarks>
table 181 "Posted Gen. Journal Line"
{
    Caption = 'Posted Gen. Journal Line';
    LookupPageId = "Posted General Journal";
    DrillDownPageId = "Posted General Journal";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Journal template name that defined the original journal's behavior and validation rules.
        /// </summary>
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            ToolTip = 'Specifies the name of the journal template.';
        }
        /// <summary>
        /// Original line number from the general journal line before posting.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            AutoIncrement = true;
        }
        /// <summary>
        /// Account type that was posted (G/L Account, Customer, Vendor, Bank Account, etc.).
        /// </summary>
        field(3; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
        }
        /// <summary>
        /// Account number that was posted to in the original journal transaction.
        /// </summary>
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the account number that the entry on the journal line will be posted to.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                          Blocked = const(false))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const(Employee)) Employee;
        }
        /// <summary>
        /// Date when the journal line was posted to the ledgers.
        /// </summary>
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
            ClosingDates = true;
        }
        /// <summary>
        /// Document type of the posted transaction (Invoice, Payment, Credit Memo, etc.).
        /// </summary>
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of document that the entry on the journal line is.';
        }
        /// <summary>
        /// Document number of the posted transaction for reference and tracking.
        /// </summary>
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies a document number for the journal line.';
        }
        /// <summary>
        /// Description text from the original journal line explaining the transaction purpose.
        /// </summary>
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry.';
        }
        /// <summary>
        /// VAT percentage rate applied to the posted transaction amount.
        /// </summary>
        field(10; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Balancing account number used in the posted journal transaction.
        /// </summary>
        field(11; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry for the journal line will posted (for example, a cash account for cash purchases).';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                               Blocked = const(false))
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
        /// Currency code of the posted transaction amount.
        /// </summary>
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code of the currency for the amounts on the journal line.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Transaction amount in the specified currency (positive for debits, negative for credits).
        /// </summary>
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of.';
        }
        /// <summary>
        /// Debit amount of the posted transaction (always positive when displayed).
        /// </summary>
        field(14; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of, if it is a debit amount.';
        }
        /// <summary>
        /// Credit amount for the posted transaction when using debit/credit presentation.
        /// </summary>
        field(15; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of, if it is a credit amount.';
        }
        /// <summary>
        /// Transaction amount converted to local currency using posting date exchange rate.
        /// </summary>
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
        }
        /// <summary>
        /// Running balance in local currency after posting this transaction.
        /// </summary>
        field(17; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Balance (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Exchange rate factor used for currency conversion at posting time.
        /// </summary>
        field(18; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        /// <summary>
        /// Sales or purchase amount in local currency for statistical reporting.
        /// </summary>
        field(19; "Sales/Purch. (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Sales/Purch. (LCY)';
        }
        /// <summary>
        /// Calculated profit amount in local currency for financial analysis.
        /// </summary>
        field(20; "Profit (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        /// <summary>
        /// Invoice discount amount in local currency applied during posting.
        /// </summary>
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        /// <summary>
        /// Bill-to customer number or pay-to vendor number for transaction tracking.
        /// </summary>
        field(22; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            Editable = false;
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor;
        }
        /// <summary>
        /// Posting group used for G/L account determination (Customer, Vendor, or Fixed Asset).
        /// </summary>
        field(23; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if ("Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Account Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Account Type" = const("Fixed Asset")) "FA Posting Group";
        }
        /// <summary>
        /// Global dimension 1 code for reporting and analysis purposes.
        /// </summary>
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        /// <summary>
        /// Global dimension 2 code for reporting and analysis purposes.
        /// </summary>
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        /// <summary>
        /// Salesperson or purchaser code associated with the transaction.
        /// </summary>
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        /// <summary>
        /// Source code identifying the origin of the posted transaction.
        /// </summary>
        field(29; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Indicates whether the entry was created automatically by the system.
        /// </summary>
        field(30; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        /// <summary>
        /// Hold code preventing payment processing for this transaction.
        /// </summary>
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Document type of the entry that was applied for payment settlement in the posted transaction.
        /// </summary>
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        /// <summary>
        /// Document number of the entry that was applied for payment settlement in the posted transaction.
        /// </summary>
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        /// <summary>
        /// Payment due date for the posted transaction.
        /// </summary>
        field(38; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Date until which payment discount can be taken.
        /// </summary>
        field(39; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        /// <summary>
        /// Payment discount percentage available for early payment.
        /// </summary>
        field(40; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Project number for project-related transactions and cost allocation.
        /// </summary>
        field(42; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        /// <summary>
        /// Quantity associated with the posted transaction for unit-based calculations and reporting.
        /// </summary>
        field(43; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity of items to be included on the journal line.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// VAT amount calculated and posted for the transaction.
        /// </summary>
        field(44; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the amount of VAT included in the total amount.';
        }
        /// <summary>
        /// VAT posting method used (Automatic or Manual VAT Entry).
        /// </summary>
        field(45; "VAT Posting"; Option)
        {
            Caption = 'VAT Posting';
            Editable = false;
            OptionCaption = 'Automatic VAT Entry,Manual VAT Entry';
            OptionMembers = "Automatic VAT Entry","Manual VAT Entry";
        }
        /// <summary>
        /// Payment terms code defining payment conditions for the transaction.
        /// </summary>
        field(47; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Application identifier for grouping entries that apply to each other.
        /// </summary>
        field(48; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        /// <summary>
        /// Business unit code for decentralized organization reporting.
        /// </summary>
        field(50; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// Journal batch name where the original transaction was entered.
        /// </summary>
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the name of the journal batch.';
            TableRelation = "Posted Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        /// <summary>
        /// Reason code explaining the purpose or cause of the transaction.
        /// </summary>
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Recurring posting method for repeating transactions.
        /// </summary>
        field(53; "Recurring Method"; Enum "Gen. Journal Recurring Method")
        {
            BlankZero = true;
            Caption = 'Recurring Method';
        }
        /// <summary>
        /// Expiration date for recurring journal transactions.
        /// </summary>
        field(54; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        /// <summary>
        /// Frequency formula for recurring transaction intervals.
        /// </summary>
        field(55; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        /// <summary>
        /// General posting type for G/L account transactions (Purchase, Sale, Settlement).
        /// </summary>
        field(57; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            ToolTip = 'Specifies the general posting type that will be used when you post the entry on this journal line.';
        }
        /// <summary>
        /// General business posting group for posting setup determination.
        /// </summary>
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for posting setup determination.
        /// </summary>
        field(59; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// VAT calculation type method used for tax calculation.
        /// </summary>
        field(60; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        /// <summary>
        /// Indicates if transaction involves European Union 3-party trade.
        /// </summary>
        field(61; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether the entry can be applied to other entries.
        /// </summary>
        field(62; "Allow Application"; Boolean)
        {
            Caption = 'Allow Application';
            InitValue = true;
        }
        /// <summary>
        /// Balance account type used for automatic balancing (G/L Account, Customer, Vendor, Bank Account).
        /// </summary>
        field(63; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            ToolTip = 'Specifies the code for the balancing account type that should be used in this journal line.';
        }
        /// <summary>
        /// General posting type for balancing account transactions.
        /// </summary>
        field(64; "Bal. Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Bal. Gen. Posting Type';
            ToolTip = 'Specifies the general posting type associated with the balancing account that will be used when you post the entry on the journal line.';
        }
        /// <summary>
        /// General business posting group for balancing account posting setup.
        /// </summary>
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            ToolTip = 'Specifies the general business posting group code associated with the balancing account that will be used when you post the entry.';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for balancing account posting setup.
        /// </summary>
        field(66; "Bal. Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            ToolTip = 'Specifies the general product posting group code associated with the balancing account that will be used when you post the entry.';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// VAT calculation type for balancing account VAT processing.
        /// </summary>
        field(67; "Bal. VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
        }
        /// <summary>
        /// VAT percentage rate for balancing account transactions.
        /// </summary>
        field(68; "Bal. VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Bal. VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// VAT amount calculated for balancing account transactions.
        /// </summary>
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';
        }
        /// <summary>
        /// Bank payment type for electronic banking transactions.
        /// </summary>
        field(70; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Payment Type';
        }
        /// <summary>
        /// VAT base amount for the posted transaction on which VAT calculations were performed.
        /// </summary>
        field(71; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        /// <summary>
        /// VAT base amount for the balancing account on which VAT calculations were performed.
        /// </summary>
        field(72; "Bal. VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';
        }
        /// <summary>
        /// Indicates whether the entry is a correction of a previously posted entry.
        /// </summary>
        field(73; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        /// <summary>
        /// Indicates whether posted documents should be printed automatically.
        /// </summary>
        field(74; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        /// <summary>
        /// Indicates whether a check has been printed for this payment transaction.
        /// </summary>
        field(75; "Check Printed"; Boolean)
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Check Printed';
            Editable = false;
        }
        /// <summary>
        /// Document date from the original source document.
        /// </summary>
        field(76; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        /// <summary>
        /// External document number reference from vendor invoice or customer statement.
        /// </summary>
        field(77; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Source type indicating the origin of the journal line (Customer, Vendor, Bank Account, etc.).
        /// </summary>
        field(78; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        /// <summary>
        /// Source number corresponding to the source type (Customer No., Vendor No., etc.).
        /// </summary>
        field(79; "Source No."; Code[20])
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
        /// Number series used for posting document numbering.
        /// </summary>
        field(80; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Tax area code for sales tax jurisdiction determination.
        /// </summary>
        field(82; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the transaction is subject to sales tax.
        /// </summary>
        field(83; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Tax group code for determining applicable tax rates and calculation rules.
        /// </summary>
        field(84; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether use tax applies to this transaction.
        /// </summary>
        field(85; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// Tax area code for balancing account tax jurisdiction determination.
        /// </summary>
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the balancing account transaction is subject to sales tax.
        /// </summary>
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';
        }
        /// <summary>
        /// Tax group code for balancing account tax calculation rules.
        /// </summary>
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether use tax applies to the balancing account transaction.
        /// </summary>
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';
        }
        /// <summary>
        /// VAT business posting group for VAT setup determination.
        /// </summary>
        field(90; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT business posting group code that will be used when you post the entry on the journal line.';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for VAT setup determination.
        /// </summary>
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT product posting group. Links business transactions made for the item, resource, or G/L account with the general ledger, to account for VAT amounts resulting from trade with that record.';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// VAT business posting group for balancing account VAT setup.
        /// </summary>
        field(92; "Bal. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for balancing account VAT setup.
        /// </summary>
        field(93; "Bal. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Additional currency posting method for multi-currency reporting.
        /// </summary>
        field(95; "Additional-Currency Posting"; Option)
        {
            Caption = 'Additional-Currency Posting';
            Editable = false;
            OptionCaption = 'None,Amount Only,Additional-Currency Amount Only';
            OptionMembers = "None","Amount Only","Additional-Currency Amount Only";
        }
        /// <summary>
        /// Fixed asset additional currency conversion factor.
        /// </summary>
        field(98; "FA Add.-Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'FA Add.-Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        /// <summary>
        /// Currency code of the source document before conversion.
        /// </summary>
        field(99; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Transaction amount in source currency before conversion.
        /// </summary>
        field(100; "Source Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            AutoFormatExpression = "Source Currency Code";
            Caption = 'Source Currency Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT base amount in source currency before conversion.
        /// </summary>
        field(101; "Source Curr. VAT Base Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            AutoFormatExpression = "Source Currency Code";
            Caption = 'Source Curr. VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT amount in source currency before conversion.
        /// </summary>
        field(102; "Source Curr. VAT Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            AutoFormatExpression = "Source Currency Code";
            Caption = 'Source Curr. VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT base discount percentage applied to the transaction.
        /// </summary>
        field(103; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// VAT amount converted to local currency for posting.
        /// </summary>
        field(104; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// VAT base amount converted to local currency for posting.
        /// </summary>
        field(105; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Balancing account VAT amount converted to local currency for posting.
        /// </summary>
        field(106; "Bal. VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Bal. VAT Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Balancing account VAT base amount converted to local currency for posting.
        /// </summary>
        field(107; "Bal. VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Bal. VAT Base Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this is a reversing entry that will be automatically reversed.
        /// </summary>
        field(108; "Reversing Entry"; Boolean)
        {
            Caption = 'Reversing Entry';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether posting zero amounts is allowed for this transaction.
        /// </summary>
        field(109; "Allow Zero-Amount Posting"; Boolean)
        {
            Caption = 'Allow Zero-Amount Posting';
            Editable = false;
        }
        /// <summary>
        /// Ship-to address code for customer transactions or order address code for vendor transactions.
        /// </summary>
        field(110; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = if ("Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."))
            else
            if ("Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."))
            else
            if ("Bal. Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."));
        }
        /// <summary>
        /// VAT amount difference allowed for manual VAT correction.
        /// </summary>
        field(111; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Balancing account VAT amount difference allowed for manual VAT correction.
        /// </summary>
        field(112; "Bal. VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code for intercompany transaction processing.
        /// </summary>
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Intercompany transaction direction (Outgoing or Incoming).
        /// </summary>
        field(114; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// Intercompany partner G/L account number used for intercompany transactions (obsolete field replaced by IC Account No.).
        /// </summary>
        field(116; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        /// <summary>
        /// Intercompany partner transaction number for cross-reference tracking.
        /// </summary>
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Sell-to customer number or buy-from vendor number for the transaction.
        /// </summary>
        field(118; "Sell-to/Buy-from No."; Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor;
        }
        /// <summary>
        /// VAT registration number for tax reporting and compliance verification.
        /// </summary>
        field(119; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        /// <summary>
        /// Country or region code for geographic reporting and tax determination.
        /// </summary>
        field(120; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Indicates whether the transaction is related to a prepayment.
        /// </summary>
        field(121; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        /// <summary>
        /// Indicates whether the entry has been financially voided.
        /// </summary>
        field(122; "Financial Void"; Boolean)
        {
            Caption = 'Financial Void';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether VAT setup should be copied to journal lines.
        /// </summary>
        field(123; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            Editable = false;
            InitValue = true;
        }
        /// <summary>
        /// VAT base amount before payment discount application.
        /// </summary>
        field(125; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            Editable = false;
        }
        /// <summary>
        /// Original payment discount amount possible before any adjustments.
        /// </summary>
        field(126; "Orig. Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            Editable = false;
        }
        /// <summary>
        /// Original payment discount amount possible in local currency at the time of posting.
        /// </summary>
        field(127; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Orig. Pmt. Disc. Possible (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Intercompany account type for intercompany transactions and postings.
        /// </summary>
        field(130; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Intercompany account number for intercompany transactions and reconciliation.
        /// </summary>
        field(131; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
            TableRelation =
            if ("IC Account Type" = const("G/L Account")) "IC G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Account No."), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Bal. Account No."), Blocked = const(false));
        }
        /// <summary>
        /// Job queue status for background processing and automated journal posting operations.
        /// </summary>
        field(160; "Job Queue Status"; Enum "Document Job Queue Status")
        {
            Caption = 'Job Queue Status';
            Editable = false;
        }
        /// <summary>
        /// Job queue entry unique identifier for tracking background processing tasks and automation status.
        /// </summary>
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        /// <summary>
        /// Incoming document entry number linking posted journal entries to source documents for audit trail and workflow tracking.
        /// </summary>
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        /// <summary>
        /// Creditor number for creditor identification in payment processing and vendor management workflows.
        /// </summary>
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        /// <summary>
        /// Payment reference for transaction tracking and bank reconciliation in electronic payment processing.
        /// </summary>
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        /// <summary>
        /// Payment method code defining the payment type and processing rules for transaction execution.
        /// </summary>
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        /// <summary>
        /// External document number for application tracking and cross-reference with external systems.
        /// </summary>
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        /// <summary>
        /// Invoice received date for tracking invoice receipt timing and processing workflow management.
        /// </summary>
        field(175; "Invoice Received Date"; Date)
        {

        }
        /// <summary>
        /// Recipient bank account for payment processing and electronic funds transfer operations.
        /// </summary>
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Account No."))
            else
            if ("Account Type" = const(Employee)) Employee."No." where("Employee No. Filter" = field("Account No."))
            else
            if ("Bal. Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Bal. Account No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Bal. Account No."))
            else
            if ("Bal. Account Type" = const(Employee)) Employee."No." where("Employee No. Filter" = field("Bal. Account No."));
        }
        /// <summary>
        /// Message to recipient for payment communication and remittance advice in electronic payment processing.
        /// </summary>
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
        /// <summary>
        /// Indicates whether payment data has been exported to external payment file for electronic payment processing.
        /// </summary>
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            Editable = false;
        }
        /// <summary>
        /// Dimension set identifier linking posted entries to dimension combinations for analytical reporting and financial analysis.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Project task number for job-specific transactions linking posted entries to specific project tasks and work breakdown structure.
        /// </summary>
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        /// <summary>
        /// Project unit price in local currency for job costing and project profitability calculations.
        /// </summary>
        field(1002; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Project Unit Price (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Project total price in local currency for job revenue tracking and project financial analysis.
        /// </summary>
        field(1003; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Project Total Price (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Project quantity for job consumption tracking and resource utilization calculations.
        /// </summary>
        field(1004; "Job Quantity"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 0;
            Caption = 'Project Quantity';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Project unit cost in local currency for job cost accounting and project profitability analysis.
        /// </summary>
        field(1005; "Job Unit Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Project Unit Cost (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Project line discount percentage for job pricing adjustments and contract-based discounting.
        /// </summary>
        field(1006; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 0;
            Caption = 'Project Line Discount %';
        }
        /// <summary>
        /// Project line discount amount in local currency for job cost and revenue calculations with contract adjustments.
        /// </summary>
        field(1007; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Project Line Disc. Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Project unit of measure code for job quantity tracking and resource measurement standardization.
        /// </summary>
        field(1008; "Job Unit Of Measure Code"; Code[10])
        {
            Caption = 'Project Unit Of Measure Code';
            TableRelation = "Unit of Measure";
        }
        /// <summary>
        /// Project line type defining the nature of job transaction for project classification and billing purposes.
        /// </summary>
        field(1009; "Job Line Type"; Enum "Job Line Type")
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Type';
        }
        /// <summary>
        /// Project unit price in job currency for multi-currency project pricing and international project management.
        /// </summary>
        field(1010; "Job Unit Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Project Unit Price';
        }
        /// <summary>
        /// Project total price in job currency for multi-currency project revenue tracking and financial reporting.
        /// </summary>
        field(1011; "Job Total Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Total Price';
            Editable = false;
        }
        /// <summary>
        /// Project unit cost in job currency for multi-currency project cost accounting and international project analysis.
        /// </summary>
        field(1012; "Job Unit Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Project Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Project total cost in job currency for multi-currency project expense tracking and cost management.
        /// </summary>
        field(1013; "Job Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Total Cost';
            Editable = false;
        }
        /// <summary>
        /// Project line discount amount in job currency for contract-based pricing adjustments and international project discounting.
        /// </summary>
        field(1014; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Line Discount Amount';
        }
        /// <summary>
        /// Project line amount in job currency for multi-currency project revenue and billing calculations.
        /// </summary>
        field(1015; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Line Amount';
        }
        /// <summary>
        /// Project total cost in local currency for comprehensive job cost tracking and profitability analysis.
        /// </summary>
        field(1016; "Job Total Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Project Total Cost (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Project line amount in local currency for consolidated job revenue reporting and financial analysis.
        /// </summary>
        field(1017; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Project Line Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Project currency factor for multi-currency job calculations and exchange rate tracking in international projects.
        /// </summary>
        field(1018; "Job Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Project Currency Factor';
        }
        /// <summary>
        /// Project currency code for multi-currency job transactions and international project financial management.
        /// </summary>
        field(1019; "Job Currency Code"; Code[10])
        {
            Caption = 'Project Currency Code';
        }
        /// <summary>
        /// Project planning line number linking posted entries to specific job planning lines for project progress tracking.
        /// </summary>
        field(1020; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';
        }
        /// <summary>
        /// Project remaining quantity for job completion tracking and resource planning calculations.
        /// </summary>
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 0;
            Caption = 'Project Remaining Qty.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Direct debit mandate ID for SEPA direct debit processing and automated payment collections from customer accounts.
        /// </summary>
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = if ("Account Type" = const(Customer)) "SEPA Direct Debit Mandate" where("Customer No." = field("Account No."));
        }
        /// <summary>
        /// Data exchange entry number linking posted entries to external data import processes and bank statement reconciliation.
        /// </summary>
        field(1220; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Payer information from imported bank statements and electronic payment processing for transaction identification.
        /// </summary>
        field(1221; "Payer Information"; Text[50])
        {
            Caption = 'Payer Information';
        }
        /// <summary>
        /// Transaction information from electronic payment processing and bank statement imports for detailed payment tracking.
        /// </summary>
        field(1222; "Transaction Information"; Text[100])
        {
            Caption = 'Transaction Information';
        }
        /// <summary>
        /// Data exchange line number for tracking specific lines within imported bank statement and payment files.
        /// </summary>
        field(1223; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        /// <summary>
        /// Applied automatically flag indicating whether the posted entry was matched and applied through automated payment matching processes.
        /// </summary>
        field(1224; "Applied Automatically"; Boolean)
        {
            Caption = 'Applied Automatically';
        }
        /// <summary>
        /// Deferral code for revenue and expense deferral processing linking posted entries to deferral templates and schedules.
        /// </summary>
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            ToolTip = 'Specifies the deferral template that governs how expenses or revenue are deferred to the different accounting periods when the expenses or revenue were incurred.';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        /// <summary>
        /// Deferral line number for tracking specific lines within deferral schedules and multi-period revenue/expense recognition.
        /// </summary>
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
        }
        /// <summary>
        /// Campaign number for marketing campaign tracking and sales/purchase transaction analysis by promotional activities.
        /// </summary>
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        /// <summary>
        /// Production order number for manufacturing cost allocation and work-in-process tracking in production-related transactions.
        /// </summary>
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
        }
        /// <summary>
        /// Fixed asset posting date for FA-specific transaction dating and depreciation calculation in asset management entries.
        /// </summary>
        field(5600; "FA Posting Date"; Date)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Date';
        }
        /// <summary>
        /// Fixed asset posting type defining the nature of FA transaction for depreciation, acquisition, disposal, and maintenance operations.
        /// </summary>
        field(5601; "FA Posting Type"; Enum "Gen. Journal Line FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';
        }
        /// <summary>
        /// Depreciation book code for fixed asset depreciation tracking and multiple depreciation method management.
        /// </summary>
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Salvage value for fixed asset depreciation calculations representing the estimated residual value at end of asset life.
        /// </summary>
        field(5603; "Salvage Value"; Decimal)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Salvage Value';
        }
        /// <summary>
        /// Number of depreciation days for fixed asset depreciation calculation and pro-rated depreciation in partial periods.
        /// </summary>
        field(5604; "No. of Depreciation Days"; Integer)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
        }
        /// <summary>
        /// Depreciate until FA posting date flag controlling whether depreciation should be calculated up to the FA posting date.
        /// </summary>
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
        }
        /// <summary>
        /// Depreciate acquisition cost flag controlling whether the acquisition cost should be subject to depreciation calculations.
        /// </summary>
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. Acquisition Cost';
        }
        /// <summary>
        /// Maintenance code for fixed asset maintenance tracking and service history documentation in asset management systems.
        /// </summary>
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        /// <summary>
        /// Insurance number linking fixed asset entries to insurance policies for asset protection and risk management tracking.
        /// </summary>
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        /// <summary>
        /// Budgeted fixed asset number for budget tracking and planned asset acquisition management in financial planning processes.
        /// </summary>
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        /// <summary>
        /// Duplicate in depreciation book code for cross-book depreciation posting and multi-book asset management synchronization.
        /// </summary>
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Use duplication list flag controlling whether the duplication list should be used for cross-book depreciation posting.
        /// </summary>
        field(5613; "Use Duplication List"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Use Duplication List';
        }
        /// <summary>
        /// Fixed asset reclassification entry flag indicating whether this entry represents an asset reclassification transaction.
        /// </summary>
        field(5614; "FA Reclassification Entry"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Reclassification Entry';
        }
        /// <summary>
        /// Fixed asset error entry number linking to FA ledger entry for error correction and audit trail purposes.
        /// </summary>
        field(5615; "FA Error Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Error Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        /// <summary>
        /// Index entry flag indicating whether this entry represents an indexed transaction for inflation adjustment calculations.
        /// </summary>
        field(5616; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        /// <summary>
        /// Source line number tracking the original journal line number for audit trail and transaction traceability.
        /// </summary>
        field(5617; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// Comment field for additional notes and documentation related to the posted journal line transaction.
        /// </summary>
        field(5618; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        /// <summary>
        /// Check exported flag indicating whether the check payment has been exported to the bank payment processing system.
        /// </summary>
        field(5701; "Check Exported"; Boolean)
        {
            Caption = 'Check Exported';
        }
        /// <summary>
        /// Check transmitted flag indicating whether the check payment has been successfully transmitted to the bank.
        /// </summary>
        field(5702; "Check Transmitted"; Boolean)
        {
            Caption = 'Check Transmitted';
        }
        /// <summary>
        /// Non-deductible VAT percentage for tax calculations where only part of the VAT can be deducted per tax regulations.
        /// </summary>
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Non-deductible VAT base amount in transaction currency for calculating non-deductible VAT portions per tax legislation.
        /// </summary>
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base';
        }
        /// <summary>
        /// Non-deductible VAT amount in transaction currency representing the portion of VAT that cannot be deducted.
        /// </summary>
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount';
        }
        /// <summary>
        /// Non-deductible VAT base amount in local currency for standardized non-deductible VAT reporting and accounting.
        /// </summary>
        field(6203; "Non-Deductible VAT Base LCY"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Base LCY';
        }
        /// <summary>
        /// Non-deductible VAT amount in local currency for consolidated non-deductible VAT reporting and financial analysis.
        /// </summary>
        field(6204; "Non-Deductible VAT Amount LCY"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Amount LCY';
        }
        /// <summary>
        /// Non-deductible VAT base amount in additional currency for multi-currency non-deductible VAT tracking and reporting.
        /// </summary>
        field(6205; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base ACY';
        }
        /// <summary>
        /// Non-deductible VAT amount in additional currency for comprehensive multi-currency non-deductible VAT management.
        /// </summary>
        field(6206; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
        }
        /// <summary>
        /// Non-deductible VAT difference for handling variances in non-deductible VAT calculations and adjustments.
        /// </summary>
        field(6208; "Non-Deductible VAT Diff."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Difference';
        }
        /// <summary>
        /// Account ID for API integration providing GUID-based account identification for external system connectivity.
        /// </summary>
        field(8001; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".SystemId;
        }
        /// <summary>
        /// Customer ID for API integration providing GUID-based customer identification for external system connectivity.
        /// </summary>
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;
        }
        /// <summary>
        /// Applies-to invoice ID for API integration providing GUID-based invoice identification for external application matching.
        /// </summary>
        field(8003; "Applies-to Invoice Id"; Guid)
        {
            Caption = 'Applies-to Invoice Id';
            TableRelation = "Sales Invoice Header".SystemId;
        }
        /// <summary>
        /// Contact graph ID for Microsoft Graph API integration enabling contact synchronization with external systems.
        /// </summary>
        field(8004; "Contact Graph Id"; Text[250])
        {
            Caption = 'Contact Graph Id';
        }
        /// <summary>
        /// Last modified date time for API integration tracking when the posted journal line was last updated.
        /// </summary>
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        /// <summary>
        /// Journal batch ID for API integration providing GUID-based batch identification for external system connectivity.
        /// </summary>
        field(8006; "Journal Batch Id"; Guid)
        {
            Caption = 'Journal Batch Id';
            TableRelation = "Gen. Journal Batch".SystemId;
        }
        /// <summary>
        /// Payment method ID for API integration providing GUID-based payment method identification for external systems.
        /// </summary>
        field(8007; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';
            TableRelation = "Payment Method".SystemId;
        }
        /// <summary>
        /// General ledger register number linking posted entries to specific G/L register for audit trail and batch tracking.
        /// </summary>
        field(8010; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            ToolTip = 'Specifies the number of the general ledger register.';
            TableRelation = "G/L Register";
        }
        /// <summary>
        /// Indentation level for hierarchical display of posted journal lines in reports and user interface presentations.
        /// </summary>
        field(8011; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "G/L Register No.")
        {
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
        }
        fieldgroup(Brick; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
        }
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    /// <summary>
    /// Creates a posted general journal line record from a general journal line during the posting process.
    /// </summary>
    /// <param name="GenJournalLine">The source general journal line record to create posted entry from.</param>
    /// <param name="GLRegNo">The G/L register number for linking to the posting batch.</param>
    /// <param name="FirstLine">Indicates whether this is the first line in the posting batch.</param>
    procedure InsertFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; GLRegNo: Integer; FirstLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertFromGenJournalLine(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        Init();
        TransferFields(GenJournalLine);
        "Line No." := 0;
        "G/L Register No." := GLRegNo;
        if not FirstLine then
            Indentation := 1;
        Insert();
        Rec.CopyLinks(GenJournalLine);

        OnAfterInsertFromGenJournalLine(GenJournalLine, Rec);
    end;

    /// <summary>
    /// Integration event triggered before creating a posted general journal line record from a general journal line.
    /// </summary>
    /// <param name="GenJournalLine">The source general journal line record.</param>
    /// <param name="IsHandled">Set to true to skip the default insertion logic.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event triggered after successfully creating a posted general journal line record from a general journal line.
    /// </summary>
    /// <param name="GenJournalLine">The source general journal line record that was used for creation.</param>
    /// <param name="PostedGenJournalLine">The created posted general journal line record.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; var PostedGenJournalLine: Record "Posted Gen. Journal Line")
    begin
    end;
}
