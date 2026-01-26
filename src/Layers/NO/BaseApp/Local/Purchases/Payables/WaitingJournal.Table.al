// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 15000004 "Waiting Journal"
{
    Caption = 'Waiting Journal';
    DrillDownPageID = "Waiting Journal";
    LookupPageID = "Waiting Journal";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Account No."));
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(6; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(11; "Bal. Account No."; Code[20])
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

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
            end;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(14; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(15; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance (LCY)';
            Editable = false;
        }
        field(18; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(19; "Sales/Purch. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales/Purch. (LCY)';
        }
        field(20; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(22; "Sell-to/Buy-from No."; Code[20])
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
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(29; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(30; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(35; "Applies-to Doc. Type"; Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(38; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(40; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(42; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Job No."));
            end;
        }
        field(43; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(44; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(45; "VAT Posting"; Option)
        {
            Caption = 'VAT Posting';
            Editable = false;
            OptionCaption = 'Automatic VAT Entry,Manual VAT Entry';
            OptionMembers = "Automatic VAT Entry","Manual VAT Entry";
        }
        field(47; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(48; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(50; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ' ,F  Fixed,V  Variable,B  Balance,RF Reversing Fixed,RV Reversing Variable,RB Reversing Balance';
            OptionMembers = " ","F  Fixed","V  Variable","B  Balance","RF Reversing Fixed","RV Reversing Variable","RB Reversing Balance";
        }
        field(54; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(55; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(56; "Allocated Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Gen. Jnl. Allocation".Amount where("Journal Template Name" = field("Journal Template Name"),
                                                                   "Journal Batch Name" = field("Journal Batch Name"),
                                                                   "Journal Line No." = field("Line No.")));
            Caption = 'Allocated Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(59; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(60; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(61; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        field(62; "Allow Application"; Boolean)
        {
            Caption = 'Allow Application';
            InitValue = true;
        }
        field(63; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(64; "Bal. Gen. Posting Type"; Option)
        {
            Caption = 'Bal. Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(66; "Bal. Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(67; "Bal. VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
        }
        field(68; "Bal. VAT %"; Decimal)
        {
            Caption = 'Bal. VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';
        }
        field(70; "Bank Payment Type"; Option)
        {
            Caption = 'Bank Payment Type';
            OptionCaption = ' ,Computer Check,Manual Check';
            OptionMembers = " ","Computer Check","Manual Check";
        }
        field(71; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        field(72; "Bal. VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';
        }
        field(73; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(75; "Check Printed"; Boolean)
        {
            Caption = 'Check Printed';
            Editable = false;
        }
        field(76; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        field(77; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(78; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(79; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(80; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(82; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(83; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(84; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(85; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';
        }
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';
        }
        field(90; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(92; "Bal. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(93; "Bal. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(95; "Additional-Currency Posting"; Option)
        {
            Caption = 'Additional-Currency Posting';
            Editable = false;
            OptionCaption = 'None,Amount Only,Additional-Currency Amount Only';
            OptionMembers = "None","Amount Only","Additional-Currency Amount Only";
        }
        field(98; "FA Add.-Currency Factor"; Decimal)
        {
            Caption = 'FA Add.-Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(99; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(100; "Source Currency Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            Editable = false;
        }
        field(101; "Source Curr. VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Base Amount';
            Editable = false;
        }
        field(102; "Source Curr. VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Amount';
            Editable = false;
        }
        field(103; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(104; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(105; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(106; "Bal. VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount (LCY)';
            Editable = false;
        }
        field(107; "Bal. VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount (LCY)';
            Editable = false;
        }
        field(108; "Reversing Entry"; Boolean)
        {
            Caption = 'Reversing Entry';
            Editable = false;
        }
        field(109; "Allow Zero-Amount Posting"; Boolean)
        {
            Caption = 'Allow Zero-Amount Posting';
            Editable = false;
        }
        field(110; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = if ("Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Sell-to/Buy-from No."))
            else
            if ("Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Sell-to/Buy-from No."))
            else
            if ("Bal. Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Sell-to/Buy-from No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Sell-to/Buy-from No."));
        }
        field(111; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(112; "Bal. VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Difference';
            Editable = false;
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
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Campaign No."));
            end;
        }
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,Depreciation,Write-Down,Appreciation,Custom 1,Custom 2,Disposal,Maintenance';
            OptionMembers = " ","Acquisition Cost",Depreciation,"Write-Down",Appreciation,"Custom 1","Custom 2",Disposal,Maintenance;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5604; "No. of Depreciation Days"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
        }
        field(5614; "FA Reclassification Entry"; Boolean)
        {
            Caption = 'FA Reclassification Entry';
        }
        field(5615; "FA Error Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Error Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(5616; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(10000; "Description 2"; Text[50])
        {
            Caption = 'Description';
        }
#if not CLEANSCHEMA26
        field(10604; "VAT Code"; Code[10])
        {
            Caption = 'VAT Code';
            TableRelation = "VAT Code".Code;
            ObsoleteReason = 'Use the field "VAT Number" instead';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
#if not CLEANSCHEMA26
        field(10605; "Bal. VAT Code"; Code[10])
        {
            Caption = 'Bal. VAT Code';
            TableRelation = "VAT Code".Code;
            ObsoleteReason = 'Use the field "Bal. VAT Number" instead';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(10608; "VAT Base Amount Type"; Option)
        {
            Caption = 'VAT Base Amount Type';
            OptionCaption = 'Automatic,With VAT,Without VAT';
            OptionMembers = Automatic,"With VAT","Without VAT";
        }
        field(10610; "VAT Number"; Code[20])
        {
            TableRelation = "VAT Reporting Code".Code;
        }
        field(10611; "Bal. VAT Number"; Code[20])
        {
            TableRelation = "VAT Reporting Code".Code;
        }
        field(15000000; "Remittance Account Code"; Code[10])
        {
            Caption = 'Remittance Account Code';
            TableRelation = "Remittance Account".Code;
        }
        field(15000001; "BOLS Text Code"; Option)
        {
            Caption = 'BOLS Text Code';
            OptionCaption = 'Transfer without advice,KID transfer,Transfer with advice,Money order,Salary,Seaman''s pay,Agricultural settlement,Pension/ Social security,Advice sent from institution other than BBS,Tax,Free text mass payment,Free text,Self-produced money order';
            OptionMembers = "Transfer without advice","KID transfer","Transfer with advice","Money order",Salary,"Seaman's pay","Agricultural settlement","Pension/ Social security","Advice sent from institution other than BBS",Tax,"Free text mass payment","Free text","Self-produced money order";
        }
        field(15000002; "Payment Type Code Domestic"; Code[2])
        {
            Caption = 'Payment Type Code Domestic';
        }
        field(15000003; KID; Code[30])
        {
            Caption = 'KID';
        }
        field(15000004; "Recipient Ref. 1"; Code[40])
        {
            Caption = 'Recipient Ref. 1';
        }
        field(15000005; "Recipient Ref. 2"; Code[40])
        {
            Caption = 'Recipient Ref. 2';
        }
        field(15000006; "Recipient Ref. 3"; Code[40])
        {
            Caption = 'Recipient Ref. 3';
        }
        field(15000007; Urgent; Boolean)
        {
            Caption = 'Urgent';
        }
        field(15000008; "Agreed Exch. Rate"; Decimal)
        {
            BlankZero = true;
            Caption = 'Agreed Exch. Rate';
            DecimalPlaces = 5 : 5;
        }
        field(15000009; "Agreed With"; Code[6])
        {
            Caption = 'Agreed With';
        }
        field(15000010; "Futures Contract No."; Code[6])
        {
            Caption = 'Futures Contract No.';
        }
        field(15000011; "Futures Contract Exch. Rate"; Decimal)
        {
            BlankZero = true;
            Caption = 'Futures Contract Exch. Rate';
            DecimalPlaces = 5 : 5;
        }
        field(15000012; Check; Option)
        {
            Caption = 'Check';
            OptionCaption = 'No,Debit employer,Debit recipient';
            OptionMembers = No,"Debit employer","Debit recipient";
        }
        field(15000013; "Recipient Ref. Foreign"; Code[35])
        {
            Caption = 'Recipient Ref. Foreign';
        }
        field(15000014; "Payment Type Code Foreign"; Code[6])
        {
            Caption = 'Payment Type Code Foreign';
        }
        field(15000015; "Specification (Norges Bank)"; Code[60])
        {
            Caption = 'Specification (Norges Bank)';
        }
        field(15000016; "Remittance Type"; Option)
        {
            Caption = 'Remittance Type';
            Editable = false;
            OptionCaption = 'Domestic,Foreign';
            OptionMembers = Domestic,Foreign;
        }
        field(15000017; "Payment Due Date"; Date)
        {
            Caption = 'Payment Due Date';
            Editable = false;
        }
        field(15000018; "Remittance Agreement Code"; Code[10])
        {
            Caption = 'Remittance Agreement Code';
            TableRelation = "Remittance Agreement".Code;
        }
        field(15000019; Warning; Boolean)
        {
            Caption = 'Warning';
        }
        field(15000020; "Warning Text"; Text[100])
        {
            Caption = 'Warning Text';
        }
        field(15000021; "Payment Order ID - Settled"; Integer)
        {
            Caption = 'Payment Order ID - Settled';
            TableRelation = "Remittance Payment Order".ID;
        }
        field(15000022; "Payment Order ID - Approved"; Integer)
        {
            Caption = 'Payment Order ID - Approved';
            TableRelation = "Remittance Payment Order".ID;
        }
        field(15000023; "Payment Order ID - Sent"; Integer)
        {
            Caption = 'Payment Order ID - Sent';
            TableRelation = "Remittance Payment Order".ID;
        }
        field(15000024; "Remittance Status"; Option)
        {
            Caption = 'Remittance Status';
            OptionCaption = ' ,Sent,Approved,Rejected,Settled,Error,Reseted';
            OptionMembers = " ",Sent,Approved,Rejected,Settled,Error,Reseted;
        }
        field(15000025; Reference; Integer)
        {
            Caption = 'Reference';
        }
        field(15000026; "Return Code"; Text[2])
        {
            Caption = 'Return Code';
        }
        field(15000027; "Handling Ref."; Text[6])
        {
            Caption = 'Handling Ref.';
        }
        field(15000028; "Journal, Settlement Template"; Code[10])
        {
            Caption = 'Journal, Settlement Template';
        }
        field(15000029; "Journal - Settlement"; Code[10])
        {
            Caption = 'Journal - Settlement';
        }
        field(15000030; "Payment Order ID - Rejected"; Integer)
        {
            Caption = 'Payment Order ID - Rejected';
            TableRelation = "Remittance Payment Order".ID;
        }
        field(15000031; "BBS Referance"; Integer)
        {
            Caption = 'BBS Referance';
        }
        field(15000032; "BBS Shipment No."; Integer)
        {
            Caption = 'BBS Shipment No.';
        }
        field(15000033; "BBS Payment Order No."; Integer)
        {
            Caption = 'BBS Payment Order No.';
        }
        field(15000034; "BBS Transaction No."; Integer)
        {
            Caption = 'BBS Transaction No.';
        }
        field(15000035; "Cancellation Cause"; Option)
        {
            Caption = 'Cancellation Cause';
            OptionCaption = ',Cancelled by the bank,Cancelled due to lack of funds,Expired unclaimed money order,Payee''s account closed or non-existent,Cancelled online by customer,Electronic cancellation sent in file by customer';
            OptionMembers = ,"Cancelled by the bank","Cancelled due to lack of funds","Expired unclaimed money order","Payee's account closed or non-existent","Cancelled online by customer","Electronic cancellation sent in file by customer";
        }
        field(15000036; "Price Info"; Option)
        {
            Caption = 'Price Info';
            OptionCaption = ',Debited account separately,Accumulated and debited/invoiced at intervals,Fees deducted from transferred amount';
            OptionMembers = ,"Debited account separately","Accumulated and debited/invoiced at intervals","Fees deducted from transferred amount";
        }
        field(15000037; "Execution Ref. 2"; Text[12])
        {
            Caption = 'Execution Ref. 2';
        }
        field(15000050; "SEPA Msg. ID"; Code[20])
        {
            Caption = 'SEPA Msg. ID';
        }
        field(15000051; "SEPA Instr. ID"; Code[20])
        {
            Caption = 'SEPA Instr. ID';
        }
        field(15000052; "SEPA End To End ID"; Code[20])
        {
            Caption = 'SEPA End To End ID';
        }
        field(15000053; "SEPA Payment Inf ID"; Code[20])
        {
            Caption = 'SEPA Payment Inf ID';
        }
    }

    keys
    {
        key(Key1; Reference)
        {
            Clustered = true;
        }
        key(Key2; "Futures Contract No.", "Line No.")
        {
        }
        key(Key3; "Payment Order ID - Sent")
        {
        }
        key(Key4; "Payment Order ID - Approved")
        {
        }
        key(Key5; "Payment Order ID - Settled")
        {
        }
        key(Key6; "Payment Order ID - Rejected")
        {
        }
        key(Key7; "BBS Referance")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ReturnError.SetRange("Waiting Journal Reference", Reference);
        ReturnError.DeleteAll(true);

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        ReturnError: Record "Return Error";
        DimMgt: Codeunit DimensionManagement;
        WaitingJournalNotFoundErr: Label 'Could not find Waiting Journal(s) matching the return file for update.';

    procedure CopyLineDimensions(GenJnlLine: Record "Gen. Journal Line")
    begin
        // Move Journal Line Dimensions to Waiting Journal
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
    end;

    procedure RecreateLineDimensions(var GenJnlLine: Record "Gen. Journal Line")
    begin
        // Move Waiting Journal Dimensions back to the Journal Line
        GenJnlLine."Dimension Set ID" := "Dimension Set ID";
        GenJnlLine.Modify();
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        TestField("Check Printed", false);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        TestField("Check Printed", false);
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
            "Dimension Set ID", Format(Reference), "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure GetWaitingJournalNotFoundForRemittanceImport(): Text[250]
    begin
        exit(WaitingJournalNotFoundErr);
    end;

    procedure WriteDescription(NewValue: Text)
    begin
        Description := CopyStr(NewValue, 1, MaxStrLen(Description));
        "Description 2" := CopyStr(NewValue, MaxStrLen(Description) + 1, MaxStrLen("Description 2"));
    end;

    procedure ReadDescription(): Text
    begin
        exit(Description + "Description 2");
    end;

    procedure PerformTransferFieldsFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        TempDescription: Text;
    begin
        TempDescription := GenJournalLine.Description;
        GenJournalLine.Description := '';
        TransferFields(GenJournalLine);
        WriteDescription(TempDescription);
    end;

    procedure CreateDimFromDefaultDim(FromFieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FromFieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Account Type".AsInteger()), "Account No.", FromFieldNo = Fieldno("Account No."));
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Bal. Account Type".AsInteger()), "Bal. Account No.", FromFieldNo = Fieldno("Bal. Account No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, "Job No.", FromFieldNo = FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", "Salespers./Purch. Code", FromFieldNo = FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Campaign, "Campaign No.", FromFieldNo = FieldNo("Campaign No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var WaitingJournal: Record "Waiting Journal"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;
}
