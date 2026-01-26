// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

/// <summary>
/// Table storing detailed line information for standard general journal templates enabling reusable journal entry patterns.
/// Contains complete journal line configurations including accounts, amounts, dimensions, and posting details for template-based journal creation.
/// </summary>
/// <remarks>
/// Detailed line storage for standard journal templates with complete transaction configuration.
/// Stores all journal line fields including account details, amounts, dimensions, VAT settings, and posting parameters.
/// Key features: Template line configurations, reusable transaction patterns, complete field coverage for journal creation.
/// Integration: Links to Standard General Journal header table, supports mass journal line creation via standard templates.
/// </remarks>
table 751 "Standard General Journal Line"
{
    Caption = 'Standard General Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// References the journal template for the standard journal line configuration.
        /// </summary>
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            Editable = false;
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Sequential line number within the standard journal template for ordering standard lines.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the account type for the standard journal line template.
        /// </summary>
        field(3; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                                       "Account Type"::"IC Partner"]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner"])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                Validate("Account No.", '');
                Validate("IC Account No.", '');

                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then begin
                    Validate("Gen. Posting Type", "Gen. Posting Type"::" ");
                    Validate("Gen. Bus. Posting Group", '');
                    Validate("Gen. Prod. Posting Group", '');
                end else
                    if "Bal. Account Type" in [
                                               "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');
                UpdateSource();

                if xRec."Account Type" in
                   [xRec."Account Type"::Customer, xRec."Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                end;
            end;
        }
        /// <summary>
        /// Account number for the standard journal line based on the account type selection.
        /// </summary>
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
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                if xRec."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"] then
                    "IC Partner Code" := '';

                if "Account No." = '' then begin
                    UpdateLineBalance();
                    UpdateSource();
                    CreateDimFromDefaultDim(FieldNo("Account No."));
                    if xRec."Account No." <> '' then begin
                        "Gen. Posting Type" := "Gen. Posting Type"::" ";
                        "Gen. Bus. Posting Group" := '';
                        "Gen. Prod. Posting Group" := '';
                        "VAT Bus. Posting Group" := '';
                        "VAT Prod. Posting Group" := '';
                        "Tax Area Code" := '';
                        "Tax Liable" := false;
                        "Tax Group Code" := '';
                    end;
                    exit;
                end;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        GetGLAccount();
                    "Account Type"::Customer:
                        GetCustomerAccount();
                    "Account Type"::Vendor:
                        GetVendorAccount();
                    "Account Type"::"Bank Account":
                        GetBankAccount();
                    "Account Type"::"Fixed Asset":
                        GetFAAccount();
                    "Account Type"::"IC Partner":
                        GetICPartnerAccount();
                end;

                Validate("Currency Code");
                Validate("VAT Prod. Posting Group");
                UpdateLineBalance();
                UpdateSource();
                CreateDimFromDefaultDim(FieldNo("Account No."));

                if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
                    Validate("IC Account No.", GetDefaultICPartnerGLAccNo());
            end;
        }
        /// <summary>
        /// Document type for the standard journal line defining transaction characteristics and posting behavior.
        /// </summary>
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                Validate("Payment Terms Code");
                if "Account No." <> '' then
                    CheckAccount("Account Type", "Account No.");
                if "Bal. Account No." <> '' then
                    CheckAccount("Bal. Account Type", "Bal. Account No.");
            end;
        }
        /// <summary>
        /// Text description of the standard journal line for identification and transaction explanation.
        /// </summary>
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// VAT percentage rate applied to the transaction amount for standard journal line tax calculation.
        /// </summary>
        field(10; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetCurrency();
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT Amount" :=
                          Round(
                            Amount * "VAT %" / (100 + "VAT %"),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Amount" := Amount;
                    "VAT Calculation Type"::"Sales Tax":
                        if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) and
                           "Use Tax"
                        then begin
                            "VAT Amount" := 0;
                            "VAT %" := 0;
                        end else begin
                            "VAT Amount" :=
                              Amount -
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable",
                                WorkDate(), Amount, Quantity, "Currency Factor");
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / (Amount - "VAT Amount"), 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" :=
                              Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                "VAT Base Amount" := Amount - "VAT Amount";
                "VAT Difference" := 0;
            end;
        }
        /// <summary>
        /// Balancing account number for the standard journal line to complete double-entry accounting.
        /// </summary>
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
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                if xRec."Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor,
                                                "Bal. Account Type"::"IC Partner"]
                then
                    "IC Partner Code" := '';

                if "Bal. Account No." = '' then begin
                    UpdateLineBalance();
                    UpdateSource();
                    CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
                    if xRec."Bal. Account No." <> '' then begin
                        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
                        "Bal. Gen. Bus. Posting Group" := '';
                        "Bal. Gen. Prod. Posting Group" := '';
                        "Bal. VAT Bus. Posting Group" := '';
                        "Bal. VAT Prod. Posting Group" := '';
                        "Bal. Tax Area Code" := '';
                        "Bal. Tax Liable" := false;
                        "Bal. Tax Group Code" := '';
                    end;
                    exit;
                end;

                case "Bal. Account Type" of
                    "Bal. Account Type"::"G/L Account":
                        GetGLBalAccount();
                    "Bal. Account Type"::Customer:
                        GetCustomerBalAccount();
                    "Bal. Account Type"::Vendor:
                        GetVendorBalAccount();
                    "Bal. Account Type"::"Bank Account":
                        GetBankBalAccount();
                    "Bal. Account Type"::"Fixed Asset":
                        GetFABalAccount();
                    "Bal. Account Type"::"IC Partner":
                        GetICPartnerBalAccount();
                end;

                Validate("Currency Code");
                Validate("Bal. VAT Prod. Posting Group");
                UpdateLineBalance();
                UpdateSource();
                CreateDimFromDefaultDim(FieldNo("Bal. Account No."));

                if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
                    Validate("IC Account No.", GetDefaultICPartnerGLAccNo());
            end;
        }
        /// <summary>
        /// Currency code for the standard journal line transaction amount, empty for local currency.
        /// </summary>
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
            begin
                if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                    if BankAcc.Get("Bal. Account No.") and (BankAcc."Currency Code" <> '') then
                        BankAcc.TestField("Currency Code", "Currency Code");
                if "Account Type" = "Account Type"::"Bank Account" then
                    if BankAcc.Get("Account No.") and (BankAcc."Currency Code" <> '') then
                        BankAcc.TestField("Currency Code", "Currency Code");

                if "Currency Code" <> '' then begin
                    GetCurrency();
                    if ("Currency Code" <> xRec."Currency Code") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" :=
                          CurrExchRate.ExchangeRate(WorkDate(), "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
            end;
        }
        /// <summary>
        /// Transaction amount for the standard journal line in the specified currency.
        /// </summary>
        field(13; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          WorkDate(), "Currency Code",
                          Amount, "Currency Factor"));

                Amount := Round(Amount, Currency."Amount Rounding Precision");

                Validate("VAT %");
                Validate("Bal. VAT %");
                UpdateLineBalance();
            end;
        }
        /// <summary>
        /// Debit amount for the standard journal line when using debit/credit entry method.
        /// </summary>
        field(14; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "Debit Amount" := Round("Debit Amount", Currency."Amount Rounding Precision");
                Correction := "Debit Amount" < 0;
                Amount := "Debit Amount";
                Validate(Amount);
            end;
        }
        /// <summary>
        /// Credit amount for the standard journal line when using debit/credit entry method.
        /// </summary>
        field(15; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "Credit Amount" := Round("Credit Amount", Currency."Amount Rounding Precision");
                Correction := "Credit Amount" < 0;
                Amount := -"Credit Amount";
                Validate(Amount);
            end;
        }
        /// <summary>
        /// Transaction amount converted to local currency for standard journal line.
        /// </summary>
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end
            end;
        }
        /// <summary>
        /// Running balance in local currency after posting the standard journal line.
        /// </summary>
        field(17; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Currency exchange rate factor for converting foreign currency amounts to local currency.
        /// </summary>
        field(18; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text002, FieldCaption("Currency Code")));
                Validate(Amount);
            end;
        }
        /// <summary>
        /// Sales or purchase amount in local currency for standard journal line statistical tracking.
        /// </summary>
        field(19; "Sales/Purch. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales/Purch. (LCY)';
        }
        /// <summary>
        /// Profit amount in local currency calculated for the standard journal line.
        /// </summary>
        field(20; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        /// <summary>
        /// Invoice discount amount in local currency applied to the standard journal line.
        /// </summary>
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        /// <summary>
        /// Bill-to customer or pay-to vendor number for the standard journal line transaction.
        /// </summary>
        field(22; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor;

            trigger OnValidate()
            begin
                if "Bill-to/Pay-to No." <> xRec."Bill-to/Pay-to No." then
                    "Ship-to/Order Address Code" := '';
            end;
        }
        /// <summary>
        /// Posting group for determining posting accounts and setup for the standard journal line.
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
        /// Shortcut dimension 1 code for the standard journal line analytical tracking and reporting.
        /// </summary>
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Shortcut dimension 2 code for the standard journal line analytical tracking and reporting.
        /// </summary>
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Salesperson or purchaser code assigned to the standard journal line for tracking responsibilities.
        /// </summary>
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Salespers./Purch. Code"));
            end;
        }
        /// <summary>
        /// Source code identifying the journal template origin for the standard journal line.
        /// </summary>
        field(29; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Hold code preventing processing of the standard journal line until manually released.
        /// </summary>
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Document type of the target document for application when posting the standard journal line.
        /// </summary>
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        /// <summary>
        /// Payment discount percentage rate applicable to the standard journal line transaction.
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
        /// Job number for project-related transactions in the standard journal line.
        /// </summary>
        field(42; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
            TableRelation = Job;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Job No."));
            end;
        }
        /// <summary>
        /// Quantity associated with the standard journal line transaction for unit-based calculations.
        /// </summary>
        field(43; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        /// <summary>
        /// VAT amount calculated for the standard journal line based on VAT percentage and base amount.
        /// </summary>
        field(44; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                if not ("VAT Calculation Type" in
                        ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])
                then
                    Error(
                      Text010, FieldCaption("VAT Calculation Type"),
                      "VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT");
                if "VAT Amount" <> 0 then begin
                    TestField("VAT %");
                    TestField(Amount);
                end;

                GetCurrency();
                "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

                if "VAT Amount" * Amount < 0 then
                    if "VAT Amount" > 0 then
                        Error(Text011, FieldCaption("VAT Amount"))
                    else
                        Error(Text012, FieldCaption("VAT Amount"));

                "VAT Base Amount" := Amount - "VAT Amount";

                "VAT Difference" :=
                  "VAT Amount" -
                  Round(
                    Amount * "VAT %" / (100 + "VAT %"),
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
                    Error(Text013, FieldCaption("VAT Difference"), Currency."Max. VAT Difference Allowed");
            end;
        }
        /// <summary>
        /// Payment terms code defining payment conditions for the standard journal line transaction.
        /// </summary>
        field(47; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Business unit code for organizational segmentation of the standard journal line.
        /// </summary>
        field(50; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// Standard journal code identifying the parent template for this standard journal line.
        /// </summary>
        field(51; "Standard Journal Code"; Code[10])
        {
            Caption = 'Standard Journal Code';
            TableRelation = "Standard General Journal".Code;
        }
        /// <summary>
        /// Reason code explaining the purpose or cause of the standard journal line transaction.
        /// </summary>
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// General posting type indicating whether the standard journal line is for purchase, sale, or settlement.
        /// </summary>
        field(57; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';

            trigger OnValidate()
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("Gen. Posting Type", "Gen. Posting Type"::" ");
                if ("Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Gen. Posting Type");
                if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                    Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// General business posting group for determining posting accounts for the standard journal line.
        /// </summary>
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("Gen. Bus. Posting Group", '');
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        /// <summary>
        /// General product posting group for determining posting accounts for the standard journal line.
        /// </summary>
        field(59; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("Gen. Prod. Posting Group", '');
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT calculation type determining how VAT is calculated for the standard journal line.
        /// </summary>
        field(60; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        /// <summary>
        /// Balancing account type for the standard journal line to complete double-entry accounting.
        /// </summary>
        field(63; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                                       "Account Type"::"IC Partner"]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner"])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                Validate("Bal. Account No.", '');
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then begin
                    Validate("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                    Validate("Bal. Gen. Bus. Posting Group", '');
                    Validate("Bal. Gen. Prod. Posting Group", '');
                end else
                    if "Account Type" in [
                                          "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');
                UpdateSource();

                if xRec."Bal. Account Type" in
                   [xRec."Bal. Account Type"::Customer, xRec."Bal. Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                end;
                if ("Account Type" in [
                                       "Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]) and
                   ("Bal. Account Type" in [
                                            "Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"])
                then
                    Validate("Payment Terms Code", '');
            end;
        }
        /// <summary>
        /// General posting type for the balancing account in the standard journal line.
        /// </summary>
        field(64; "Bal. Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Bal. Gen. Posting Type';

            trigger OnValidate()
            begin
                if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"] then
                    TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                if ("Bal. Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Bal. Gen. Posting Type");
                if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                    Validate("Bal. VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// General business posting group for the balancing account in the standard journal line.
        /// </summary>
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"] then
                    TestField("Bal. Gen. Bus. Posting Group", '');
                if xRec."Bal. Gen. Bus. Posting Group" <> "Bal. Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Bal. Gen. Bus. Posting Group") then
                        Validate("Bal. VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        /// <summary>
        /// General product posting group for the balancing account in the standard journal line.
        /// </summary>
        field(66; "Bal. Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"] then
                    TestField("Bal. Gen. Prod. Posting Group", '');
                if xRec."Bal. Gen. Prod. Posting Group" <> "Bal. Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Bal. Gen. Prod. Posting Group") then
                        Validate("Bal. VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT calculation type for the balancing account in the standard journal line.
        /// </summary>
        field(67; "Bal. VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
        }
        /// <summary>
        /// VAT percentage rate for the balancing account in the standard journal line.
        /// </summary>
        field(68; "Bal. VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Bal. VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetCurrency();
                case "Bal. VAT Calculation Type" of
                    "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT":
                        "Bal. VAT Amount" :=
                          Round(
                            -Amount * "Bal. VAT %" / (100 + "Bal. VAT %"),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                    "Bal. VAT Calculation Type"::"Full VAT":
                        "Bal. VAT Amount" := -Amount;
                    "Bal. VAT Calculation Type"::"Sales Tax":
                        if ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase) and
                           "Bal. Use Tax"
                        then begin
                            "Bal. VAT Amount" := 0;
                            "Bal. VAT %" := 0;
                        end else begin
                            "Bal. VAT Amount" :=
                              -(Amount -
                                SalesTaxCalculate.ReverseCalculateTax(
                                  "Bal. Tax Area Code", "Bal. Tax Group Code", "Bal. Tax Liable",
                                  WorkDate(), Amount, Quantity, "Currency Factor"));
                            if Amount + "Bal. VAT Amount" <> 0 then
                                "Bal. VAT %" := Round(100 * -"Bal. VAT Amount" / (Amount + "Bal. VAT Amount"), 0.00001)
                            else
                                "Bal. VAT %" := 0;
                            "Bal. VAT Amount" :=
                              Round("Bal. VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                "Bal. VAT Base Amount" := -(Amount + "Bal. VAT Amount");
                "Bal. VAT Difference" := 0;
            end;
        }
        /// <summary>
        /// VAT amount calculated for the balancing account in the standard journal line.
        /// </summary>
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';

            trigger OnValidate()
            begin
                if not ("Bal. VAT Calculation Type" in
                        ["Bal. VAT Calculation Type"::"Normal VAT", "Bal. VAT Calculation Type"::"Reverse Charge VAT"])
                then
                    Error(
                      Text010, FieldCaption("Bal. VAT Calculation Type"),
                      "Bal. VAT Calculation Type"::"Normal VAT", "Bal. VAT Calculation Type"::"Reverse Charge VAT");
                if "Bal. VAT Amount" <> 0 then begin
                    TestField("Bal. VAT %");
                    TestField(Amount);
                end;

                GetCurrency();
                "Bal. VAT Amount" :=
                  Round("Bal. VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

                if "Bal. VAT Amount" * Amount > 0 then
                    if "Bal. VAT Amount" > 0 then
                        Error(Text011, FieldCaption("Bal. VAT Amount"))
                    else
                        Error(Text012, FieldCaption("Bal. VAT Amount"));

                "Bal. VAT Base Amount" := -(Amount + "Bal. VAT Amount");

                "Bal. VAT Difference" :=
                  "Bal. VAT Amount" -
                  Round(
                    -Amount * "Bal. VAT %" / (100 + "Bal. VAT %"),
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                if Abs("Bal. VAT Difference") > Currency."Max. VAT Difference Allowed" then
                    Error(
                      Text013, FieldCaption("Bal. VAT Difference"), Currency."Max. VAT Difference Allowed");
            end;
        }
        /// <summary>
        /// Bank payment type specifying the method of payment for the standard journal line.
        /// </summary>
        field(70; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';

            trigger OnValidate()
            begin
                if ("Bank Payment Type" <> "Bank Payment Type"::" ") and
                   ("Account Type" <> "Account Type"::"Bank Account") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
                then
                    Error(
                      Text007,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));
                if ("Account Type" = "Account Type"::"Fixed Asset") and
                   ("Bank Payment Type" <> "Bank Payment Type"::" ")
                then
                    FieldError("Account Type");
            end;
        }
        /// <summary>
        /// VAT base amount for calculating VAT on the standard journal line transaction.
        /// </summary>
        field(71; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "VAT Base Amount" := Round("VAT Base Amount", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        Amount :=
                          Round(
                            "VAT Base Amount" * (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                    "VAT Calculation Type"::"Full VAT":
                        if "VAT Base Amount" <> 0 then
                            FieldError(
                              "VAT Base Amount",
                              StrSubstNo(
                                Text008, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) and
                           "Use Tax"
                        then begin
                            "VAT Amount" := 0;
                            "VAT %" := 0;
                            Amount := "VAT Base Amount" + "VAT Amount";
                        end else begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", WorkDate(),
                                "VAT Base Amount", Quantity, "Currency Factor");
                            if "VAT Base Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" :=
                              Round("VAT Amount", Currency."Amount Rounding Precision");
                            Amount := "VAT Base Amount" + "VAT Amount";
                        end;
                end;
                Validate(Amount);
            end;
        }
        /// <summary>
        /// VAT base amount for the balancing account in the standard journal line.
        /// </summary>
        field(72; "Bal. VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "Bal. VAT Base Amount" := Round("Bal. VAT Base Amount", Currency."Amount Rounding Precision");
                case "Bal. VAT Calculation Type" of
                    "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT":
                        Amount :=
                          Round(
                            -"Bal. VAT Base Amount" * (1 + "Bal. VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                    "Bal. VAT Calculation Type"::"Full VAT":
                        if "Bal. VAT Base Amount" <> 0 then
                            FieldError(
                              "Bal. VAT Base Amount",
                              StrSubstNo(
                                Text008, FieldCaption("Bal. VAT Calculation Type"),
                                "Bal. VAT Calculation Type"));
                    "Bal. VAT Calculation Type"::"Sales Tax":
                        if ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase) and
                           "Bal. Use Tax"
                        then begin
                            "Bal. VAT Amount" := 0;
                            "Bal. VAT %" := 0;
                            Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                        end else begin
                            "Bal. VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                "Bal. Tax Area Code", "Bal. Tax Group Code", "Bal. Tax Liable",
                                WorkDate(), "Bal. VAT Base Amount", Quantity, "Currency Factor");
                            if "Bal. VAT Base Amount" <> 0 then
                                "Bal. VAT %" := Round(100 * "Bal. VAT Amount" / "Bal. VAT Base Amount", 0.00001)
                            else
                                "Bal. VAT %" := 0;
                            "Bal. VAT Amount" :=
                              Round("Bal. VAT Amount", Currency."Amount Rounding Precision");
                            Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                        end;
                end;
                Validate(Amount);
            end;
        }
        /// <summary>
        /// Indicates whether the standard journal line is a correction entry reversing a previous transaction.
        /// </summary>
        field(73; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        /// <summary>
        /// External document number from the source document for the standard journal line.
        /// </summary>
        field(77; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Source type indicating the entity type that originated the standard journal line transaction.
        /// </summary>
        field(78; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '') or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '')
                then
                    UpdateSource()
                else
                    "Source No." := '';
            end;
        }
        /// <summary>
        /// Source number identifying the specific entity that originated the standard journal line.
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
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '') or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '')
                then
                    UpdateSource();
            end;
        }
        /// <summary>
        /// Number series code for generating posting document numbers when posting the standard journal line.
        /// </summary>
        field(80; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Tax area code determining tax jurisdiction and rates for the standard journal line transaction.
        /// </summary>
        field(82; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        /// <summary>
        /// Indicates whether the transaction is subject to tax liability for the standard journal line.
        /// </summary>
        field(83; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Tax group code determining applicable tax rates and calculation rules for the standard journal line.
        /// </summary>
        field(84; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        /// <summary>
        /// Indicates whether use tax applies to the standard journal line for purchase transactions.
        /// </summary>
        field(85; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// Tax area code for the balancing account determining tax jurisdiction and rates.
        /// </summary>
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        /// <summary>
        /// Indicates whether the balancing account is subject to tax liability for the standard journal line.
        /// </summary>
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        /// <summary>
        /// Tax group code for the balancing account determining applicable tax rates and calculation rules.
        /// </summary>
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        /// <summary>
        /// Indicates whether use tax applies to the balancing account for purchase transactions in the standard journal line.
        /// </summary>
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';

            trigger OnValidate()
            begin
                TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::Purchase);
                Validate("Bal. VAT %");
            end;
        }
        /// <summary>
        /// VAT business posting group determining VAT calculation setup for the standard journal line account.
        /// </summary>
        field(90; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("VAT Bus. Posting Group", '');

                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT product posting group determining VAT rates and calculation method for the standard journal line account.
        /// </summary>
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("VAT Prod. Posting Group", '');

                "VAT %" := 0;
                "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
                        if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                            VATPostingSetup.Init();
                        "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                        case "VAT Calculation Type" of
                            "VAT Calculation Type"::"Normal VAT":
                                "VAT %" := VATPostingSetup."VAT %";
                            "VAT Calculation Type"::"Full VAT":
                                case "Gen. Posting Type" of
                                    "Gen. Posting Type"::Sale:
                                        TestField("Account No.", VATPostingSetup.GetSalesAccount(false));
                                    "Gen. Posting Type"::Purchase:
                                        TestField("Account No.", VATPostingSetup.GetPurchAccount(false));
                                end;
                        end;
                    end;
                Validate("VAT %");
            end;
        }
        /// <summary>
        /// VAT business posting group for the balancing account determining VAT calculation setup.
        /// </summary>
        field(92; "Bal. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then
                    TestField("Bal. VAT Bus. Posting Group", '');

                Validate("Bal. VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT product posting group for the balancing account determining VAT rates and calculation method.
        /// </summary>
        field(93; "Bal. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then
                    TestField("Bal. VAT Prod. Posting Group", '');

                "Bal. VAT %" := 0;
                "Bal. VAT Calculation Type" := "Bal. VAT Calculation Type"::"Normal VAT";
                IsHandled := false;
                OnValidateBalVATProdPostingGroupOnBeforeBalVATCalculationCheck(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then begin
                        if not VATPostingSetup.Get("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group") then
                            VATPostingSetup.Init();
                        "Bal. VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                        case "Bal. VAT Calculation Type" of
                            "Bal. VAT Calculation Type"::"Normal VAT":
                                "Bal. VAT %" := VATPostingSetup."VAT %";
                            "Bal. VAT Calculation Type"::"Full VAT":
                                case "Bal. Gen. Posting Type" of
                                    "Bal. Gen. Posting Type"::Sale:
                                        TestField("Bal. Account No.", VATPostingSetup.GetSalesAccount(false));
                                    "Bal. Gen. Posting Type"::Purchase:
                                        TestField("Bal. Account No.", VATPostingSetup.GetPurchAccount(false));
                                end;
                        end;
                    end;
                Validate("Bal. VAT %");
            end;
        }
        /// <summary>
        /// Ship-to address code for customers or order address code for vendors in the standard journal line.
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
        /// Calculated difference between expected and actual VAT amount for the standard journal line.
        /// </summary>
        field(111; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Calculated difference between expected and actual VAT amount for the balancing account in the standard journal line.
        /// </summary>
        field(112; "Bal. VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code for IC transactions in the standard journal line.
        /// </summary>
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// Obsolete field replaced by IC Account No. for intercompany G/L account references.
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
        /// Sell-to customer or buy-from vendor number for document reference in the standard journal line.
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
        /// Intercompany account type specifying G/L account or bank account for IC transactions in the standard journal line.
        /// </summary>
        field(130; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Intercompany account number for IC G/L account or IC bank account transactions in the standard journal line.
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
        /// Dimension set ID linking to dimension combinations for analytical tracking of the standard journal line.
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Campaign number for marketing campaign tracking associated with the standard journal line.
        /// </summary>
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Campaign No."));
            end;
        }
        /// <summary>
        /// Indicates whether the transaction creates an index entry for cost accounting purposes in the standard journal line.
        /// </summary>
        field(5616; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Standard Journal Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
        DimMgt: Codeunit DimensionManagement;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        CurrencyCode: Code[10];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'cannot be specified without %1';
        Text006: Label 'The %1 option can only be used internally in the system.';
        Text007: Label '%1 or %2 must be a Bank Account.';
        Text008: Label ' must be 0 when %1 is %2.';
        Text010: Label '%1 must be %2 or %3.';
        Text011: Label '%1 must be negative.';
        Text012: Label '%1 must be positive.';
        Text013: Label 'The %1 must not be more than %2.';
        Text014: Label 'The %1 %2 has a %3 %4.\Do you still want to use %1 %2 in this journal line?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure UpdateLineBalance()
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
        if "Currency Code" = '' then
            "Amount (LCY)" := Amount;
    end;

    /// <summary>
    /// Validates shortcut dimension code for the specified dimension field number.
    /// </summary>
    /// <param name="FieldNumber">The dimension field number to validate (1-8).</param>
    /// <param name="ShortcutDimCode">The dimension value code to validate.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Opens lookup for shortcut dimension code for the specified dimension field number.
    /// </summary>
    /// <param name="FieldNumber">The dimension field number to lookup (1-8).</param>
    /// <param name="ShortcutDimCode">The dimension value code to lookup and modify.</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    /// <summary>
    /// Retrieves all shortcut dimension codes for the standard journal line.
    /// </summary>
    /// <param name="ShortcutDimCode">Array to populate with dimension codes for dimensions 1-8.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Opens the dimensions page for editing dimension set of the standard journal line.
    /// </summary>
    procedure ShowDimensions()
    begin
        OnBeforeShowDimensions(Rec, xRec);

        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Standard Journal Code", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    local procedure CheckGLAcc(GLAcc: Record "G/L Account")
    begin
        GLAcc.CheckGLAcc();
        if GLAcc."Direct Posting" or ("Journal Template Name" = '') then
            exit;
        GLAcc.TestField("Direct Posting", true);

        OnAfterCheckGLAcc(Rec, GLAcc);
    end;

    local procedure CheckAccount(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        ICPartner: Record "IC Partner";
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
    begin
        case AccountType of
            AccountType::"G/L Account":
                begin
                    GLAcc.Get(AccountNo);
                    CheckGLAcc(GLAcc);
                end;
            AccountType::Customer:
                begin
                    Cust.Get(AccountNo);
                    Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                end;
            AccountType::Vendor:
                begin
                    Vend.Get(AccountNo);
                    Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
                end;
            AccountType::"Bank Account":
                begin
                    BankAcc.Get(AccountNo);
                    BankAcc.TestField(Blocked, false);
                end;
            AccountType::"Fixed Asset":
                begin
                    FA.Get(AccountNo);
                    FA.TestField(Blocked, false);
                    FA.TestField(Inactive, false);
                    FA.TestField("Budgeted Asset", false);
                end;
            AccountType::"IC Partner":
                begin
                    ICPartner.Get(AccountNo);
                    ICPartner.CheckICPartner();
                end;
        end;
    end;

    local procedure CheckICPartner(ICPartnerCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        if ICPartnerCode <> '' then
            if (ICPartnerCode <> '') and ICPartner.Get(ICPartnerCode) then begin
                ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                "IC Partner Code" := ICPartnerCode;
            end;
    end;

    local procedure SetCurrencyCode(AccType2: Enum "Gen. Journal Account Type"; AccNo2: Code[20]): Boolean
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
    begin
        "Currency Code" := '';
        if AccNo2 <> '' then
            case AccType2 of
                AccType2::Customer:
                    if Cust.Get(AccNo2) then
                        "Currency Code" := Cust."Currency Code";
                AccType2::Vendor:
                    if Vend.Get(AccNo2) then
                        "Currency Code" := Vend."Currency Code";
                AccType2::"Bank Account":
                    if BankAcc.Get(AccNo2) then
                        "Currency Code" := BankAcc."Currency Code";
            end;
        exit("Currency Code" <> '');
    end;

    local procedure GetCurrency()
    begin
        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision()
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    local procedure UpdateSource()
    var
        SourceExists1: Boolean;
        SourceExists2: Boolean;
    begin
        SourceExists1 := ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '');
        SourceExists2 := ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '');
        case true of
            SourceExists1 and not SourceExists2:
                begin
                    "Source Type" := "Account Type".AsInteger();
                    "Source No." := "Account No.";
                end;
            SourceExists2 and not SourceExists1:
                begin
                    "Source Type" := "Bal. Account Type".AsInteger();
                    "Source No." := "Bal. Account No.";
                end;
            else begin
                "Source Type" := "Source Type"::" ";
                "Source No." := '';
            end;
        end;
    end;

    /// <summary>
    /// Creates dimensions from default dimension sources for the standard journal line.
    /// </summary>
    /// <param name="DefaultDimSource">List of dictionaries containing dimension source data.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := Rec."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, OldDimSetID, DefaultDimSource);
    end;

    local procedure GetDefaultICPartnerGLAccNo(): Code[20]
    var
        GLAcc: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        if "IC Partner Code" <> '' then begin
            if "Account Type" = "Account Type"::"G/L Account" then
                GLAccNo := "Account No."
            else
                GLAccNo := "Bal. Account No.";
            if GLAcc.Get(GLAccNo) then
                exit(GLAcc."Default IC Partner G/L Acc. No")
        end;
    end;

    local procedure GetGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Account No.");
        CheckGLAcc(GLAcc);
        if "Bal. Account No." = '' then
            Description := GLAcc.Name;

        if ("Bal. Account No." = '') or
           ("Bal. Account Type" in
            ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if "Bal. Account No." = '' then
            "Currency Code" := '';
        "Gen. Posting Type" := GLAcc."Gen. Posting Type";
        "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Area Code" := GLAcc."Tax Area Code";
        "Tax Liable" := GLAcc."Tax Liable";
        "Tax Group Code" := GLAcc."Tax Group Code";
        if WorkDate() = ClosingDate(WorkDate()) then begin
            "Gen. Posting Type" := "Gen. Posting Type"::" ";
            "Gen. Bus. Posting Group" := '';
            "Gen. Prod. Posting Group" := '';
            "VAT Bus. Posting Group" := '';
            "VAT Prod. Posting Group" := '';
        end;

        OnAfterGetGLAccount(Rec, GLAcc);
    end;

    local procedure GetGLBalAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Bal. Account No.");
        CheckGLAcc(GLAcc);
        if "Account No." = '' then begin
            Description := GLAcc.Name;
            "Currency Code" := '';
        end;
        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        "Bal. Gen. Posting Type" := GLAcc."Gen. Posting Type";
        "Bal. Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
        "Bal. Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "Bal. VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
        "Bal. VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Bal. Tax Area Code" := GLAcc."Tax Area Code";
        "Bal. Tax Liable" := GLAcc."Tax Liable";
        "Bal. Tax Group Code" := GLAcc."Tax Group Code";
        if WorkDate() = ClosingDate(WorkDate()) then begin
            "Bal. Gen. Bus. Posting Group" := '';
            "Bal. Gen. Prod. Posting Group" := '';
            "Bal. VAT Bus. Posting Group" := '';
            "Bal. VAT Prod. Posting Group" := '';
            "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        end;
    end;

    local procedure GetCustomerAccount()
    var
        Cust: Record Customer;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Cust.Get("Account No.");
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Account Type", "Account No.");
        Description := Cust.Name;
        "Posting Group" := Cust."Customer Posting Group";
        "Salespers./Purch. Code" := Cust."Salesperson Code";
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            Cust.TestField("Currency Code", "Currency Code")
        else
            "Currency Code" := Cust."Currency Code";
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> "Account No.") then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption(), Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
    end;

    local procedure GetCustomerBalAccount()
    var
        Cust: Record Customer;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Cust.Get("Bal. Account No.");
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        if "Account No." = '' then
            Description := Cust.Name;
        "Posting Group" := Cust."Customer Posting Group";
        "Salespers./Purch. Code" := Cust."Salesperson Code";
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Cust."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Cust."Currency Code";
        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> "Bal. Account No.") then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption(), Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
    end;

    local procedure GetVendorAccount()
    var
        Vend: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Vend.Get("Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Account Type", "Account No.");
        Description := Vend.Name;
        "Posting Group" := Vend."Vendor Posting Group";
        "Salespers./Purch. Code" := Vend."Purchaser Code";
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            Vend.TestField("Currency Code", "Currency Code")
        else
            "Currency Code" := Vend."Currency Code";
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> "Account No.") then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption(), Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
    end;

    local procedure GetVendorBalAccount()
    var
        Vend: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Vend.Get("Bal. Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        if "Account No." = '' then
            Description := Vend.Name;
        "Posting Group" := Vend."Vendor Posting Group";
        "Salespers./Purch. Code" := Vend."Purchaser Code";
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Vend."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Vend."Currency Code";
        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> "Bal. Account No.") then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption(), Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
    end;

    local procedure GetBankAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Account No.");
        BankAcc.TestField(Blocked, false);
        if "Bal. Account No." = '' then
            Description := BankAcc.Name;
        if ("Bal. Account No." = '') or
           ("Bal. Account Type" in
            ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if BankAcc."Currency Code" = '' then begin
            if "Bal. Account No." = '' then
                "Currency Code" := '';
        end else
            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                BankAcc.TestField("Currency Code", "Currency Code")
            else
                "Currency Code" := BankAcc."Currency Code";
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
    end;

    local procedure GetBankBalAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bal. Account No.");
        BankAcc.TestField(Blocked, false);
        if "Account No." = '' then
            Description := BankAcc.Name;
        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if BankAcc."Currency Code" = '' then begin
            if "Account No." = '' then
                "Currency Code" := '';
        end else
            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                BankAcc.TestField("Currency Code", "Currency Code")
            else
                "Currency Code" := BankAcc."Currency Code";
        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
    end;

    local procedure GetFAAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        Description := FA.Description;
    end;

    local procedure GetFABalAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Bal. Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        if "Account No." = '' then
            Description := FA.Description;
    end;

    local procedure GetICPartnerAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Account No.");
        ICPartner.CheckICPartner();
        Description := ICPartner.Name;
        if ("Bal. Account No." = '') or ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        "IC Partner Code" := "Account No.";
    end;

    local procedure GetICPartnerBalAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Bal. Account No.");
        if "Account No." = '' then
            Description := ICPartner.Name;

        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
        "IC Partner Code" := "Bal. Account No.";
    end;

    /// <summary>
    /// Creates dimensions from default dimension setup based on the specified field number.
    /// </summary>
    /// <param name="FromFieldNo">The field number from which to create default dimensions.</param>
    procedure CreateDimFromDefaultDim(FromFieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FromFieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Account Type".AsInteger()), Rec."Account No.", FromFieldNo = Rec.FieldNo("Account No."));
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Bal. Account Type".AsInteger()), Rec."Bal. Account No.", FromFieldNo = Rec.FieldNo("Bal. Account No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FromFieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FromFieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Campaign, Rec."Campaign No.", FromFieldNo = Rec.FieldNo("Campaign No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FromFieldNo);
    end;

    /// <summary>
    /// Integration event raised after initializing default dimension sources for standard journal line.
    /// Enables custom dimension source configuration and additional dimension setup logic.
    /// </summary>
    /// <param name="StandardGenJournalLine">Standard journal line with dimension sources initialized</param>
    /// <param name="DefaultDimSource">Collection of dimension sources for modification</param>
    /// <param name="FromFieldNo">Field number that triggered dimension source initialization</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var StandardGenJournalLine: Record "Standard General Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after retrieving G/L account for standard journal line processing.
    /// Enables custom G/L account validation and additional account-specific configuration.
    /// </summary>
    /// <param name="StandardGenJournalLine">Standard journal line with G/L account context</param>
    /// <param name="GLAcc">G/L account record retrieved for processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLAccount(var StandardGenJournalLine: Record "Standard General Journal Line"; GLAcc: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Integration event raised after validating shortcut dimension code on standard journal line.
    /// Enables custom dimension validation logic and post-validation processing.
    /// </summary>
    /// <param name="StandardGenJournalLine">Standard journal line with validated dimension</param>
    /// <param name="xStandardGenJournalLine">Previous version for comparison</param>
    /// <param name="FieldNumber">Field number of dimension being validated</param>
    /// <param name="ShortcutDimCode">Dimension code that was validated</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardGenJournalLine: Record "Standard General Journal Line"; var xStandardGenJournalLine: Record "Standard General Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised after creating dimension set for standard journal line.
    /// Enables custom dimension processing and validation after dimension creation.
    /// </summary>
    /// <param name="StandardGenJournalLine">Standard journal line with created dimensions</param>
    /// <param name="CallingFieldNo">Field that triggered dimension creation</param>
    /// <param name="xStandardGeneralJournalLine">Previous version for comparison</param>
    /// <param name="OldDimSetID">Previous dimension set ID for reference</param>
    /// <param name="DefaultDimSource">Dimension sources used for creation</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var StandardGenJournalLine: Record "Standard General Journal Line"; CallingFieldNo: Integer; xStandardGeneralJournalLine: Record "Standard General Journal Line"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]);
    begin
    end;

    /// <summary>
    /// Integration event raised before creating dimension set for standard journal line.
    /// Enables custom dimension setup logic and validation before standard creation.
    /// </summary>
    /// <param name="StandardGenJournalLine">Standard journal line for dimension creation</param>
    /// <param name="IsHandled">Set to true to skip standard dimension creation logic</param>
    /// <param name="CurrentFieldNo">Field number triggering dimension creation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var StandardGenJournalLine: Record "Standard General Journal Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after displaying dimension information for standard journal line.
    /// Enables custom processing after dimension display operations complete.
    /// </summary>
    /// <param name="StandardGenJnlLine">Standard journal line with displayed dimensions</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var StandardGenJnlLine: Record "Standard General Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before looking up shortcut dimension code on standard journal line.
    /// Enables custom dimension lookup logic and validation before standard lookup processing.
    /// </summary>
    /// <param name="StandardGenJnlLine">Standard journal line for dimension lookup</param>
    /// <param name="xStandardGenJnlLine">Previous version for comparison</param>
    /// <param name="FieldNumber">Field number triggering dimension lookup</param>
    /// <param name="ShortcutDimCode">Dimension code for lookup</param>
    /// <param name="IsHandled">Set to true to skip standard lookup processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var StandardGenJnlLine: Record "Standard General Journal Line"; xStandardGenJnlLine: Record "Standard General Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying dimension information for standard journal line.
    /// Enables custom dimension display logic and validation before showing dimensions.
    /// </summary>
    /// <param name="StandardGeneralJournalLine">Standard journal line for dimension display</param>
    /// <param name="xStandardGeneralJournalLine">Previous version for comparison</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var StandardGeneralJournalLine: Record "Standard General Journal Line"; xStandardGeneralJournalLine: Record "Standard General Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating shortcut dimension code on standard journal line.
    /// Enables custom dimension validation logic before standard validation processing.
    /// </summary>
    /// <param name="StandardGenJournalLine">Standard journal line for dimension validation</param>
    /// <param name="xStandardGenJournalLine">Previous version for comparison</param>
    /// <param name="FieldNumber">Field number being validated</param>
    /// <param name="ShortcutDimCode">Dimension code being validated</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardGenJournalLine: Record "Standard General Journal Line"; var xStandardGenJournalLine: Record "Standard General Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before VAT calculation check when validating VAT product posting group.
    /// Enables custom VAT validation logic and prevents standard VAT calculation checks.
    /// </summary>
    /// <param name="StandardGeneralJournalLine">Standard journal line with VAT product posting group</param>
    /// <param name="VATPostingSetup">VAT posting setup for validation</param>
    /// <param name="IsHandled">Set to true to skip standard VAT calculation check</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(var StandardGeneralJournalLine: Record "Standard General Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before balance VAT calculation check when validating balance VAT product posting group.
    /// Enables custom balance VAT validation logic and prevents standard balance VAT calculation checks.
    /// </summary>
    /// <param name="StandardGeneralJournalLine">Standard journal line with balance VAT product posting group</param>
    /// <param name="VATPostingSetup">VAT posting setup for balance validation</param>
    /// <param name="IsHandled">Set to true to skip standard balance VAT calculation check</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBalVATProdPostingGroupOnBeforeBalVATCalculationCheck(var StandardGeneralJournalLine: Record "Standard General Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after checking G/L account validation on standard journal line.
    /// Enables custom G/L account validation logic and post-validation processing.
    /// </summary>
    /// <param name="StandardGeneralJournalLine">Standard journal line with validated G/L account</param>
    /// <param name="GLAccount">G/L account that was checked</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var StandardGeneralJournalLine: Record "Standard General Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;
}
