// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Consolidation;
using System.Threading;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.Entity;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.Automation;
using System.IO;
using System.DateTime;
using System.Environment.Configuration;
using System.Utilities;

table 81 "Gen. Journal Line"
{
    Caption = 'Gen. Journal Line';
    Permissions = tabledata "Sales Invoice Header" = r,
                  tabledata Customer = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata "G/L Account" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Ledger Entry" = R,
                  tabledata "Data Exch. Field" = rimd;
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
        field(3; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                                       "Account Type"::"IC Partner", "Account Type"::Employee]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner", "Bal. Account Type"::Employee])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                Validate("Account No.", '');
                OnValidateAccountTypeOnBeforeCheckKeepDescription(Rec, xRec, CurrFieldNo);
                if not "Keep Description" then
                    Validate(Description, '');
                Validate("IC Account No.", '');
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account", "Account Type"::Employee] then begin
                    Validate("Gen. Posting Type", "Gen. Posting Type"::" ");
                    Validate("Gen. Bus. Posting Group", '');
                    Validate("Gen. Prod. Posting Group", '');
                end else
                    if "Bal. Account Type" in [
                                               "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');
                UpdateSource();

                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                then begin
                    "Depreciation Book Code" := '';
                    Validate("FA Posting Type", "FA Posting Type"::" ");
                end;
                if xRec."Account Type" in
                   [xRec."Account Type"::Customer, xRec."Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                    "VAT Registration No." := '';
                end;

                if "Journal Template Name" <> '' then
                    if "Account Type" = "Account Type"::"IC Partner" then begin
                        GetTemplate();
                        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                            FieldError("Account Type");
                    end;

                Validate("Deferral Code", '');
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
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
            if ("Account Type" = const("Allocation Account")) "Allocation Account"
            else
            if ("Account Type" = const(Employee)) Employee;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Account No." <> xRec."Account No.") and not (xRec."Account No." = '') then begin
                    ClearAppliedAutomatically();
                    ClearApplication("Account Type");
                    BlankJobNo(FieldNo("Account No."));
                end;

                if xRec."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"] then
                    "IC Partner Code" := '';

                if "Account No." = '' then begin
                    CleanLine();
                    exit;
                end;

                OnValidateAccountNoOnBeforeAssignValue(Rec, xRec);

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        GetGLAccount();
                    "Account Type"::Customer:
                        GetCustomerAccount();
                    "Account Type"::Vendor:
                        GetVendorAccount();
                    "Account Type"::Employee:
                        GetEmployeeAccount();
                    "Account Type"::"Bank Account":
                        GetBankAccount();
                    "Account Type"::"Fixed Asset":
                        GetFAAccount();
                    "Account Type"::"IC Partner":
                        GetICPartnerAccount();
                    "Account Type"::"Allocation Account":
                        GetAllocationAccount();
                end;

                OnValidateAccountNoOnAfterAssignValue(Rec, xRec);

                Validate("Currency Code");
                Validate("VAT Prod. Posting Group");
                UpdateLineBalance();
                UpdateSource();

                IsHandled := false;
                OnAccountNoOnValidateOnBeforeCreateDim(Rec, IsHandled);
                if IsHandled then
                    exit;

                CreateDimFromDefaultDim(FieldNo("Account No."));

                if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
                    Validate("IC Account No.", GetDefaultICPartnerGLAccNo());
                ValidateApplyRequirements(Rec);

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        UpdateAccountID();
                    "Account Type"::Customer:
                        UpdateCustomerID();
                    "Account Type"::"Bank Account":
                        UpdateBankAccountID();
                    "Account Type"::Vendor:
                        UpdateVendorID();
                end;
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                TestField("Posting Date");
                GLSetup.Get();
                GLSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");

                ValidateDocumentDateFromPostingDate();
                ValidateCurrencyCode();

                OnValidatePostingDateOnAfterValidateCurrencyCode(Rec, xRec);

                if ("Posting Date" <> xRec."Posting Date") and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);

                ValidateApplyRequirements(Rec);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                Validate("Payment Terms Code");
                if "Account No." <> '' then
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                Cust.Get("Account No.");
                                Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vend.Get("Account No.");
                                Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
                            end;
                    end;
                if "Bal. Account No." <> '' then
                    case "Bal. Account Type" of
                        "Account Type"::Customer:
                            begin
                                Cust.Get("Bal. Account No.");
                                Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vend.Get("Bal. Account No.");
                                Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
                            end;
                    end;
                UpdateSalesPurchLCY();
                ValidateApplyRequirements(Rec);
            end;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
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
                        begin
                            "VAT Amount" :=
                              Round(Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                            "VAT Base Amount" :=
                              Round(Amount - "VAT Amount", Currency."Amount Rounding Precision");
                        end;
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
                                "Posting Date", Amount, Quantity, "Currency Factor");
                            OnAfterSalesTaxCalculateReverseCalculateTax(Rec, CurrFieldNo);
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

                "VAT Amount (LCY)" := CalcVATAmountLCY();
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";
                NonDeductibleVAT.ValidateNonDedVATPctInGenJnlLine(Rec);

                OnValidateVATPctOnBeforeUpdateSalesPurchLCY(Rec, Currency);
                UpdateSalesPurchLCY();

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
        }
        field(11; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
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
            if ("Bal. Account Type" = const("Allocation Account")) "Allocation Account"
            else
            if ("Bal. Account Type" = const(Employee)) Employee;

            trigger OnValidate()
            begin
                if "Bal. Account No." <> xRec."Bal. Account No." then begin
                    ClearApplication("Bal. Account Type");
                    BlankJobNo(FieldNo("Bal. Account No."));
                end;

                if xRec."Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor,
                                                "Bal. Account Type"::"IC Partner"]
                then
                    "IC Partner Code" := '';

                if "Bal. Account No." = '' then begin
                    UpdateLineBalance();
                    UpdateSource();
                    Clear("Balance Account Id");
                    CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
                    if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
                        "Recipient Bank Account" := '';
                    if xRec."Bal. Account No." <> '' then begin
                        ClearBalancePostingGroups();
                        "Bal. Tax Area Code" := '';
                        "Bal. Tax Liable" := false;
                        "Bal. Tax Group Code" := '';
                        ClearCurrencyCode();
                    end;
                    exit;
                end;

                ReadGLSetup();
                if GLSetup."Journal Templ. Name Mandatory" then
                    if GenJnlTemplate.Name <> "Journal Template Name" then
                        GenJnlTemplate.Get("Journal Template Name");

                OnValidateBalAccountNoOnBeforeAssignValue(Rec, xRec);

                case "Bal. Account Type" of
                    "Bal. Account Type"::"G/L Account":
                        GetGLBalAccount();
                    "Bal. Account Type"::Customer:
                        GetCustomerBalAccount();
                    "Bal. Account Type"::Vendor:
                        GetVendorBalAccount();
                    "Bal. Account Type"::Employee:
                        GetEmployeeBalAccount();
                    "Bal. Account Type"::"Bank Account":
                        GetBankBalAccount();
                    "Bal. Account Type"::"Fixed Asset":
                        GetFABalAccount();
                    "Bal. Account Type"::"IC Partner":
                        GetICPartnerBalAccount();
                end;

                OnValidateBalAccountNoOnAfterAssignValue(Rec, xRec);

                Validate("Currency Code");
                Validate("Bal. VAT Prod. Posting Group");
                UpdateLineBalance();
                UpdateSource();
                CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
                UpdateBalanceAccountId();
                if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
                    Validate("IC Account No.", GetDefaultICPartnerGLAccNo());
                ValidateApplyRequirements(Rec);
            end;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
                AccCurrencyCode: Code[10];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateCurrencyCodeOnBeforeCheckBankAccountCurrencyCode(Rec, IsHandled);
                if not IsHandled then begin
                    if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                        if BankAcc.Get("Bal. Account No.") and (BankAcc."Currency Code" <> '') then
                            BankAcc.TestField("Currency Code", "Currency Code");

                    if "Account Type" = "Account Type"::"Bank Account" then
                        if BankAcc.Get("Account No.") and (BankAcc."Currency Code" <> '') then
                            BankAcc.TestField("Currency Code", "Currency Code");
                end;

                if ("Recurring Method" in
                    ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]) and
                   ("Currency Code" <> '')
                then
                    Error(
                      Text001,
                      FieldCaption("Currency Code"), FieldCaption("Recurring Method"), "Recurring Method");

                if "Currency Code" <> '' then begin
                    GetCurrency();
                    AccCurrencyCode := GetAccCurrencyCode();
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Posting Date" <> xRec."Posting Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0) or
                       (("Currency Code" <> AccCurrencyCode) and (AccCurrencyCode <> ''))
                    then begin
                        OnValidateCurrencyCodeOnBeforeUpdateCurrencyFactor(Rec, CurrExchRate);
                        "Currency Factor" := CurrExchRate.ExchangeRate("Posting Date", "Currency Code");
                    end;
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");

                if not CustVendAccountNosModified() then
                    if ("Currency Code" <> xRec."Currency Code") and (Amount <> 0) then
                        PaymentToleranceMgt.PmtTolGenJnl(Rec);
            end;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                ValidateAmount();
            end;
        }
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
                if ("Credit Amount" = 0) or ("Debit Amount" <> 0) then begin
                    Amount := "Debit Amount";
                    Validate(Amount);
                end;
            end;
        }
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
                if ("Debit Amount" = 0) or ("Credit Amount" <> 0) then begin
                    Amount := -"Credit Amount";
                    Validate(Amount);
                end;
            end;
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAmountLCY(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end else begin
                    if CheckFixedCurrency() then begin
                        GetCurrency();
                        Amount := Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              "Posting Date", "Currency Code",
                              "Amount (LCY)", "Currency Factor"),
                            Currency."Amount Rounding Precision")
                    end else begin
                        TestField("Amount (LCY)");
                        TestField(Amount);
                        "Currency Factor" := Amount / "Amount (LCY)";
                    end;

                    Validate("VAT %");
                    Validate("Bal. VAT %");
                    UpdateLineBalance();
                end;

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(17; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Balance (LCY)';
            Editable = false;
        }
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
        field(19; "Sales/Purch. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales/Purch. (LCY)';
        }
        field(20; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Profit (LCY)';
        }
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Inv. Discount (LCY)';
        }
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

            trigger OnValidate()
            begin
                if "Bill-to/Pay-to No." <> xRec."Bill-to/Pay-to No." then
                    "Ship-to/Order Address Code" := '';
                ReadGLSetup();
                if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then
                    UpdateCountryCodeAndVATRegNo("Bill-to/Pay-to No.");
            end;
        }
        field(23; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Account Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Account Type" = const("Fixed Asset")) "FA Posting Group"
            else
            if ("Account Type" = const(Employee)) "Employee Posting Group";

            trigger OnValidate()
            begin
                CheckPostingGroupChange();
            end;
        }
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
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateSalesPersonPurchaserCode(Rec);

                CreateDimFromDefaultDim(FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(28; "Pending Approval"; Boolean)
        {
            Caption = 'Pending Approval';
            Editable = false;
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
        field(31; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = CustomerContent;
        }
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAppliesToDocType(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;
                if "Applies-to Doc. Type" <> xRec."Applies-to Doc. Type" then
                    Validate("Applies-to Doc. No.", '');
            end;
        }
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
                AccType: Enum "Gen. Journal Account Type";
                AccNo: Code[20];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                xRec.Amount := Amount;
                xRec."Currency Code" := "Currency Code";
                xRec."Posting Date" := "Posting Date";

                GetAccTypeAndNo(Rec, AccType, AccNo);
                Clear(CustLedgEntry);
                Clear(VendLedgEntry);

                case AccType of
                    AccType::Customer:
                        LookUpAppliesToDocCust(AccNo);
                    AccType::Vendor:
                        LookUpAppliesToDocVend(AccNo);
                    AccType::Employee:
                        LookUpAppliesToDocEmpl(AccNo);
                end;
                SetJournalLineFieldsFromApplication();

                OnLookupAppliestoDocNoOnAfterSetJournalLineFieldsFromApplication(Rec);

                if xRec.Amount <> 0 then
                    if not PaymentToleranceMgt.PmtTolGenJnl(Rec) then
                        exit;

                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    UpdateAppliesToInvoiceID();
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
                TempGenJnlLine: Record "Gen. Journal Line" temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAppliesToDocNo(Rec, xRec, CurrFieldNo, SuppressCommit, IsHandled);
                if IsHandled then
                    exit;
                if SuppressCommit then
                    PaymentToleranceMgt.SetSuppressCommit(true);

                if "Applies-to Doc. No." <> xRec."Applies-to Doc. No." then
                    ClearCustVendApplnEntry();

                if ("Applies-to Doc. No." = '') and (xRec."Applies-to Doc. No." <> '') then begin
                    PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec, xRec."Applies-to Doc. No.");

                    TempGenJnlLine := Rec;
                    if (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) or
                       (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor) or
                       (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Employee)
                    then
                        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);

                    OnAppliesToDocNoOnValidateOnBeforeUpdAmtToEntries(Rec, TempGenJnlLine);

                    case TempGenJnlLine."Account Type" of
                        TempGenJnlLine."Account Type"::Customer:
                            begin
                                CustLedgEntry.SetCurrentKey("Document No.");
                                CustLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    CustLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                                CustLedgEntry.SetRange(Open, true);
                                OnAppliesToDocNoOnValidateOnAfterCustLedgEntrySetFilters(Rec, CustLedgEntry, TempGenJnlLine);
                                if CustLedgEntry.FindFirst() then begin
                                    if CustLedgEntry."Amount to Apply" <> 0 then begin
                                        CustLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                                    end;
                                    "Exported to Payment File" := CustLedgEntry."Exported to Payment File";
                                    "Applies-to Ext. Doc. No." := '';
                                end;
                            end;
                        TempGenJnlLine."Account Type"::Vendor:
                            begin
                                VendLedgEntry.SetCurrentKey("Document No.");
                                VendLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    VendLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                                VendLedgEntry.SetRange(Open, true);
                                OnAppliesToDocNoOnValidateOnAfterVendLedgEntrySetFilters(Rec, VendLedgEntry);
                                if VendLedgEntry.FindFirst() then begin
                                    if VendLedgEntry."Amount to Apply" <> 0 then begin
                                        VendLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                                    end;
                                    "Exported to Payment File" := VendLedgEntry."Exported to Payment File";
                                end;
                                "Applies-to Ext. Doc. No." := '';
                            end;
                        TempGenJnlLine."Account Type"::Employee:
                            begin
                                EmplLedgEntry.SetCurrentKey("Document No.");
                                EmplLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    EmplLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                EmplLedgEntry.SetRange("Employee No.", TempGenJnlLine."Account No.");
                                EmplLedgEntry.SetRange(Open, true);
                                OnAppliesToDocNoValidateOnAfterEmplLedgEntrySetFilters(Rec, EmplLedgEntry);
                                if EmplLedgEntry.FindFirst() then begin
                                    if EmplLedgEntry."Amount to Apply" <> 0 then begin
                                        EmplLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmplLedgEntry);
                                    end;
                                    "Exported to Payment File" := EmplLedgEntry."Exported to Payment File";
                                end;
                            end;
                        else
                            OnAppliesToDocNoOnValidateOnCaseElse(Rec, xRec, TempGenJnlLine);
                    end;
                    OnAppliesToDocNoOnValidateOnAfterUpdAmtToEntries(Rec, TempGenJnlLine);
                end;

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (Amount <> 0) then begin
                    if xRec."Applies-to Doc. No." <> '' then begin
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec, xRec."Applies-to Doc. No.");
                        OnValidateAppliesToDocNoOnAfterDelPmtToApplnDocNo(Rec, xRec);
                    end;
                    SetApplyToAmount();
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);
                    xRec.ClearAppliedGenJnlLine();
                end;

                case "Account Type" of
                    "Account Type"::Customer:
                        GetCustLedgerEntry();
                    "Account Type"::Vendor:
                        GetVendLedgerEntry();
                    "Account Type"::Employee:
                        GetEmplLedgerEntry();
                end;

                OnAppliesToDocNoOnValidateOnBeforeValidateApplyRequirements(Rec);
                ValidateApplyRequirements(Rec);
                SetJournalLineFieldsFromApplication();

                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    UpdateAppliesToInvoiceID();
                OnAfterValidateAppliesToDocNo(Rec, xRec, CurrFieldNo, SuppressCommit);
            end;
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
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(42; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateJobNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Job No." = xRec."Job No." then
                    exit;

                SourceCodeSetup.Get();
                if "Source Code" <> SourceCodeSetup."Job G/L WIP" then
                    Validate("Job Task No.", '');
                if "Job No." = '' then begin
                    CreateDimFromDefaultDim(FieldNo("Job No."));
                    exit;
                end;

                CheckAccountTypeOnJobValidation();

                CheckBalAccountNoOnJobNoValidation();

                AssignJobCurrencyCode();

                CreateDimFromDefaultDim(FieldNo("Job No."));
            end;
        }
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
        field(44; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                GenJnlBatch.TestField("Allow VAT Difference", true);
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

                "VAT Amount (LCY)" := CalcVATAmountLCY();
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";
                NonDeductibleVAT.ValidateNonDedVATPctInGenJnlLine(Rec);

                UpdateSalesPurchLCY();

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
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

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                "Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Payment Discount %" := 0;
                if ("Account Type" <> "Account Type"::"G/L Account") or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                then
                    case "Document Type" of
                        "Document Type"::Invoice:
                            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                                PaymentTerms.Get("Payment Terms Code");
                                IsHandled := false;
                                OnValidatePaymentTermsCodeOnBeforeCalculateDueDate(Rec, PaymentTerms, IsHandled);
                                if not IsHandled then
                                    "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                                IsHandled := false;
                                OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(Rec, PaymentTerms, IsHandled);
                                if not IsHandled then
                                    "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                                "Payment Discount %" := PaymentTerms."Discount %";
                            end else
                                "Due Date" := "Document Date";
                        "Document Type"::"Credit Memo":
                            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                                PaymentTerms.Get("Payment Terms Code");
                                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                                    IsHandled := false;
                                    OnValidatePaymentTermsCodeOnBeforeCalculateDueDate(Rec, PaymentTerms, IsHandled);
                                    if not IsHandled then
                                        "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                                    IsHandled := false;
                                    OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(Rec, PaymentTerms, IsHandled);
                                    if not IsHandled then
                                        "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                                    "Payment Discount %" := PaymentTerms."Discount %";
                                end else
                                    "Due Date" := "Document Date";
                            end else
                                "Due Date" := "Document Date";
                        else
                            "Due Date" := "Document Date";
                    end;
            end;
        }
        field(48; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            begin
                if "Applies-to ID" <> xRec."Applies-to ID" then
                    if ShouldClearCustVendApplnEntry() then
                        ClearCustVendApplnEntry();
                SetJournalLineFieldsFromApplication();
            end;
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

            trigger OnValidate()
            begin
                UpdateJournalBatchID();
            end;
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Recurring Method"; Enum "Gen. Journal Recurring Method")
        {
            BlankZero = true;
            Caption = 'Recurring Method';

            trigger OnValidate()
            begin
                if "Recurring Method" in
                   ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]
                then
                    TestField("Currency Code", '');
                UpdateSalesPurchLCY();

                CheckRecurringDimensionsAndFilters();
                ShowSetDimFiltersNotification();
            end;
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
        field(57; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty := "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"];
                OnBeforeValidateGenPostingType(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Gen. Posting Type", "Gen. Posting Type"::" ");
                if ("Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Gen. Posting Type");
                CheckVATInAlloc();
                if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                    Validate("VAT Prod. Posting Group");
                if "Gen. Posting Type" <> "Gen. Posting Type"::Purchase then
                    Validate("Use Tax", false)
            end;
        }
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty := "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"];
                OnBeforeValidateGenBusPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Gen. Bus. Posting Group", '');
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(59; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty := "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"];
                OnBeforeValidateGenProdPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Gen. Prod. Posting Group", '');
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
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
        field(63; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                                       "Account Type"::"IC Partner", "Account Type"::Employee]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner", "Bal. Account Type"::Employee])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                ReadGLSetup();
                if GLSetup."Journal Templ. Name Mandatory" then
                    if GenJnlTemplate.Name <> "Journal Template Name" then
                        GenJnlTemplate.Get("Journal Template Name");

                OnValidateBalAccountTypeOnBeforeSetBalAccountNo(Rec, xRec);

                Validate("Bal. Account No.", '');
                Validate("IC Account No.", '');
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account", "Bal. Account Type"::Employee]
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
                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                then begin
                    "Depreciation Book Code" := '';
                    Validate("FA Posting Type", "FA Posting Type"::" ");
                end;
                if xRec."Bal. Account Type" in
                   [xRec."Bal. Account Type"::Customer, xRec."Bal. Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                    "VAT Registration No." := '';
                end;
                if ("Account Type" in [
                                       "Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]) and
                   ("Bal. Account Type" in [
                                            "Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"])
                then
                    Validate("Payment Terms Code", '');

                if "Bal. Account Type" = "Bal. Account Type"::"IC Partner" then begin
                    GetTemplate();
                    if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                        FieldError("Bal. Account Type");
                end;
            end;
        }
        field(64; "Bal. Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Bal. Gen. Posting Type';

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty :=
                  "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"];
                OnBeforeValidateBalGenPostingType(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                if ("Bal. Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Bal. Gen. Posting Type");
                if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                    Validate("Bal. VAT Prod. Posting Group");

                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                then begin
                    "Depreciation Book Code" := '';
                    Validate("FA Posting Type", "FA Posting Type"::" ");
                end;
                if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::Purchase then
                    Validate("Bal. Use Tax", false);
            end;
        }
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty :=
                  "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"];
                OnBeforeValidateBalGenBusPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Bal. Gen. Bus. Posting Group", '');
                if xRec."Bal. Gen. Bus. Posting Group" <> "Bal. Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Bal. Gen. Bus. Posting Group") then
                        Validate("Bal. VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(66; "Bal. Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty :=
                  "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"];
                OnBeforeValidateBalGenProdPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Bal. Gen. Prod. Posting Group", '');
                if xRec."Bal. Gen. Prod. Posting Group" <> "Bal. Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Bal. Gen. Prod. Posting Group") then
                        Validate("Bal. VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(67; "Bal. VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
        }
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
                        begin
                            "Bal. VAT Amount" :=
                              Round(-Amount * "Bal. VAT %" / (100 + "Bal. VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                            "Bal. VAT Base Amount" :=
                              Round(-Amount - "Bal. VAT Amount", Currency."Amount Rounding Precision");
                        end;
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
                                  "Posting Date", Amount, Quantity, "Currency Factor"));
                            OnAfterSalesTaxCalculateReverseCalculateTax(Rec, CurrFieldNo);
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

                if "Currency Code" = '' then
                    "Bal. VAT Amount (LCY)" := "Bal. VAT Amount"
                else
                    "Bal. VAT Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", "Bal. VAT Amount", "Currency Factor"));
                OnValidateBalVATPctOnAfterAssignBalVATAmountLCY("Bal. VAT Amount (LCY)");
                "Bal. VAT Base Amount (LCY)" := -("Amount (LCY)" + "Bal. VAT Amount (LCY)");
                NonDeductibleVAT.ValidateBalNonDedVATPctInGenJnlLine(Rec);

                OnValidateVATPctOnBeforeUpdateSalesPurchLCY(Rec, Currency);
                UpdateSalesPurchLCY();
            end;
        }
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';

            trigger OnValidate()
            begin
                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                GenJnlBatch.TestField("Allow VAT Difference", true);
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

                if "Currency Code" = '' then
                    "Bal. VAT Amount (LCY)" := "Bal. VAT Amount"
                else
                    "Bal. VAT Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "Bal. VAT Amount", "Currency Factor"));
                "Bal. VAT Base Amount (LCY)" := -("Amount (LCY)" + "Bal. VAT Amount (LCY)");
                NonDeductibleVAT.ValidateBalNonDedVATPctInGenJnlLine(Rec);

                UpdateSalesPurchLCY();
            end;
        }
        field(70; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            AccessByPermission = TableData "Bank Account" = R;
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

                if Rec."Bank Payment Type" <> xRec."Bank Payment Type" then
                    Rec.DeletePaymentFileErrors();
            end;
        }
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
                                "Tax Area Code", "Tax Group Code", "Tax Liable", "Posting Date",
                                "VAT Base Amount", Quantity, "Currency Factor");
                            OnAfterSalesTaxCalculateCalculateTax(Rec, CurrFieldNo);
                            if "VAT Base Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" :=
                              Round("VAT Amount", Currency."Amount Rounding Precision");
                            Amount := "VAT Base Amount" + "VAT Amount";
                        end;
                end;
                OnValidateVATBaseAmountOnBeforeValidateAmount(Rec, Currency);
                Validate(Amount);
            end;
        }
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
                                "Posting Date", "Bal. VAT Base Amount", Quantity, "Currency Factor");
                            OnAfterSalesTaxCalculateCalculateTax(Rec, CurrFieldNo);
                            if "Bal. VAT Base Amount" <> 0 then
                                "Bal. VAT %" := Round(100 * "Bal. VAT Amount" / "Bal. VAT Base Amount", 0.00001)
                            else
                                "Bal. VAT %" := 0;
                            "Bal. VAT Amount" :=
                              Round("Bal. VAT Amount", Currency."Amount Rounding Precision");
                            Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                        end;
                end;
                OnValidateBalVATBaseAmountOnBeforeValidateAmount(Rec, Currency);
                Validate(Amount);
            end;
        }
        field(73; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(74; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        field(75; "Check Printed"; Boolean)
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Check Printed';
            Editable = false;
        }
        field(76; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                GLSetup.Get();
                GLSetup.UpdateVATDate("Document Date", Enum::"VAT Reporting Date"::"Document Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");

                Validate("Payment Terms Code");
            end;
        }
        field(77; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(78; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';

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

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '') or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '')
                then
                    UpdateSource();
            end;
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

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(83; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(84; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(85; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                if not "Use Tax" then
                    exit;
                TestField("Gen. Posting Type", "Gen. Posting Type"::Purchase);
                Validate("VAT %");
            end;
        }
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("Bal. VAT %");
            end;
        }
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';

            trigger OnValidate()
            begin
                Validate("Bal. VAT %");
            end;
        }
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("Bal. VAT %");
            end;
        }
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';

            trigger OnValidate()
            begin
                if not "Bal. Use Tax" then
                    exit;
                TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::Purchase);
                Validate("Bal. VAT %");
            end;
        }
        field(90; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("VAT Bus. Posting Group", '');

                Validate("VAT Prod. Posting Group");

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATProdPostingGroup(Rec, IsHandled);
                if IsHandled then
                    exit;

                CheckEmptyVATProdPostingGroup();

                CheckVATInAlloc();

                "VAT %" := 0;
                "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
                        GetVATPostingSetup("VAT Bus. Posting Group", "VAT Prod. Posting Group");
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

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
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
                        GetVATPostingSetup("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group");
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
        field(95; "Additional-Currency Posting"; Option)
        {
            Caption = 'Additional-Currency Posting';
            Editable = false;
            OptionCaption = 'None,Amount Only,Additional-Currency Amount Only';
            OptionMembers = "None","Amount Only","Additional-Currency Amount Only";
        }
        field(98; "FA Add.-Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
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
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            Editable = false;
        }
        field(101; "Source Curr. VAT Base Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Base Amount';
            Editable = false;
        }
        field(102; "Source Curr. VAT Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Amount';
            Editable = false;
        }
        field(103; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(104; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(105; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(106; "Bal. VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Bal. VAT Amount (LCY)';
            Editable = false;
        }
        field(107; "Bal. VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
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
            TableRelation = if ("Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."))
            else
            if ("Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."))
            else
            if ("Bal. Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."));
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
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(114; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
#if not CLEANSCHEMA25
        field(116; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            Editable = false;
        }
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

            trigger OnValidate()
            begin
                ReadGLSetup();
                if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No." then
                    UpdateCountryCodeAndVATRegNo("Sell-to/Buy-from No.");
            end;
        }
        field(119; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
            begin
                VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", '', 0);
            end;
        }
        field(120; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Validate("VAT Registration No.");
            end;
        }
        field(121; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(122; "Financial Void"; Boolean)
        {
            Caption = 'Financial Void';
            Editable = false;
        }
        field(123; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            Editable = false;
            InitValue = true;
        }
        field(125; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            Editable = false;
        }
        field(126; "Orig. Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
        }
        field(127; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Orig. Pmt. Disc. Possible (LCY)';
        }
        field(128; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = true;

            trigger OnValidate()
            begin
                InitVATDateIfEmpty();
            end;
        }
        field(129; "Zero Src. Curr. Amount"; Boolean)
        {
            Caption = 'Zero Source Currency Amount';
            Editable = false;
        }
        field(130; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
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
        field(160; "Job Queue Status"; Enum "Document Job Queue Status")
        {
            Caption = 'Job Queue Status';
            Editable = false;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if Description = '' then
                    Description := CopyStr(IncomingDocument.Description, 1, MaxStrLen(Description));
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;

                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    IncomingDocument.SetGenJournalLine(Rec);
            end;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                UpdatePaymentMethodId();
            end;
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(175; "Invoice Received Date"; Date)
        {


            trigger OnValidate()
            begin
                if (Rec."Invoice Received Date" <> 0D) and
                   (("Account Type" = "Account Type"::Vendor) or ("Bal. Account Type" = "Bal. Account Type"::Vendor))
                then
                    TestField("Document Type", "Document Type"::Invoice);
            end;
        }
        field(180; "Keep Description"; Boolean)
        {
            Caption = 'Keep Description';
            Editable = false;
        }
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
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            Editable = false;
        }
        field(291; "Has Payment Export Error"; Boolean)
        {
            CalcFormula = exist("Payment Jnl. Export Error Text" where("Journal Template Name" = field("Journal Template Name"),
                                                                        "Journal Batch Name" = field("Journal Batch Name"),
                                                                        "Journal Line No." = field("Line No.")));
            Caption = 'Has Payment Export Error';
            Editable = false;
            FieldClass = FlowField;
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
        field(1000; "Remit-to Code"; Code[20])
        {
            Caption = 'Remit-to Code';
            TableRelation = "Remit Address".Code where("Vendor No." = field("Sell-to/Buy-from No."));
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Job Task No." <> xRec."Job Task No." then
                    Validate("Job Planning Line No.", 0);
                if "Job Task No." = '' then begin
                    ClearJobRelatedAmounts();
                    exit;
                end;

                OnValidateJobTaskNoOnBeforeJobTaskIsSet(Rec);
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    CopyDimensionsFromJobTaskLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1002; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            Caption = 'Project Unit Price (LCY)';
            Editable = false;
        }
        field(1003; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Total Price (LCY)';
            Editable = false;
        }
        field(1004; "Job Quantity"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 0;
            Caption = 'Project Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    if "Job Planning Line No." <> 0 then
                        Validate("Job Planning Line No.");
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1005; "Job Unit Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Project Unit Cost (LCY)';
            Editable = false;
        }
        field(1006; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 0;
            Caption = 'Project Line Discount %';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount %", "Job Line Discount %");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1007; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Project Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount Amount (LCY)", "Job Line Disc. Amount (LCY)");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1008; "Job Unit Of Measure Code"; Code[10])
        {
            Caption = 'Project Unit Of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(1009; "Job Line Type"; Enum "Job Line Type")
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Type';

            trigger OnValidate()
            begin
                if "Job Planning Line No." <> 0 then
                    Error(Text019, FieldCaption("Job Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(1010; "Job Unit Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Project Unit Price';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Unit Price", "Job Unit Price");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1011; "Job Total Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Total Price';
            Editable = false;
        }
        field(1012; "Job Unit Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Project Unit Cost';
            Editable = false;
        }
        field(1013; "Job Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Total Cost';
            Editable = false;
        }
        field(1014; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Line Discount Amount';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount Amount", "Job Line Discount Amount");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1015; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = Rec."Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Line Amount';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Amount", "Job Line Amount");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1016; "Job Total Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Total Cost (LCY)';
            Editable = false;
        }
        field(1017; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Amount (LCY)", "Job Line Amount (LCY)");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1018; "Job Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Project Currency Factor';
        }
        field(1019; "Job Currency Code"; Code[10])
        {
            Caption = 'Project Currency Code';

            trigger OnValidate()
            begin
                if ("Job Currency Code" <> xRec."Job Currency Code") or ("Job Currency Code" <> '') then
                    if JobTaskIsSet() then begin
                        CreateTempJobJnlLine();
                        UpdatePricesFromJobJnlLine();
                    end;
            end;
        }
        field(1020; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
                JobPlanningLine.SetRange("No.", "Account No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);
                OnLookupJobPlanningLineNoOnAfterJobPlanningLineSetFilter(JobPlanningLine, Rec);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobPlanningLineNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                    JobPlanningLine.TestField("No.", "Account No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);
                    "Job Line Type" := JobPlanningLine.ConvertToJobLineType();
                    Validate("Job Remaining Qty.", JobPlanningLine."Remaining Qty." - "Job Quantity");
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 0;
            Caption = 'Project Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Job Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text018, FieldCaption("Job Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Job Remaining Qty." < 0 then
                            "Job Remaining Qty." := 0;
                    end else
                        if "Job Remaining Qty." > 0 then
                            "Job Remaining Qty." := 0;
                end;
            end;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = if ("Account Type" = const(Customer)) "SEPA Direct Debit Mandate" where("Customer No." = field("Account No."));

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if "Direct Debit Mandate ID" = '' then
                    exit;
                TestField("Account Type", "Account Type"::Customer);
                SEPADirectDebitMandate.Get("Direct Debit Mandate ID");
                SEPADirectDebitMandate.TestField("Customer No.", "Account No.");
                "Recipient Bank Account" := SEPADirectDebitMandate."Customer Bank Account Code";
            end;
        }
        field(1220; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(1221; "Payer Information"; Text[50])
        {
            Caption = 'Payer Information';
        }
        field(1222; "Transaction Information"; Text[100])
        {
            Caption = 'Transaction Information';
        }
        field(1223; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(1224; "Applied Automatically"; Boolean)
        {
            Caption = 'Applied Automatically';
        }
        field(1300; "Linked Table ID"; Integer)
        {
            Caption = 'Linked Table ID';
            Editable = false;
        }
        field(1301; "Linked System ID"; Guid)
        {
            Caption = 'Linked System ID';
            Editable = false;
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
                DeferralUtilities: Codeunit "Deferral Utilities";
                DeferralPostDate: Date;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDeferralCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Deferral Code" <> '' then
                    if Rec."Account Type" = Rec."Account Type"::"Allocation Account" then begin
                        Rec.TestField("Account No.");
                        if not GenJournalAllocAccMgt.VerifyAllGLAccountsUsed(Rec) then
                            Error(MustUseAllGLAccountsAsDestinationAccountsAllocAccErr);
                    end else
                        Rec.TestField("Account Type", "Account Type"::"G/L Account");
                DeferralUtilities.CheckDeferralConditionForGenJournal(Rec);
                DeferralPostDate := GetDeferralPostDate();

                DeferralUtilities.DeferralCodeOnValidate(
                    "Deferral Code", DeferralDocType::"G/L".AsInteger(), "Journal Template Name", "Journal Batch Name",
                    0, '', "Line No.", GetDeferralAmount(), DeferralPostDate, Description, "Currency Code");
            end;
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
        }
        field(2676; "Selected Alloc. Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(2677; "Alloc. Acc. Modified by User"; Boolean)
        {
            Caption = 'Allocation Account Distributions Modified';
            FieldClass = FlowField;
            CalcFormula = exist(Microsoft.Finance.AllocationAccount."Alloc. Acc. Manual Override" where("Parent System Id" = field(SystemId), "Parent Table Id" = const(Database::"Gen. Journal Line")));
        }
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Posting Allocation Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(2679; "Alloc. Journal Line SystemId"; Guid)
        {
            Caption = 'Allocation Journal Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCampaignNo(Rec, IsHandled);
                if IsHandled then
                    exit;

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
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Gen. Journal Line FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';

            trigger OnValidate()
            begin
                if not (("Account Type" = "Account Type"::"Fixed Asset") or
                         ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")) and
                   ("FA Posting Type" = "FA Posting Type"::" ")
                then begin
                    "FA Posting Date" := 0D;
                    "Salvage Value" := 0;
                    "No. of Depreciation Days" := 0;
                    "Depr. until FA Posting Date" := false;
                    "Depr. Acquisition Cost" := false;
                    "Maintenance Code" := '';
                    "Insurance No." := '';
                    "Budgeted FA No." := '';
                    "Duplicate in Depreciation Book" := '';
                    "Use Duplication List" := false;
                    "FA Reclassification Entry" := false;
                    "FA Error Entry No." := 0;
                end;

                if "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" then
                    TestField("Insurance No.", '');
                if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                    TestField("Maintenance Code", '');
                GetFAVATSetup();
                GetFAAddCurrExchRate();
            end;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if "Depreciation Book Code" = '' then
                    exit;

                if ("Account No." <> '') and
                   ("Account Type" = "Account Type"::"Fixed Asset")
                then begin
                    FADeprBook.Get("Account No.", "Depreciation Book Code");
                    "Posting Group" := FADeprBook."FA Posting Group";
                end;

                if ("Bal. Account No." <> '') and
                   ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")
                then begin
                    FADeprBook.Get("Bal. Account No.", "Depreciation Book Code");
                    "Posting Group" := FADeprBook."FA Posting Group";
                end;
                GetFAVATSetup();
                GetFAAddCurrExchRate();
            end;
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5604; "No. of Depreciation Days"; Integer)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;

            trigger OnValidate()
            begin
                if "Maintenance Code" <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::Maintenance);
            end;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;

            trigger OnValidate()
            begin
                if "Insurance No." <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
            end;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            var
                FA: Record "Fixed Asset";
            begin
                if "Budgeted FA No." <> '' then begin
                    FA.Get("Budgeted FA No.");
                    FA.TestField("Budgeted Asset", true);
                end;
            end;
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(5614; "FA Reclassification Entry"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
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
        field(5617; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(5618; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        field(5701; "Check Exported"; Boolean)
        {
            Caption = 'Check Exported';
        }
        field(5702; "Check Transmitted"; Boolean)
        {
            Caption = 'Check Transmitted';
        }
        field(5703; "Reverse Date Calculation"; DateFormula)
        {
            Caption = 'Reverse Date Calculation';

            trigger OnValidate()
            var
                GenJournalTemplate: Record "Gen. Journal Template";
            begin
                if Format("Reverse Date Calculation") = '' then
                    exit;

                GenJournalTemplate.Get("Journal Template Name");
                GenJournalTemplate.TestField(Recurring);
                if not ("Recurring Method" in ["Recurring Method"::"RF Reversing Fixed", "Recurring Method"::"RV Reversing Variable", "Recurring Method"::"RB Reversing Balance"]) then
                    FieldError("Recurring Method");
            end;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                GetCurrency();
                NonDeductibleVAT.Calculate(Rec, Currency);
            end;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base';
            Editable = false;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6203; "Non-Deductible VAT Base LCY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base LCY';
            Editable = false;
        }
        field(6204; "Non-Deductible VAT Amount LCY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount LCY';
            Editable = false;
        }
        field(6205; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base ACY';
            Editable = false;
        }
        field(6206; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
            Editable = false;
        }
        field(6207; "FA G/L Account No."; Code[20])
        {
            Caption = 'FA G/L Account No.';
            Editable = false;
        }
        field(6208; "Non-Deductible VAT Diff."; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
        field(6209; "Bal. Non-Ded. VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Bal. Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                GetCurrency();
                NonDeductibleVAT.CalculateBalAcc(Rec, Currency);
            end;
        }
        field(6210; "Bal. Non-Ded. VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Bal. Non-Deductible VAT Base';
            Editable = false;
        }
        field(6211; "Bal. Non-Ded. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Bal. Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6212; "Bal. Non-Ded. VAT Base LCY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. Non-Deductible VAT Base LCY';
            Editable = false;
        }
        field(6213; "Bal. Non-Ded. VAT Amount LCY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. Non-Deductible VAT Amount LCY';
            Editable = false;
        }
        field(6230; "Non-Ded. VAT FA Cost"; Boolean)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Ded. VAT FA Cost';
        }
        field(8001; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".SystemId;

            trigger OnValidate()
            begin
                UpdateAccountNo();
            end;
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            begin
                UpdateCustomerNo();
            end;
        }
        field(8003; "Applies-to Invoice Id"; Guid)
        {
            Caption = 'Applies-to Invoice Id';
            TableRelation = "Sales Invoice Entity Aggregate".Id;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                UpdateAppliesToInvoiceNo();
            end;
        }
        field(8004; "Contact Graph Id"; Text[250])
        {
            Caption = 'Contact Graph Id';
        }
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        field(8006; "Journal Batch Id"; Guid)
        {
            Caption = 'Journal Batch Id';
            TableRelation = "Gen. Journal Batch".SystemId;

            trigger OnValidate()
            begin
                UpdateJournalBatchName();
            end;
        }
        field(8007; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';
            TableRelation = "Payment Method".SystemId;

            trigger OnValidate()
            begin
                UpdatePaymentMethodCode();
            end;
        }
        field(8008; "Balance Account Id"; Guid)
        {
            Caption = 'Balance Account Id';
            TableRelation = "G/L Account".SystemId;

            trigger OnValidate()
            begin
                UpdateBalanceAccountNo();
            end;
        }
        field(8009; "Vendor Id"; Guid)
        {
            Caption = 'Vendor Id';
            TableRelation = Vendor.SystemId;

            trigger OnValidate()
            begin
                UpdateVendorNo();
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.")
        {
            IncludedFields = "Debit Amount", "Credit Amount", "Document Type";
        }
        key(Key3; "Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.")
        {
        }
        key(Key4; "Document No.")
        {
            IncludedFields = "Debit Amount", "Credit Amount";
        }
        key(Key5; "Incoming Document Entry No.")
        {
        }
        key(Key6; "Document No.", "Posting Date", "Source Code")
        {
            IncludedFields = "VAT Amount (LCY)", "Bal. VAT Amount (LCY)";
        }
        key(Key7; "Data Exch. Entry No.")
        {
        }
        key(Key8; "Journal Batch Name", "Journal Template Name")
        {
            IncludedFields = "Balance (LCY)", Amount, "Amount (LCY)";
        }
        key(Key9; "Source Code", "Document No.", "Posting Date")
        {
            IncludedFields = "VAT Amount (LCY)", "Bal. VAT Amount (LCY)";
        }
        key(Key10; "Bal. Account No.", "Bal. Account Type")
        {
            IncludedFields = Amount;
        }
        key(key11; "Document No.", "Account No.", "Applies-to ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckJobQueueStatus(Rec);
        ApprovalsMgmt.PreventDeletingRecordWithOpenApprovalEntry(Rec);

        // Lines are deleted 1 by 1, this actually check if this is the last line in the General journal Bach
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        if GenJournalLine.IsEmpty() then
            if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                ApprovalsMgmt.PreventDeletingRecordWithOpenApprovalEntry(GenJournalBatch);

        TestField("Check Printed", false);

        IsHandled := false;
        OnDeleteOnBeforeClearCustVendApplnEntry(Rec, GenJournalBatch, GenJnlAlloc, IsHandled);
        if not IsHandled then begin
            ClearCustVendApplnEntry();
            ClearAppliedGenJnlLine();
            DeleteRelatedPaymentFileErrors();
            ClearDataExchangeEntries(false);

            GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
            if not GenJnlAlloc.IsEmpty() then
                GenJnlAlloc.DeleteAll();
        end;

        DeferralUtilities.DeferralCodeOnDelete(
            DeferralDocType::"G/L".AsInteger(),
            "Journal Template Name", "Journal Batch Name", 0, '', "Line No.");

        Rec.Validate("Incoming Document Entry No.", 0);

        RecallSetDimFiltersNotification();
        DeleteGenJnlDimFilters();
    end;

    trigger OnInsert()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJnlAlloc.LockTable();
        LockTable();

        if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            ApprovalsMgmt.PreventInsertRecIfOpenApprovalEntryExist(GenJournalBatch);

        SetLastModifiedDateTime();

        GenJnlTemplate.Get("Journal Template Name");
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        "Copy VAT Setup to Jnl. Lines" := GenJnlBatch."Copy VAT Setup to Jnl. Lines";
        "Posting No. Series" := GenJnlBatch."Posting No. Series";
        "Check Printed" := false;
        if "Source Code" = '' then
            "Source Code" := GenJnlTemplate."Source Code";

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");

        InitVATDateIfEmpty();

        if "Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"] then
            ShowSetDimFiltersNotification();
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        CheckJobQueueStatus(Rec);

        CheckOpenApprovalEntryExistForCurrentUser();

        SetLastModifiedDateTime();

        IsHandled := false;
        OnModifyOnBeforeTestCheckPrinted(Rec, xRec, IsHandled);
        if not IsHandled then
            TestField("Check Printed", false);

        if ("Applies-to ID" = '') then
            if ShouldClearCustVendApplnEntry() then
                ClearCustVendApplnEntry();
    end;

    trigger OnRename()
    begin
        CheckJobQueueStatus(Rec);
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);

        TestField("Check Printed", false);
    end;

    var
#pragma warning disable AA0074
        Text000: Label '%1 or %2 must be a G/L Account or Bank Account.', Comment = '%1=Account Type,%2=Balance Account Type';
#pragma warning disable AA0470
        Text001: Label 'You must not specify %1 when %2 is %3.';
        Text002: Label 'cannot be specified without %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ChangeCurrencyQst: Label 'The Currency Code in the Gen. Journal Line will be changed from %1 to %2.\\Do you want to continue?', Comment = '%1=FromCurrencyCode, %2=ToCurrencyCode';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'The %1 option can only be used internally in the system.';
#pragma warning restore AA0470
        Text007: Label '%1 or %2 must be a bank account.', Comment = '%1=Account Type,%2=Balance Account Type';
#pragma warning disable AA0470
        Text008: Label ' must be 0 when %1 is %2.';
#pragma warning restore AA0470
        Text009: Label 'LCY';
#pragma warning disable AA0470
        Text010: Label '%1 must be %2 or %3.';
        Text011: Label '%1 must be negative.';
        Text012: Label '%1 must be positive.';
        Text013: Label 'The %1 must not be more than %2.';
#pragma warning restore AA0470
        WrongJobQueueStatus: Label 'Journal line cannot be modified because it has been scheduled for posting.';
#pragma warning restore AA0074
        RenumberDocNoQst: Label 'If you have many documents it can take time to sort them, and %1 might perform slowly during the process. In those cases we suggest that you sort them during non-working hours. Do you want to continue?', Comment = '%1= Business Central';
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlTemplate: Record "Gen. Journal Template";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlBatch: Record "Gen. Journal Batch";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        GLSetup: Record "General Ledger Setup";
        Job: Record Job;
        SourceCodeSetup: Record "Source Code Setup";
        TempJobJnlLine: Record "Job Journal Line" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        EmplEntrySetApplID: Codeunit "Empl. Entry-SetAppl.ID";
        DimMgt: Codeunit DimensionManagement;
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        DeferralUtilities: Codeunit "Deferral Utilities";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Window: Dialog;
        DeferralDocType: Enum "Deferral Document Type";
        CurrencyCode: Code[10];
#pragma warning disable AA0074
        Text014: Label 'The %1 %2 has a %3 %4.\\Do you still want to use %1 %2 in this journal line?', Comment = '%1=Caption of Table Customer, %2=Customer No, %3=Caption of field Bill-to Customer No, %4=Value of Bill-to customer no.';
#pragma warning restore AA0074
        TemplateFound: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text015: Label 'You are not allowed to apply and post an entry to an entry with an earlier posting date.\\Instead, post %1 %2 and then apply it to %3 %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrencyDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text016: Label '%1 must be G/L Account or Bank Account.';
        Text018: Label '%1 can only be set when %2 is set.';
        Text019: Label '%1 cannot be changed when %2 is set.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLSetupRead: Boolean;
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export them again?';
        NothingToExportErr: Label 'There is nothing to export.';
        NotExistErr: Label 'Document number %1 does not exist or is already closed.', Comment = '%1=Document number';
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        DueDateMsg: Label 'This posting date will cause an overdue payment.';
#pragma warning disable AA0470
        CalcPostDateMsg: Label 'Processing payment journal lines #1##########';
#pragma warning restore AA0470
        NoEntriesToVoidErr: Label 'There are no entries to void.';
        SuppressCommit: Boolean;
        AccTypeNotSupportedErr: Label 'You cannot specify a deferral code for this type of account.';
        SalespersonPurchPrivacyBlockErr: Label 'Privacy Blocked must not be true for Salesperson / Purchaser %1.', Comment = '%1 = salesperson / purchaser code.';
        BlockedErr: Label 'The Blocked field must not be %1 for %2 %3.', Comment = '%1=Blocked field value,%2=Account Type,%3=Account No.';
        BlockedEmplErr: Label 'You cannot export file because employee %1 is blocked due to privacy.', Comment = '%1 = Employee no. ';
        InvoiceForGivenIDDoesNotExistErr: Label 'Invoice for given Applies-to Invoice Id does not exist.';
        RecurringMethodsDimFilterErr: Label 'Recurring method %1 cannot be used for the line with dimension filter setup.', Comment = '%1 - Recurring Method value';
        RecurringMethodsLineDimdErr: Label 'Recurring method %1 cannot be used for the line with dimension setup.', Comment = '%1 - Recurring Method value';
        DontShowAgainActionTxt: Label 'Don''t show again.';
        SetDimFiltersActionTxt: Label 'Set dimension filters.';
        SetDimFiltersMessageTxt: Label 'Dimension filters are not set for one or more lines that use the BD Balance by Dimension or RBD Reversing Balance by Dimension options. Do you want to set the filters?';
        SpecialSymbolsTok: Label '=|&@()<>', Locked = true;
        MustUseAllGLAccountsAsDestinationAccountsAllocAccErr: Label 'To use Allocation Accounts in combination with deferrals, the selected Allocation Account must have only G/L Accounts as destination types, no other types are allowed.';
        CannotChangePostingGroupForAccountTypeErr: Label 'Posting group cannot be changed for Account Type %1.', Comment = '%1 - account type';
        RestrictLineUsageDetailsTxt: Label 'The restriction was imposed because the line requires approval.';
        RestrictBatchUsageDetailsTxt: Label 'The restriction was imposed because the journal batch requires approval.';

    protected var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;
        HideValidationDialog: Boolean;
        SkipTaxCalculation: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    /// <summary>
    /// Determines if the general journal line is empty. It is considered empty if
    /// account number, amount, and balance account number (if not system created entry) are blank.
    /// </summary>
    /// <returns>True if empty, otherwise false.</returns>
    procedure EmptyLine() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeEmptyLine(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(
          ("Account No." = '') and (Amount = 0) and
          (("Bal. Account No." = '') or not "System-Created Entry"));
    end;

    local procedure InitVATDateIfEmpty()
    begin
        if "VAT Reporting Date" = 0D then
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
    end;

    local procedure BlankJobNo(CurrentFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlankJobNo(Rec, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Job No.", '');
    end;

    /// <summary>
    /// Returns the value of the global flag SkipTaxCalculation.
    /// </summary>
    /// <remarks>
    /// Currently SkipTaxCalculation in general journal line is used only in variable set and get procedures.
    /// </remarks>
    /// <returns>The value of the global flag SkipTaxCalculation.</returns>
    procedure GetSkipTaxCalculation(): Boolean
    begin
        exit(SkipTaxCalculation);
    end;

    /// <summary>
    /// Sets the value of the global variable SkipTaxCalculation.
    /// </summary>
    /// <remarks>
    /// Currently SkipTaxCalculation in general journal line is used only in variable set and get procedures.
    /// </remarks>
    /// <param name="Skip">The new value to set.</param>
    procedure SetSkipTaxCalulation(Skip: Boolean)
    begin
        SkipTaxCalculation := Skip;
    end;

    /// <summary>
    /// Updates the debit amout, credit amount, balnce and amount fields of a general journal line.
    /// </summary>
    /// <remarks>
    /// Also, updates the allocations for the line and validates the deferral code field if necessary.
    /// </remarks>
    procedure UpdateLineBalance()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnUpdateLineBalanceOnBeforeUpdateAmounts(Rec, IsHandled);
        if not IsHandled then
            UpdateAmounts();

        case true of
            ("Account No." <> '') and ("Bal. Account No." <> ''):
                "Balance (LCY)" := 0;
            "Bal. Account No." <> '':
                "Balance (LCY)" := -"Amount (LCY)";
            else
                "Balance (LCY)" := "Amount (LCY)";
        end;

        OnUpdateLineBalanceOnAfterAssignBalanceLCY("Balance (LCY)", Rec);

        Clear(GenJnlAlloc);
        GenJnlAlloc.UpdateAllocations(Rec);
        OnUpdateLineBalanceOnAfterUpdateAllocations(Rec);

        UpdateSalesPurchLCY();

        if ("Deferral Code" <> '') and (Amount <> xRec.Amount) and ((Amount <> 0) and (xRec.Amount <> 0)) then
            Validate("Deferral Code");
    end;

    /// <summary>
    /// Updates the debit and credit amounts based on the current line's amount and correction status.
    /// </summary>
    procedure UpdateAmounts()
    begin
        "Debit Amount" := 0;
        "Credit Amount" := 0;

        if ((Amount > 0) and (not Correction)) or
           ((Amount < 0) and Correction)
        then
            "Debit Amount" := Amount
        else
            if Amount <> 0 then
                "Credit Amount" := -Amount;

        if "Currency Code" = '' then
            "Amount (LCY)" := Amount;
    end;

    /// <summary>
    /// Initializes a new general journal line with values from the previous general journal line.
    /// </summary>
    /// <param name="LastGenJnlLine">Previous general journal line.</param>
    /// <param name="Balance">Genaral journal line balance.</param>
    /// <param name="BottomLine">Indicates whether the current line is the last line in a batch of general journal lines.</param>
    procedure SetUpNewLine(LastGenJnlLine: Record "Gen. Journal Line"; Balance: Decimal; BottomLine: Boolean)
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUpNewLine(GenJnlTemplate, GenJnlBatch, GenJnlLine, LastGenJnlLine, GLSetupRead, Balance, BottomLine, IsHandled, Rec);
        if IsHandled then
            exit;

        GenJnlTemplate.Get("Journal Template Name");
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJnlLine.FindFirst() then begin
            "Posting Date" := LastGenJnlLine."Posting Date";
            "Document Date" := LastGenJnlLine."Posting Date";
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
            "Document No." := LastGenJnlLine."Document No.";
            IsHandled := false;
            OnSetUpNewLineOnBeforeIncrDocNo(GenJnlLine, LastGenJnlLine, Balance, BottomLine, IsHandled, Rec, GenJnlBatch);
            if BottomLine and not IsHandled and (Balance - LastGenJnlLine."Balance (LCY)" = 0) and not LastGenJnlLine.EmptyLine() then
                "Document No." := NoSeriesBatch.SimulateGetNextNo(GenJnlBatch."No. Series", Rec."Posting Date", "Document No.");
        end else begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
            IsHandled := false;
            OnSetUpNewLineOnBeforeSetDocumentNo(GenJnlLine, LastGenJnlLine, Balance, BottomLine, IsHandled, Rec);
            if not IsHandled then
                if GenJnlBatch."No. Series" <> '' then
                    "Document No." := NoSeries.PeekNextNo(GenJnlBatch."No. Series", "Posting Date");
        end;
        if GenJnlTemplate.Recurring then
            "Recurring Method" := LastGenJnlLine."Recurring Method";
        case GenJnlTemplate.Type of
            GenJnlTemplate.Type::Payments:
                begin
                    "Account Type" := "Account Type"::Vendor;
                    "Document Type" := "Document Type"::Payment;
                end;
            else begin
                "Account Type" := LastGenJnlLine."Account Type";
                "Document Type" := LastGenJnlLine."Document Type";
            end;
        end;
        "Source Code" := GenJnlTemplate."Source Code";
        "Reason Code" := GenJnlBatch."Reason Code";
        "Posting No. Series" := GenJnlBatch."Posting No. Series";

        IsHandled := false;
        OnSetUpNewLineOnBeforeSetBalAccount(GenJnlLine, LastGenJnlLine, Balance, IsHandled, GenJnlTemplate, GenJnlBatch, BottomLine, Rec, CurrFieldNo);
        if not IsHandled then begin
            "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
               ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
            then
                "Account Type" := "Account Type"::"G/L Account";
            Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
            Description := '';
            OnSetupNewLineOnBeforeSuggestBalancingAmount(Rec, GenJnlBatch, CurrFieldNo);
            if GenJnlBatch."Suggest Balancing Amount" then
                SuggestBalancingAmount(LastGenJnlLine, BottomLine);
        end;

        UpdateJournalBatchID();

        OnAfterSetupNewLine(Rec, GenJnlTemplate, GenJnlBatch, LastGenJnlLine, Balance, BottomLine);
    end;

    /// <summary>
    /// Initializes a new general journal line.
    /// </summary>
    /// <param name="PostingDate">Posting date to set.</param>
    /// <param name="DocumentDate">Document date to set.</param>
    /// <param name="VATDate">VAT date to set.</param>
    /// <param name="PostingDescription">Posting description to set.</param>
    /// <param name="ShortcutDim1Code">Shortcut dimension 1 code to set.</param>
    /// <param name="ShortcutDim2Code">Shortcut dimension 2 code to set.</param>
    /// <param name="DimSetID">Dimension set ID to set.</param>
    /// <param name="ReasonCode">Reason code to set.</param>
    procedure InitNewLine(PostingDate: Date; DocumentDate: Date; VATDate: Date; PostingDescription: Text[100]; ShortcutDim1Code: Code[20]; ShortcutDim2Code: Code[20]; DimSetID: Integer; ReasonCode: Code[10])
    begin
        Init();
        "Posting Date" := PostingDate;
        "Document Date" := DocumentDate;
        if VATDate = 0D then
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date")
        else
            "VAT Reporting Date" := VATDate;
        Description := PostingDescription;
        "Shortcut Dimension 1 Code" := ShortcutDim1Code;
        "Shortcut Dimension 2 Code" := ShortcutDim2Code;
        "Dimension Set ID" := DimSetID;
        "Reason Code" := ReasonCode;
        OnAfterInitNewLine(Rec);
    end;

    local procedure CheckAccountTypeOnJobValidation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountTypeOnJobValidation(IsHandled, Rec);
        if IsHandled then
            exit;

        TestField("Account Type", "Account Type"::"G/L Account");
    end;

    /// <summary>
    /// Checks the document numbers on general journal lines to ensure correct sequence
    /// by the number series in the general journal batch.
    /// </summary>
    procedure CheckDocNoOnLines()
    var
        GenJnlBatchLocal: Record "Gen. Journal Batch";
        GenJnlLineLocal: Record "Gen. Journal Line";
        NoSeriesBatchSim: Codeunit "No. Series - Batch";
        PrevDocNo: Code[20];
        IsHandled: Boolean;
    begin
        NoSeriesBatchSim.SetSimulationMode();

        IsHandled := false;
        OnBeforeCheckDocNoOnLines(Rec, IsHandled);
        if IsHandled then
            exit;

        GenJnlLineLocal.CopyFilters(Rec);

        if not GenJnlLineLocal.FindSet() then
            exit;
        GenJnlBatchLocal.Get(GenJnlLineLocal."Journal Template Name", GenJnlLineLocal."Journal Batch Name");
        if GenJnlBatchLocal."No. Series" = '' then
            exit;

        PrevDocNo := '';
        repeat
            if PrevDocNo <> GenJnlLineLocal."Document No." then
                if GenJnlLineLocal."Document No." <> NoSeriesBatchSim.GetNextNo(GenJnlBatchLocal."No. Series", "Posting Date") then // do not save state
                    NoSeriesBatchSim.TestManual(GenJnlBatchLocal."No. Series", GenJnlLineLocal."Document No.");
            PrevDocNo := GenJnlLineLocal."Document No.";
        until GenJnlLineLocal.Next() = 0;
    end;


    /// <summary>
    /// Updates the document numbers on general journal lines to ensure correct sequence
    /// by the number series in the general journal batch.
    /// </summary>
    procedure RenumberDocumentNo()
    var
        GenJnlLine2: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        FirstDocNo: Code[20];
        FirstTempDocNo: Code[20];
        LastTempDocNo: Code[20];
    begin
        if SkipRenumberDocumentNo() then
            exit;
        TestField("Check Printed", false);

        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        GenJnlBatch.TestField("No. Series");

        if GetFilter("Document No.") <> '' then
            Error(DocNoFilterErr);
        FirstDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", "Posting Date");
        FirstTempDocNo := GetTempRenumberDocumentNo();
        // step1 - renumber to non-existing document number
        DocNo := FirstTempDocNo;
        GenJnlLine2 := Rec;
        GenJnlLine2.Reset();
        RenumberDocNoOnLines(DocNo, GenJnlLine2);
        LastTempDocNo := DocNo;

        // step2 - renumber to real document number (within Filter)
        DocNo := FirstDocNo;
        GenJnlLine2.CopyFilters(Rec);
        GenJnlLine2 := Rec;
        RenumberDocNoOnLines(DocNo, GenJnlLine2);

        // step3 - renumber to real document number (outside filter)
        DocNo := IncStr(DocNo);
        GenJnlLine2.Reset();
        GenJnlLine2.SetRange("Document No.", FirstTempDocNo, LastTempDocNo);
        RenumberDocNoOnLines(DocNo, GenJnlLine2);

        if Get("Journal Template Name", "Journal Batch Name", "Line No.") then;
    end;

    local procedure SkipRenumberDocumentNo() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRenumberDocumentNo(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(GuiAllowed() and not DIALOG.Confirm(StrSubstNo(RenumberDocNoQst, ProductName.Short()), true));
    end;

    local procedure RenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line")
    var
        LastGenJnlLine: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        PrevDocNo: Code[20];
        FirstDocNo: Code[20];
        TempFirstDocNo: Code[20];
        PrevCustVendNo: Code[20];
        CurrCustVendNo: Code[20];
        First: Boolean;
        IsHandled: Boolean;
        PrevPostingDate: Date;
    begin
        IsHandled := false;
        OnBeforeRenumberDocNoOnLines(DocNo, GenJnlLine2, IsHandled);
        if IsHandled then
            exit;

        FirstDocNo := DocNo;
        GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.", "Bal. Account No.");
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlLine2.SetRange("Check Printed", false);
        LastGenJnlLine.Init();
        First := true;
        if GenJnlLine2.FindSet() then
            repeat
                if ((FirstDocNo <> GetTempRenumberDocumentNo()) and (GenJnlLine2.GetFilter("Document No.") = '')) then begin
                    Commit();
                    TempFirstDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", GenJnlLine2."Posting Date");
                    if (FirstDocNo <> TempFirstDocNo) and (FirstDocNo <> IncStr(TempFirstDocNo)) then begin
                        DocNo := TempFirstDocNo;
                        FirstDocNo := DocNo;
                        First := true;
                    end;
                end;
                if GenJnlLine2."Document No." = FirstDocNo then
                    exit;
                GetCustVendNo(CurrCustVendNo, GenJnlLine2);
#pragma warning disable AA0205
                if ShouldChangeDocNo(GenJnlLine2, LastGenJnlLine, First, PrevDocNo, PrevPostingDate, PrevCustVendNo, CurrCustVendNo) then begin
#pragma warning restore AA0205
                    DocNo := IncStr(DocNo);
                    PrevCustVendNo := '';
                end;
                PrevDocNo := GenJnlLine2."Document No.";
                PrevPostingDate := GenJnlLine2."Posting Date";
                GetCustVendNo(PrevCustVendNo, GenJnlLine2);
                if GenJnlLine2."Document No." <> '' then begin
                    if GenJnlLine2."Applies-to ID" = GenJnlLine2."Document No." then
                        GenJnlLine2.RenumberAppliesToID(GenJnlLine2, GenJnlLine2."Document No.", DocNo);
                    GenJnlLine2.RenumberAppliesToDocNo(GenJnlLine2, GenJnlLine2."Document No.", DocNo);
                end;
                GenJnlLine3.Get(GenJnlLine2."Journal Template Name", GenJnlLine2."Journal Batch Name", GenJnlLine2."Line No.");
                CheckJobQueueStatus(GenJnlLine3);
                if GenJnlLine3."Document No." <> DocNo then begin
                    GenJnlLine3."Document No." := DocNo;
                    GenJnlLine3.Modify();
                    RestrictGenJournalLine(GenJnlLine3);
                    OnRenumberDocNoOnLinesOnAfterModifyGenJnlLine3(DocNo, GenJnlLine3);
                end;

                First := false;
                LastGenJnlLine := GenJnlLine2;
            until GenJnlLine2.Next() = 0;

        OnAfterRenumberDocNoOnLines(DocNo, GenJnlLine2);
    end;

    local procedure ShouldChangeDocNo(GenJnlLineForChange: Record "Gen. Journal Line"; LastGenJnlLine: Record "Gen. Journal Line"; First: Boolean; PrevDocNo: Code[20]; PrevPostingDate: Date; PrevCustVendNo: Code[20]; CurrCustVendNo: Code[20]): Boolean
    begin
        if First or LastGenJnlLine.EmptyLine() then
            exit(false);
        if (GenJnlLineForChange."Bal. Account No." <> '') and (GenJnlLineForChange."Document No." = '') then
            exit(true);
        if (GenJnlLineForChange."Document No." <> PrevDocNo) or (GenJnlLineForChange."Posting Date" <> PrevPostingDate) then
            exit(true);
        if GenJnlLineForChange."Document Type" in [GenJnlLineForChange."Document Type"::" ", GenJnlLineForChange."Document Type"::Payment, GenJnlLineForChange."Document Type"::Refund] then
            exit(false);
        exit((PrevCustVendNo <> '') and (CurrCustVendNo <> '') and (CurrCustVendNo <> PrevCustVendNo));
    end;

    local procedure GetTempRenumberDocumentNo(): Code[20]
    begin
        exit('RENUMBERED-000000001');
    end;

    /// <summary>
    /// Updates the applies to ID in general journal line and related ledger entries.
    /// </summary>
    /// <param name="GenJnlLine2">General journal line where applies to ID has to be replaced.</param>
    /// <param name="OriginalAppliesToID">Applies to ID which needs to be replaced.</param>
    /// <param name="NewAppliesToID">New applies to ID.</param>
    procedure RenumberAppliesToID(GenJnlLine2: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        OnBeforeRenumberAppliesToID(GenJnlLine2, OriginalAppliesToID, NewAppliesToID, AccType, AccNo);
        GetAccTypeAndNo(GenJnlLine2, AccType, AccNo);
        case AccType of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetRange("Customer No.", AccNo);
                    CustLedgEntry.SetRange("Applies-to ID", OriginalAppliesToID);
                    OnRenumberAppliesToIDOnAfterCustLedgEntrySetFilters(GenJnlLine2, AccNo, CustLedgEntry);
                    if CustLedgEntry.FindSet() then
                        repeat
                            CustLedgEntry2.Get(CustLedgEntry."Entry No.");
                            CustLedgEntry2."Applies-to ID" := NewAppliesToID;
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry2);
                        until CustLedgEntry.Next() = 0;
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetRange("Vendor No.", AccNo);
                    VendLedgEntry.SetRange("Applies-to ID", OriginalAppliesToID);
                    OnRenumberAppliesToIDOnAfterVendLedgEntrySetFilters(GenJnlLine2, AccNo, VendLedgEntry);
                    if VendLedgEntry.FindSet() then
                        repeat
                            VendLedgEntry2.Get(VendLedgEntry."Entry No.");
                            VendLedgEntry2."Applies-to ID" := NewAppliesToID;
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry2);
                        until VendLedgEntry.Next() = 0;
                end;
            else
                exit
        end;
        GenJnlLine2."Applies-to ID" := NewAppliesToID;
        GenJnlLine2.Modify();

        OnAfterRenumberAppliesToID(GenJnlLine2, OriginalAppliesToID, NewAppliesToID, AccType, AccNo);
    end;

    /// <summary>
    /// Updates the applies to document number in general journal lines.
    /// </summary>
    /// <param name="GenJnlLine2">
    /// General journal line is used to find lines that need to be modified.
    /// </param>
    /// <param name="OriginalAppliesToID">Applies to document number which needs to be replaced.</param>
    /// <param name="NewAppliesToID">New applies-to document number.</param>
    procedure RenumberAppliesToDocNo(GenJnlLine2: Record "Gen. Journal Line"; OriginalAppliesToDocNo: Code[20]; NewAppliesToDocNo: Code[20])
    begin
        GenJnlLine2.Reset();
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlLine2.SetRange("Applies-to Doc. Type", GenJnlLine2."Document Type");
        GenJnlLine2.SetRange("Applies-to Doc. No.", OriginalAppliesToDocNo);
        GenJnlLine2.ModifyAll("Applies-to Doc. No.", NewAppliesToDocNo);
    end;

    local procedure CheckEmptyVATProdPostingGroup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmptyVATProdPostingGroup(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
            TestField("VAT Prod. Posting Group", '');
    end;

    local procedure CheckVATInAlloc()
    begin
        if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
            if GenJnlAlloc.FindSet() then
                repeat
                    GenJnlAlloc.CheckVAT(Rec);
                until GenJnlAlloc.Next() = 0;
        end;
    end;

    /// <summary>
    /// Sets the currency code from related bank account.
    /// </summary>
    /// <param name="AccType2">
    /// Current general journal account type.
    /// This parameter is used to determine if the account type is bank account.
    /// If it is not bank account the currency code will not be updated.
    /// </param>
    /// <param name="AccNo2">Current general journal account number. Used to retrieve bank account.</param>
    /// <returns>True if the currency code is set, otherwise false.</returns>
    protected procedure SetCurrencyCode(AccType2: Enum "Gen. Journal Account Type"; AccNo2: Code[20]) Result: Boolean
    var
        BankAcc: Record "Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCurrencyCode(Rec, AccType2, AccNo2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        "Currency Code" := '';
        if AccNo2 <> '' then
            if AccType2 = AccType2::"Bank Account" then
                if BankAcc.Get(AccNo2) then
                    "Currency Code" := BankAcc."Currency Code";
        exit("Currency Code" <> '');
    end;

    /// <summary>
    /// Sets the currency code and currency factor.
    /// </summary>
    /// <remarks>
    /// If provided currency code is blank then the currency factor is set to 1.
    /// </remarks>
    /// <param name="CurrencyCode">Currency code to set.</param>
    /// <param name="CurrencyFactor">Currency factor to set.</param>
    procedure SetCurrencyFactor(CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    begin
        "Currency Code" := CurrencyCode;
        if "Currency Code" = '' then
            "Currency Factor" := 1
        else
            "Currency Factor" := CurrencyFactor;
    end;

    /// <summary>
    /// Sets the global Currency and CurrencyCode variables based on currency information in general journal line.
    /// </summary>
    /// <remarks>
    /// If additional currency posting is set to 'additional-currency amount only' the CurrencyCode is set from general ledger setup.
    /// An error will be raised if retrieved currency does not have amount rounding precision set.
    /// </remarks>
    protected procedure GetCurrency()
    begin
        if "Additional-Currency Posting" =
           "Additional-Currency Posting"::"Additional-Currency Amount Only"
        then begin
            if GLSetup."Additional Reporting Currency" = '' then
                ReadGLSetup();
            CurrencyCode := GLSetup."Additional Reporting Currency";
        end else
            CurrencyCode := "Currency Code";

        if CurrencyCode = '' then begin
            Clear(Currency);
            OnGetCurrencyOnBeforeInitRoundingPrecision(Rec, Currency);
            Currency.InitRoundingPrecision()
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    /// <summary>
    /// Updates general journal line source type and source number from account
    /// or balancing account.
    /// </summary>
    procedure UpdateSource()
    var
        SourceExists1: Boolean;
        SourceExists2: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSource(Rec, IsHandled);
        if IsHandled then
            exit;

        SourceExists1 := ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '');
        SourceExists2 := ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '');
        case true of
            SourceExists1 and not SourceExists2:
                begin
                    "Source Type" := "Account Type";
                    "Source No." := "Account No.";
                end;
            SourceExists2 and not SourceExists1:
                begin
                    "Source Type" := "Bal. Account Type";
                    "Source No." := "Bal. Account No.";
                end;
            else begin
                "Source Type" := "Source Type"::" ";
                "Source No." := '';
            end;
        end;

        OnAfterUpdateSource(Rec, CurrFieldNo);
    end;

    protected procedure CheckGLAcc(GLAcc: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAcc(GLAcc, Rec, IsHandled);
        if IsHandled then
            exit;

        GLAcc.CheckGLAcc();
        if GLAcc."Direct Posting" or ("Journal Template Name" = '') or "System-Created Entry" then
            exit;
        if Rec."Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                exit;

        CheckDirectPosting(GLAcc);

        OnAfterCheckGLAcc(Rec, GLAcc);
    end;

    protected procedure CheckICPartner(ICPartnerCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        if ICPartnerCode <> '' then begin
            if GenJnlTemplate.Get("Journal Template Name") then;
            if (ICPartnerCode <> '') and ICPartner.Get(ICPartnerCode) then begin
                ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                "IC Partner Code" := ICPartnerCode;
            end;
        end;
    end;

    local procedure CheckDirectPosting(var GLAccount: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDirectPosting(GLAccount, IsHandled, Rec);
        if IsHandled then
            exit;

        GLAccount.TestField("Direct Posting", true);

        OnAfterCheckDirectPosting(GLAccount, Rec);
    end;

    procedure GetFAAddCurrExchRate()
    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FANo: Code[20];
        UseFAAddCurrExchRate: Boolean;
        IsHandled: Boolean;
    begin
        "FA Add.-Currency Factor" := 0;
        if ("FA Posting Type" <> "FA Posting Type"::" ") and
           ("Depreciation Book Code" <> '')
        then begin
            if "Account Type" = "Account Type"::"Fixed Asset" then
                FANo := "Account No.";
            if "Bal. Account Type" = "Bal. Account Type"::"Fixed Asset" then
                FANo := "Bal. Account No.";
            if FANo <> '' then begin
                DeprBook.Get("Depreciation Book Code");
                case "FA Posting Type" of
                    "FA Posting Type"::"Acquisition Cost":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr Exch Rate - Acq. Cost";
                    "FA Posting Type"::Depreciation:
                        UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Depr.";
                    "FA Posting Type"::"Write-Down":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr Exch Rate -Write-Down";
                    "FA Posting Type"::Appreciation:
                        UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch. Rate - Apprec.";
                    "FA Posting Type"::"Custom 1":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch Rate - Custom 1";
                    "FA Posting Type"::"Custom 2":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch Rate - Custom 2";
                    "FA Posting Type"::Disposal:
                        UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Disp.";
                    "FA Posting Type"::Maintenance:
                        UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Maint.";
                    else
                        OnGetFAAddCurrExchRateOnCaseElse(Rec, DeprBook, UseFAAddCurrExchRate);
                end;
                if UseFAAddCurrExchRate then begin
                    FADeprBook.Get(FANo, "Depreciation Book Code");

                    IsHandled := false;
                    OnGetFAAddCurrExchRateOnBeforeFADeprBookTestField(FADeprBook, IsHandled);
                    if IsHandled then
                        exit;

                    FADeprBook.TestField("FA Add.-Currency Factor");
                    "FA Add.-Currency Factor" := FADeprBook."FA Add.-Currency Factor";
                end;
            end;
        end;
    end;

    procedure GetShowCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        exit(Text009);
    end;

    local procedure GetVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            VATPostingSetup.Init();
        OnAfterGetVATPostingSetup(VATPostingSetup);
    end;

    local procedure ClearJobRelatedAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearJobRelatedAmounts(Rec, IsHandled);
        if IsHandled then
            exit;

        "Job Quantity" := 0;
        "Job Currency Factor" := 0;
        "Job Currency Code" := '';
        "Job Unit Price" := 0;
        "Job Total Price" := 0;
        "Job Line Amount" := 0;
        "Job Line Discount Amount" := 0;
        "Job Unit Cost" := 0;
        "Job Total Cost" := 0;
        "Job Line Discount %" := 0;

        "Job Unit Price (LCY)" := 0;
        "Job Total Price (LCY)" := 0;
        "Job Line Amount (LCY)" := 0;
        "Job Line Disc. Amount (LCY)" := 0;
        "Job Unit Cost (LCY)" := 0;
        "Job Total Cost (LCY)" := 0;
    end;

    procedure ClearCustVendApplnEntry()
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        TempEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        OnBeforeClearCustVendApplnEntry(Rec, xRec, AccType, AccNo);
        if (xRec."Account No." <> "Account No.") or (xRec."Bal. Account No." <> "Bal. Account No.") then
            GetAccTypeAndNo(xRec, AccType, AccNo)
        else
            GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstCustLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearCustApplnEntryFields();
                        TempCustLedgEntry.DeleteAll();
                        OnClearCustVendApplnEntryOnBeforeCustEntrySetApplIDSetApplId(Rec, CustLedgEntry);
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstCustLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearCustApplnEntryFields();
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                        end;
            AccType::Vendor:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearVendApplnEntryFields();
                        TempVendLedgEntry.DeleteAll();
                        VendEntrySetApplID.SetApplId(VendLedgEntry, TempVendLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearVendApplnEntryFields();
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                        end;
            AccType::Employee:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstEmplLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearEmplApplnEntryFields();
                        TempEmplLedgEntry.DeleteAll();
                        EmplEntrySetApplID.SetApplId(EmplLedgEntry, TempEmplLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstEmplLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearEmplApplnEntryFields();
                            CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmplLedgEntry);
                        end;
        end;

        OnAfterClearCustVendApplnEntry(Rec, xRec, AccType, AccNo);
    end;

    local procedure ClearCustApplnEntryFields()
    begin
        CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        CustLedgEntry."Accepted Payment Tolerance" := 0;
        CustLedgEntry."Amount to Apply" := 0;
        if Rec."On Hold" = CustLedgEntry."On Hold" then begin
            CustLedgEntry."On Hold" := '';
            Rec."On Hold" := '';
        end;
        OnAfterClearCustApplnEntryFields(CustLedgEntry);
    end;

    local procedure ClearVendApplnEntryFields()
    begin
        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        VendLedgEntry."Accepted Payment Tolerance" := 0;
        VendLedgEntry."Amount to Apply" := 0;
        if Rec."On Hold" = VendLedgEntry."On Hold" then begin
            VendLedgEntry."On Hold" := '';
            Rec."On Hold" := '';
        end;
        OnAfterClearVendApplnEntryFields(VendLedgEntry);
    end;

    local procedure ClearEmplApplnEntryFields()
    begin
        EmplLedgEntry."Amount to Apply" := 0;

        OnAfterClearEmplApplnEntryFields(EmplLedgEntry);
    end;

    procedure CheckFixedCurrency(): Boolean
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", "Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "Posting Date");

        if not CurrExchRate.FindLast() then
            exit(false);

        if CurrExchRate."Relational Currency Code" = '' then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        if CurrExchRate."Fix Exchange Rate Amount" <>
           CurrExchRate."Fix Exchange Rate Amount"::Both
        then
            exit(false);

        CurrExchRate.SetRange("Currency Code", CurrExchRate."Relational Currency Code");
        if CurrExchRate.FindLast() then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        exit(false);
    end;

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
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, OldDimSetID, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Check Printed", false);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, CurrFieldNo);
    end;

    local procedure ValidateAmount()
    var
        IsHandled: Boolean;
    begin
        GetCurrency();
        if "Currency Code" = '' then
            "Amount (LCY)" := Amount
        else
            "Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor"));
        OnValidateAmountOnAfterAssignAmountLCY("Amount (LCY)");

        Amount := Round(Amount, Currency."Amount Rounding Precision");

        IsHandled := false;
        OnValidateAmountOnBeforeCheckCreditLimit(Rec, CurrFieldNo, CustCheckCreditLimit, IsHandled);
        if not IsHandled then
            if (CurrFieldNo <> 0) and
            (CurrFieldNo <> FieldNo("Applies-to Doc. No.")) and
            ((("Account Type" = "Account Type"::Customer) and
                ("Account No." <> '') and (Amount > 0) and
                (CurrFieldNo <> FieldNo("Bal. Account No."))) or
                (("Bal. Account Type" = "Bal. Account Type"::Customer) and
                ("Bal. Account No." <> '') and (Amount < 0) and
                (CurrFieldNo <> FieldNo("Account No."))))
            then
                CustCheckCreditLimit.GenJnlLineCheck(Rec);

        Validate("VAT %");
        Validate("Bal. VAT %");
        UpdateLineBalance();
        if "Deferral Code" <> '' then
            Validate("Deferral Code");

        UpdateApplyToAmount();

        if JobTaskIsSet() then begin
            CreateTempJobJnlLine();
            UpdatePricesFromJobJnlLine();
        end;

        OnAfterValidateAmount(Rec);
    end;

    local procedure UpdateApplyToAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateApplyToAmount(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Amount <> xRec.Amount then begin
            if ("Applies-to Doc. No." <> '') or ("Applies-to ID" <> '') then
                SetApplyToAmount();
            if (xRec.Amount <> 0) or (xRec."Applies-to Doc. No." <> '') or (xRec."Applies-to ID" <> '') then
                PaymentToleranceMgt.PmtTolGenJnl(Rec);
        end;
        if ((CurrFieldNo = fieldno(Amount)) or (CurrFieldNo = FieldNo("Amount (LCY)"))) and (Amount = 0) and (("Applies-to ID" <> '') or ("Applies-to Doc. No." <> '')) then begin
            if ("Applies-to ID" <> '') then
                Validate("Applies-to ID", '');
            if ("Applies-to Doc. No." <> '') then
                validate("Applies-to Doc. No.", '');
        end;
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Check Printed", false);
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnShowDimensionsOnAfterEditDimensionSet(Rec, OldDimSetID);

        IsChanged := OldDimSetID <> "Dimension Set ID";

        OnAfterShowDimensions(Rec, xRec, OldDimSetID, IsChanged);
    end;

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            JournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    procedure GetFAVATSetup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FABalAcc: Boolean;
        IsHandled: Boolean;
    begin
        if CurrFieldNo = 0 then
            exit;
        if ("Account Type" <> "Account Type"::"Fixed Asset") and
           ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
        then
            exit;
        FABalAcc := ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset");
        if not FABalAcc then begin
            ClearPostingGroups();
            "Tax Group Code" := '';
            Validate("VAT Prod. Posting Group");
        end;
        if FABalAcc then begin
            ClearBalancePostingGroups();
            "Bal. Tax Group Code" := '';
            Validate("Bal. VAT Prod. Posting Group");
        end;

        IsHandled := false;
        OnGetFAVATSetupOnBeforeCopyVATSetupToJnlLines(Rec, LocalGLAcc, FAPostingGr, IsHandled);
        if IsHandled then
            exit;

        if CopyVATSetupToJnlLines() then
            if (("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") or
                ("FA Posting Type" = "FA Posting Type"::Disposal) or
                ("FA Posting Type" = "FA Posting Type"::Maintenance)) and
               ("Posting Group" <> '')
            then
                if FAPostingGr.GetPostingGroup("Posting Group", "Depreciation Book Code") then begin
                    case "FA Posting Type" of
                        "FA Posting Type"::"Acquisition Cost":
                            LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccount());
                        "FA Posting Type"::Disposal:
                            LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccountOnDisposal());
                        "FA Posting Type"::Maintenance:
                            LocalGLAcc.Get(FAPostingGr.GetMaintenanceExpenseAccount());
                    end;
                    OnGetFAVATSetupOnBeforeCheckGLAcc(Rec, LocalGLAcc);
                    LocalGLAcc.CheckGLAcc();
                    if not FABalAcc then begin
                        "Gen. Posting Type" := LocalGLAcc."Gen. Posting Type";
                        "Gen. Bus. Posting Group" := LocalGLAcc."Gen. Bus. Posting Group";
                        "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
                        "VAT Bus. Posting Group" := LocalGLAcc."VAT Bus. Posting Group";
                        "VAT Prod. Posting Group" := LocalGLAcc."VAT Prod. Posting Group";
                        "Tax Group Code" := LocalGLAcc."Tax Group Code";
                        Validate("VAT Prod. Posting Group");
                    end else begin
                        ;
                        "Bal. Gen. Posting Type" := LocalGLAcc."Gen. Posting Type";
                        "Bal. Gen. Bus. Posting Group" := LocalGLAcc."Gen. Bus. Posting Group";
                        "Bal. Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
                        "Bal. VAT Bus. Posting Group" := LocalGLAcc."VAT Bus. Posting Group";
                        "Bal. VAT Prod. Posting Group" := LocalGLAcc."VAT Prod. Posting Group";
                        "Bal. Tax Group Code" := LocalGLAcc."Tax Group Code";
                        Validate("Bal. VAT Prod. Posting Group");
                    end;
                end;
    end;

    local procedure GetFADeprBook(FANo: Code[20])
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        DefaultFADeprBook: Record "FA Depreciation Book";
        SetFADeprBook: Record "FA Depreciation Book";
    begin
        OnBeforeGetFADeprBook(Rec, FANo);
        if "Depreciation Book Code" = '' then begin
            FASetup.Get();

            DefaultFADeprBook.SetRange("FA No.", FANo);
            DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);

            SetFADeprBook.SetRange("FA No.", FANo);

            case true of
                DefaultFADeprBook.FindFirst():
                    "Depreciation Book Code" := DefaultFADeprBook."Depreciation Book Code";
                FADeprBook.Get(FANo, FASetup."Default Depr. Book"):
                    "Depreciation Book Code" := FASetup."Default Depr. Book";
                SetFADeprBook.Count = 1:
                    begin
                        SetFADeprBook.FindFirst();
                        "Depreciation Book Code" := SetFADeprBook."Depreciation Book Code";
                    end
                else
                    "Depreciation Book Code" := '';
            end;
        end;

        if "Depreciation Book Code" <> '' then begin
            FADeprBook.Get(FANo, "Depreciation Book Code");
            "Posting Group" := FADeprBook."FA Posting Group";
        end;

        OnAfterGetFADeprBook(Rec, FANo);
    end;

    procedure GetTemplate()
    begin
        if not TemplateFound then
            GenJnlTemplate.Get("Journal Template Name");
        TemplateFound := true;
    end;

    local procedure UpdateSalesPurchLCY()
    var
        VATAmount: Decimal;
        VATAmountLCY: Decimal;
    begin
        "Sales/Purch. (LCY)" := 0;
        if (not "System-Created Entry") and ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and (Amount <> 0) then begin
            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and
               (("Bal. Account No." <> '') or ("Recurring Method" <> "Recurring Method"::" "))
            then
                "Sales/Purch. (LCY)" := "Amount (LCY)" + "Bal. VAT Amount (LCY)";

            if ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]) and ("Account No." <> '') then
                "Sales/Purch. (LCY)" := -("Amount (LCY)" - "VAT Amount (LCY)");

            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and ("Bal. Account No." = '') then begin
                CalculateVATAmount(VATAmount, VATAmountLCY);
                if VATAmountLCY <> 0 then
                    "Sales/Purch. (LCY)" := ("Amount (LCY)" + VATAmountLCY);
                if ("Sales/Purch. (LCY)" * "Amount (LCY)") < 0 then
                    "Sales/Purch. (LCY)" := "Amount (LCY)";
            end;
        end;

        OnAfterUpdateSalesPurchLCY(Rec);
    end;

    procedure LookUpAppliesToDocCust(AccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpAppliesToDocCust(Rec, AccNo, IsHandled);
        if IsHandled then
            exit;

        Clear(CustLedgEntry);
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        if AccNo <> '' then
            CustLedgEntry.SetRange("Customer No.", AccNo);

        IsHandled := false;
        OnLookUpAppliesToDocCustOnBeforeCustLedgerEntrySetRangeOpen(Rec, IsHandled);
        if not IsHandled then
            CustLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if CustLedgEntry.IsEmpty() then begin
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if CustLedgEntry.IsEmpty() then
                CustLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if CustLedgEntry.IsEmpty() then
                CustLedgEntry.SetRange("Document Type");
        end;
        if Amount <> 0 then begin
            CustLedgEntry.SetRange(Positive, Amount < 0);
            if CustLedgEntry.IsEmpty() then
                CustLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocCustOnAfterSetFilters(CustLedgEntry, Rec, AccNo);

        if RunApplyCustEntriesPageLookupOk(AccNo) then begin
            OnLookUpAppliesToDocCustOnAfterApplyCustEntriesGetRecord(Rec, CustLedgEntry);
            if AccNo = '' then begin
                AccNo := CustLedgEntry."Customer No.";
                if "Bal. Account Type" = "Bal. Account Type"::Customer then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithCustLedgEntry();
            UpdateDocumentTypeAndAppliesTo(CustLedgEntry."Document Type", CustLedgEntry."Document No.");
            OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(Rec, CustLedgEntry);
        end;
    end;

    local procedure RunApplyCustEntriesPageLookupOk(AccNo: Code[20]) Result: Boolean
    var
        ApplyCustEntries: Page "Apply Customer Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunApplyCustEntriesPageLookupOk(Rec, CustLedgEntry, AccNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ApplyCustEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
            ApplyCustEntries.GetRecord(CustLedgEntry);
            exit(true);
        end;

        exit(false);
    end;

    procedure LookUpAppliesToDocVend(AccNo: Code[20])
    var
        ApplyVendEntries: Page "Apply Vendor Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpAppliesToDocVend(Rec, AccNo, IsHandled);
        if IsHandled then
            exit;

        Clear(VendLedgEntry);
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        if AccNo <> '' then
            VendLedgEntry.SetRange("Vendor No.", AccNo);
        IsHandled := false;
        OnLookUpAppliesToDocVendOnBeforeVendLedgerEntrySetRangeOpen(Rec, IsHandled);
        if not IsHandled then
            VendLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.IsEmpty() then begin
                VendLedgEntry.SetRange("Document Type");
                VendLedgEntry.SetRange("Document No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if VendLedgEntry.IsEmpty() then
                VendLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if VendLedgEntry.IsEmpty() then
                VendLedgEntry.SetRange("Document Type");
        end;
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.IsEmpty() then
                VendLedgEntry.SetRange("Document No.");
        end;
        if Amount <> 0 then begin
            VendLedgEntry.SetRange(Positive, Amount < 0);
            if VendLedgEntry.IsEmpty() then;
            VendLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocVendOnAfterSetFilters(VendLedgEntry, Rec, AccNo);

        if RunApplyVendEntriesPageLookupOk(ApplyVendEntries, AccNo) then begin
            IsHandled := false;
            OnLookUpAppliesToDocVendOnAfterApplyVendEntriesGetRecord(Rec, GenJnlLine, GenJnlApply, PaymentToleranceMgt, VendLedgEntry, IsHandled);
            if IsHandled then
                exit;

            if AccNo = '' then begin
                AccNo := VendLedgEntry."Vendor No.";
                if "Bal. Account Type" = "Bal. Account Type"::Vendor then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithVendLedgEntry();
            UpdateDocumentTypeAndAppliesTo(VendLedgEntry."Document Type", VendLedgEntry."Document No.");
            OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(Rec, VendLedgEntry);
        end;

        OnAfterLookUpAppliesToDocVend(Rec, VendLedgEntry, CustLedgEntry, ApplyVendEntries);
    end;

    local procedure RunApplyVendEntriesPageLookupOk(var ApplyVendEntries: Page "Apply Vendor Entries"; AccNo: Code[20]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunApplyVendEntriesPageLookupOk(Rec, VendLedgEntry, AccNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ApplyVendEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        if ApplyVendEntries.RunModal() = ACTION::LookupOK then begin
            ApplyVendEntries.GetRecord(VendLedgEntry);
            exit(true);
        end;

        exit(false);
    end;

    procedure LookUpAppliesToDocEmpl(AccNo: Code[20])
    var
        ApplyEmplEntries: Page "Apply Employee Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpAppliesToDocEmpl(Rec, AccNo, IsHandled);
        if IsHandled then
            exit;

        Clear(EmplLedgEntry);
        EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
        if AccNo <> '' then
            EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if EmplLedgEntry.IsEmpty() then begin
                EmplLedgEntry.SetRange("Document Type");
                EmplLedgEntry.SetRange("Document No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            EmplLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if EmplLedgEntry.IsEmpty() then
                EmplLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if EmplLedgEntry.IsEmpty() then
                EmplLedgEntry.SetRange("Document Type");
        end;
        if "Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if EmplLedgEntry.IsEmpty() then
                EmplLedgEntry.SetRange("Document No.");
        end;
        if Amount <> 0 then begin
            EmplLedgEntry.SetRange(Positive, Amount < 0);
            if EmplLedgEntry.IsEmpty() then;
            EmplLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocEmplOnAfterSetFilters(EmplLedgEntry, Rec);

        ApplyEmplEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyEmplEntries.SetTableView(EmplLedgEntry);
        ApplyEmplEntries.SetRecord(EmplLedgEntry);
        ApplyEmplEntries.LookupMode(true);
        if ApplyEmplEntries.RunModal() = ACTION::LookupOK then begin
            ApplyEmplEntries.GetRecord(EmplLedgEntry);
            if AccNo = '' then begin
                AccNo := EmplLedgEntry."Employee No.";
                if "Bal. Account Type" = "Bal. Account Type"::Employee then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithEmplLedgEntry();
            UpdateDocumentTypeAndAppliesTo(EmplLedgEntry."Document Type", EmplLedgEntry."Document No.");
            OnLookUpAppliesToDocEmplOnAfterUpdateDocumentTypeAndAppliesTo(Rec, EmplLedgEntry);
        end;
    end;

    procedure SetApplyToAmount()
    begin
        OnBeforeSetApplyToAmount(Rec);
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    CustLedgEntry.SetRange(Open, true);
                    OnSetApplyToAmountOnAfterCustLedgEntrySetFilters(Rec, CustLedgEntry);
                    if CustLedgEntry.FindFirst() then
                        if CustLedgEntry."Amount to Apply" = 0 then begin
                            CustLedgEntry.CalcFields("Remaining Amount");
                            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                            OnSetApplyToAmountOnBeforeCustEntryEdit(Rec, CustLedgEntry);
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                        end;
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Document No.");
                    VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    VendLedgEntry.SetRange(Open, true);
                    OnSetApplyToAmountOnAfterVendLedgEntrySetFilters(Rec, VendLedgEntry);
                    if VendLedgEntry.FindFirst() then
                        if VendLedgEntry."Amount to Apply" = 0 then begin
                            VendLedgEntry.CalcFields("Remaining Amount");
                            VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                            OnSetApplyToAmountOnBeforeVendEntryEdit(Rec, VendLedgEntry);
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                        end;
                end;
            "Account Type"::Employee:
                begin
                    EmplLedgEntry.SetCurrentKey("Document No.");
                    EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    EmplLedgEntry.SetRange("Employee No.", "Account No.");
                    EmplLedgEntry.SetRange(Open, true);
                    if EmplLedgEntry.FindFirst() then
                        if EmplLedgEntry."Amount to Apply" = 0 then begin
                            EmplLedgEntry.CalcFields("Remaining Amount");
                            EmplLedgEntry."Amount to Apply" := EmplLedgEntry."Remaining Amount";
                            OnSetApplyToAmountOnBeforeEmplEntryEdit(Rec, EmplLedgEntry);
                            CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmplLedgEntry);
                        end;
                end;
        end;
        OnAfterSetApplyToAmount(Rec);
    end;

    procedure ValidateApplyRequirements(TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        IsHandled: Boolean;
    begin
        if (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) or
           (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor)
        then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);

        OnBeforeValidateApplyRequirements(TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        case TempGenJnlLine."Account Type" of
            TempGenJnlLine."Account Type"::Customer:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open);
                    CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                    CustLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    CustLedgEntry.SetRange(Open, true);
                    OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithAppliesToID(TempGenJnlLine, CustLedgEntry);
                    if CustLedgEntry.FindSet() then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry."Document No.", CustLedgEntry);
                        until CustLedgEntry.Next() = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        CustLedgEntry.SetCurrentKey("Document No.");
                        CustLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " then
                            CustLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                        CustLedgEntry.SetRange(Open, true);
                        OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithoutAppliesToID(TempGenJnlLine, CustLedgEntry);
                        if CustLedgEntry.FindFirst() then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry."Document No.", CustLedgEntry);
                    end;
            TempGenJnlLine."Account Type"::Vendor:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
                    VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                    VendLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    VendLedgEntry.SetRange(Open, true);
                    OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithAppliesToID(TempGenJnlLine, VendLedgEntry);
                    if VendLedgEntry.FindSet() then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry."Document No.", VendLedgEntry);
                        until VendLedgEntry.Next() = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        VendLedgEntry.SetCurrentKey("Document No.");
                        VendLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " then
                            VendLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                        VendLedgEntry.SetRange(Open, true);
                        OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithoutAppliesToID(TempGenJnlLine, VendLedgEntry);
                        if VendLedgEntry.FindFirst() then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry."Document No.", VendLedgEntry);
                    end;
            TempGenJnlLine."Account Type"::Employee:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open);
                    EmplLedgEntry.SetRange("Employee No.", TempGenJnlLine."Account No.");
                    EmplLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    EmplLedgEntry.SetRange(Open, true);
                    if EmplLedgEntry.FindSet() then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, EmplLedgEntry."Posting Date", EmplLedgEntry."Document Type", EmplLedgEntry."Document No.", EmplLedgEntry);
                        until EmplLedgEntry.Next() = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        EmplLedgEntry.SetCurrentKey("Document No.");
                        EmplLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> EmplLedgEntry."Applies-to Doc. Type"::" " then
                            EmplLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        EmplLedgEntry.SetRange("Employee No.", TempGenJnlLine."Account No.");
                        EmplLedgEntry.SetRange(Open, true);
                        if EmplLedgEntry.FindFirst() then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, EmplLedgEntry."Posting Date", EmplLedgEntry."Document Type", EmplLedgEntry."Document No.", EmplLedgEntry);
                    end;
        end;

        OnAfterValidateApplyRequirements(TempGenJnlLine);
    end;

    local procedure UpdateCountryCodeAndVATRegNo(No: Code[20])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        OnBeforeUpdateCountryCodeAndVATRegNo(Rec, xRec, No);

        if No = '' then begin
            "Country/Region Code" := '';
            "VAT Registration No." := '';
            exit;
        end;

        ReadGLSetup();
        case true of
            ("Account Type" = "Account Type"::Customer) or ("Bal. Account Type" = "Bal. Account Type"::Customer):
                begin
                    Cust.Get(No);
                    "Country/Region Code" := Cust."Country/Region Code";
                    "VAT Registration No." := Cust."VAT Registration No.";
                end;
            ("Account Type" = "Account Type"::Vendor) or ("Bal. Account Type" = "Bal. Account Type"::Vendor):
                begin
                    Vend.Get(No);
                    "Country/Region Code" := Vend."Country/Region Code";
                    "VAT Registration No." := Vend."VAT Registration No.";
                end;
        end;

        OnAfterUpdateCountryCodeAndVATRegNo(Rec, xRec, No);
    end;

    procedure JobTaskIsSet() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobTaskIsSet(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(("Job No." <> '') and ("Job Task No." <> '') and ("Account Type" = "Account Type"::"G/L Account"));
    end;

    procedure CreateTempJobJnlLine()
    var
        TmpJobJnlOverallCurrencyFactor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TestField("Posting Date");

        Clear(TempJobJnlLine);
        TempJobJnlLine.DontCheckStdCost();
        OnCreateTempJobJnlLimeOnBeforeValidateFields(TempJobJnlLine, Rec, XRec, CurrFieldNo);

        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        if CurrFieldNo <> FieldNo("Posting Date") then
            TempJobJnlLine.Validate("Posting Date", "Posting Date")
        else
            TempJobJnlLine.Validate("Posting Date", xRec."Posting Date");
        TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::"G/L Account");

        "Job Currency Factor" := 0;
        if "Job Currency Code" <> '' then begin
            if "Posting Date" = 0D then
                CurrencyDate := WorkDate()
            else
                CurrencyDate := "Posting Date";

            OnCreateTempJobJnlLineOnBeforeFindJobCurrencyFactor(Rec, CurrExchRate);
            if "Currency Code" = "Job Currency Code" then
                "Job Currency Factor" := "Currency Factor"
            else
                "Job Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Job Currency Code");
            TempJobJnlLine.SetCurrencyFactor("Job Currency Factor");
        end;
        TempJobJnlLine.Validate("No.", "Account No.");
        TempJobJnlLine.Validate(Quantity, "Job Quantity");

        TmpJobJnlOverallCurrencyFactor := GetGenJnlLineToJobCurrencyFactor();

        UpdateAmountsOnTempJobJnlLine(TmpJobJnlOverallCurrencyFactor);

        OnAfterCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, CurrFieldNo);
    end;

    local procedure UpdateAmountsOnTempJobJnlLine(TmpJobJnlOverallCurrencyFactor: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmountsOnTempJobJnlLine(Rec, xRec, TempJobJnlLine, IsHandled);
        if IsHandled then
            exit;

        if "Job Quantity" <> 0 then
            TempJobJnlLine.Validate("Unit Cost", ((Amount - "VAT Amount") * TmpJobJnlOverallCurrencyFactor) / "Job Quantity");

        if (xRec."Account No." = "Account No.") and (xRec."Job Task No." = "Job Task No.") and ("Job Unit Price" <> 0) then begin
            if TempJobJnlLine."Cost Factor" = 0 then
                TempJobJnlLine."Unit Price" := xRec."Job Unit Price";
            TempJobJnlLine."Line Amount" := xRec."Job Line Amount";
            TempJobJnlLine."Line Discount %" := xRec."Job Line Discount %";
            TempJobJnlLine."Line Discount Amount" := xRec."Job Line Discount Amount";
            TempJobJnlLine.Validate("Unit Price");
        end;
    end;

    procedure UpdatePricesFromJobJnlLine()
    begin
        "Job Unit Price" := TempJobJnlLine."Unit Price";
        "Job Total Price" := TempJobJnlLine."Total Price";
        "Job Line Amount" := TempJobJnlLine."Line Amount";
        "Job Line Discount Amount" := TempJobJnlLine."Line Discount Amount";
        "Job Unit Cost" := TempJobJnlLine."Unit Cost";
        "Job Total Cost" := TempJobJnlLine."Total Cost";
        "Job Line Discount %" := TempJobJnlLine."Line Discount %";

        "Job Unit Price (LCY)" := TempJobJnlLine."Unit Price (LCY)";
        "Job Total Price (LCY)" := TempJobJnlLine."Total Price (LCY)";
        "Job Line Amount (LCY)" := TempJobJnlLine."Line Amount (LCY)";
        "Job Line Disc. Amount (LCY)" := TempJobJnlLine."Line Discount Amount (LCY)";
        "Job Unit Cost (LCY)" := TempJobJnlLine."Unit Cost (LCY)";
        "Job Total Cost (LCY)" := TempJobJnlLine."Total Cost (LCY)";

        OnAfterUpdatePricesFromJobJnlLine(Rec, TempJobJnlLine);
    end;

    procedure SetHideValidation(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
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

    local procedure GetDeferralPostDate() DeferralPostDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralPostDate(Rec, DeferralPostDate, IsHandled);
        if IsHandled then
            exit(DeferralPostDate);

        DeferralPostDate := "Posting Date";
    end;

    procedure IsApplied() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsApplied(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Applies-to Doc. No." <> '' then
            exit(true);
        if "Applies-to ID" <> '' then
            exit(true);
        exit(false);
    end;

    procedure DataCaption(): Text[250]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(GenJnlBatch.Name + '-' + GenJnlBatch.Description);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    procedure GetCustLedgerEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustLedgerEntry(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::Customer) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '')
        then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            CustLedgEntry.SetRange(Open, true);
            OnGetCustLedgerEntryOnAfterSetFilters(Rec, CustLedgEntry);
            if not CustLedgEntry.FindFirst() then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", CustLedgEntry."Customer No.");
            OnGetCustLedgerEntryOnAfterAssignCustomerNo(Rec, CustLedgEntry);

            if Amount = 0 then begin
                CustLedgEntry.CalcFields("Remaining Amount");
                OnGetCustLedgerEntryOnAfterCalcRemainingAmount(CustLedgEntry);

                if "Posting Date" <= CustLedgEntry."Pmt. Discount Date" then
                    Amount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible")
                else
                    Amount := -CustLedgEntry."Remaining Amount";

                if "Currency Code" <> CustLedgEntry."Currency Code" then
                    UpdateCurrencyCode(CustLedgEntry."Currency Code");

                SetAppliesToFields(
                  CustLedgEntry."Document Type", CustLedgEntry."Document No.", CustLedgEntry."External Document No.");

                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                if GenJnlBatch."Bal. Account No." <> '' then begin
                    "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
                    Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                end else
                    Validate(Amount);

                OnAfterGetCustLedgerEntry(Rec, CustLedgEntry);
            end;
        end;
    end;

    procedure GetVendLedgerEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendLedgerEntry(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::Vendor) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '')
        then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            VendLedgEntry.SetRange(Open, true);
            if not VendLedgEntry.FindFirst() then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", VendLedgEntry."Vendor No.");
            OnGetVendLedgerEntryOnAfterAssignVendorNo(Rec, VendLedgEntry);

            if Amount = 0 then begin
                VendLedgEntry.CalcFields("Remaining Amount");
                OnGetVendLedgerEntryOnAfterCalcRemainingAmount(VendLedgEntry);

                if "Posting Date" <= VendLedgEntry."Pmt. Discount Date" then
                    Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible")
                else
                    Amount := -VendLedgEntry."Remaining Amount";

                if "Currency Code" <> VendLedgEntry."Currency Code" then
                    UpdateCurrencyCode(VendLedgEntry."Currency Code");

                SetAppliesToFields(
                  VendLedgEntry."Document Type", VendLedgEntry."Document No.", VendLedgEntry."External Document No.");

                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                if GenJnlBatch."Bal. Account No." <> '' then begin
                    "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
                    Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                end else
                    Validate(Amount);

                OnAfterGetVendLedgerEntry(Rec, VendLedgEntry);
            end;
        end;
    end;

    procedure GetEmplLedgerEntry()
    begin
        if ("Account Type" = "Account Type"::Employee) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '')
        then begin
            EmplLedgEntry.Reset();
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            EmplLedgEntry.SetRange(Open, true);
            if not EmplLedgEntry.FindFirst() then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", EmplLedgEntry."Employee No.");
            if Amount = 0 then begin
                EmplLedgEntry.CalcFields("Remaining Amount");

                Amount := -EmplLedgEntry."Remaining Amount";

                SetAppliesToFields(EmplLedgEntry."Document Type", EmplLedgEntry."Document No.", '');

                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                if GenJnlBatch."Bal. Account No." <> '' then begin
                    "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
                    Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                end else
                    Validate(Amount);
                OnAfterGetEmplLedgerEntry(Rec, EmplLedgEntry);
            end;
        end;
    end;

    protected procedure UpdateCurrencyCode(NewCurrencyCode: Code[10])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        FromCurrencyCode: Code[10];
        ToCurrencyCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCurrencyCode(Rec, NewCurrencyCode, IsHandled);
        if IsHandled then
            exit;

        FromCurrencyCode := GetShowCurrencyCode("Currency Code");
        ToCurrencyCode := GetShowCurrencyCode(NewCurrencyCode);
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(ChangeCurrencyQst, FromCurrencyCode, ToCurrencyCode), true)
        then
            Error(UpdateInterruptedErr);
        Validate("Currency Code", NewCurrencyCode);
    end;

    local procedure ValidateCurrencyCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCurrencyCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate("Currency Code");
    end;

    local procedure ValidateDocumentDateFromPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateDocumentDateFromPostingDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Validate("Document Date", "Posting Date");
    end;

    local procedure SetAppliesToFields(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Code[35])
    begin
        UpdateDocumentTypeAndAppliesTo(DocType, DocNo);

        if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice) and ("Document Type" = "Document Type"::Payment) then
            "Applies-to Ext. Doc. No." := ExtDocNo;
    end;

    local procedure CustVendAccountNosModified(): Boolean
    begin
        exit(
          (("Bal. Account No." <> xRec."Bal. Account No.") and
           ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])) or
          (("Account No." <> xRec."Account No.") and
           ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor])))
    end;

    protected procedure CheckPaymentTolerance()
    begin
        if Amount <> 0 then
            if ("Bal. Account No." <> xRec."Bal. Account No.") or ("Account No." <> xRec."Account No.") then
                PaymentToleranceMgt.PmtTolGenJnl(Rec);
    end;

    procedure IncludeVATAmount(): Boolean
    begin
        exit(
          ("VAT Posting" = "VAT Posting"::"Manual VAT Entry") and
          ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT"));
    end;

    procedure ConvertAmtFCYToLCYForSourceCurrency(Amount: Decimal): Decimal
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConvertAmtFCYToLCYForSourceCurrency(Rec, Amount, IsHandled);
        if IsHandled then
            exit(Amount);

        if (Amount = 0) or ("Source Currency Code" = '') then
            exit(Amount);

        Currency.Get("Source Currency Code");
        CurrencyFactor := CurrExchRate.ExchangeRate("Posting Date", "Source Currency Code");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Posting Date", "Source Currency Code", Amount, CurrencyFactor),
            Currency."Amount Rounding Precision"));
    end;

    procedure MatchSingleLedgerEntry()
    begin
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", Rec);
    end;

    procedure GetStyle(): Text
    begin
        if "Applied Automatically" then
            exit('Favorable')
    end;

    procedure GetDocumentBalance(var GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        DocGenJournalLine: Record "Gen. Journal Line";
    begin
        DocGenJournalLine.CopyFilters(GenJournalLine);
        DocGenJournalLine.SetRange("Posting Date", GenJournalLine."Posting Date");
        if GenJnlTemplate.Get(GenJournalLine."Journal Template Name") and GenJnlTemplate."Force Doc. Balance" then begin
            DocGenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
            DocGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type");
        end;
        OnGetDocumentBalanceOnBeforeCalcBalance(DocGenJournalLine, GenJnlTemplate);
        DocGenJournalLine.CalcSums("Balance (LCY)");
        exit(DocGenJournalLine."Balance (LCY)");
    end;

    procedure GetOverdueDateInteractions(var OverdueWarningText: Text): Text
    var
        DueDate: Date;
    begin
        DueDate := GetAppliesToDocDueDate();
        OverdueWarningText := '';
        if (DueDate <> 0D) and (DueDate < "Posting Date") then begin
            OverdueWarningText := DueDateMsg;
            exit('Unfavorable');
        end;
        exit('');
    end;

    procedure ClearDataExchangeEntries(DeleteHeaderEntries: Boolean)
    var
        DataExchField: Record "Data Exch. Field";
        GenJournalLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearDataExchangeEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Data Exch. Entry No." = 0 then
            exit;

        DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", "Data Exch. Line No.");

        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetRange("Data Exch. Entry No.", "Data Exch. Entry No.");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        if GenJournalLine.IsEmpty() or DeleteHeaderEntries then
            DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", 0);
    end;

    procedure ClearAppliedGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        if "Applies-to Doc. No." = '' then
            exit;

        IsHandled := false;
        OnBeforeModifyClearAppliedGenJnlLine(Rec, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        GenJournalLine.SetRange("Document Type", "Applies-to Doc. Type");
        GenJournalLine.SetRange("Document No.", "Applies-to Doc. No.");
        if not GenJournalLine.IsEmpty() then begin
            GenJournalLine.ModifyAll("Applied Automatically", false);
            GenJournalLine.ModifyAll("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.ModifyAll("Account No.", '');
        end;
    end;

    procedure GetIncomingDocumentURL(): Text[1024]
    var
        IncomingDocument: Record "Incoming Document";
    begin
        if "Incoming Document Entry No." = 0 then
            exit('');

        IncomingDocument.Get("Incoming Document Entry No.");
        exit(IncomingDocument.GetURL());
    end;

    procedure InsertPaymentFileError(Text: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.CreateNew(Rec, Text, '', '');
    end;

    procedure InsertPaymentFileErrorWithDetails(ErrorText: Text; AddnlInfo: Text; ExtSupportInfo: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.CreateNew(Rec, ErrorText, AddnlInfo, ExtSupportInfo);
    end;

    procedure DeletePaymentFileBatchErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.DeleteJnlBatchErrors(Rec);
    end;

    procedure DeletePaymentFileErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.DeleteJnlLineErrors(Rec);
    end;

    procedure HasPaymentFileErrors(): Boolean
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        exit(PaymentJnlExportErrorText.JnlLineHasErrors(Rec));
    end;

    procedure HasPaymentFileErrorsInBatch(): Boolean
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        exit(PaymentJnlExportErrorText.JnlBatchHasErrors(Rec));
    end;

    protected procedure UpdateDescriptionFromBalAccount(Name: Text[100])
    begin
        if not IsAdHocBalAccDescription() then
            Description := Name;
    end;

    local procedure IsAdHocBalAccDescription() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsAdHocBalAccDescription(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Keep Description" then
            exit(true);

        if "Account No." <> '' then
            exit(true);

        exit(false);
    end;

    protected procedure UpdateDescription(Name: Text[100])
    begin
        if not IsAdHocDescription() then
            Description := Name;
    end;

    local procedure IsAdHocDescription() Result: Boolean
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        FixedAsset: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsAdHocDescription(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Description = '' then
            exit(false);
        if xRec."Account No." = '' then
            exit(true);

        if "Keep Description" then
            exit(true);

        case xRec."Account Type" of
            xRec."Account Type"::"G/L Account":
                exit(GLAccount.Get(xRec."Account No.") and (GLAccount.Name <> Description));
            xRec."Account Type"::Customer:
                exit(Customer.Get(xRec."Account No.") and (Customer.Name <> Description));
            xRec."Account Type"::Vendor:
                exit(Vendor.Get(xRec."Account No.") and (Vendor.Name <> Description));
            xRec."Account Type"::"Bank Account":
                exit(BankAccount.Get(xRec."Account No.") and (BankAccount.Name <> Description));
            xRec."Account Type"::"Fixed Asset":
                exit(FixedAsset.Get(xRec."Account No.") and (FixedAsset.Description <> Description));
            xRec."Account Type"::"IC Partner":
                exit(ICPartner.Get(xRec."Account No.") and (ICPartner.Name <> Description));
            xRec."Account Type"::Employee:
                exit(Employee.Get(xRec."Account No.") and (Employee.FullName() <> Description));
        end;
        exit(false);
    end;

    procedure GetAppliesToDocEntryNo() Result: Integer
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgEntry, AccNo);
                    exit(CustLedgEntry."Entry No.");
                end;
            AccType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendLedgEntry, AccNo);
                    exit(VendLedgEntry."Entry No.");
                end;
            AccType::Employee:
                begin
                    GetAppliesToDocEmplLedgEntry(EmplLedgEntry, AccNo);
                    exit(EmplLedgEntry."Entry No.");
                end;
        end;

        OnAfterGetAppliesToDocEntryNo(Rec, AccType, AccNo, Result);
    end;

    procedure GetAppliesToDocDueDate() Result: Date
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAppliesToDocDueDate(Rec, Result, IsHandled);
        if IsHandled then
            exit;

        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgEntry, AccNo);
                    Result := CustLedgEntry."Due Date";
                end;
            AccType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendLedgEntry, AccNo);
                    Result := VendLedgEntry."Due Date";
                end;
        end;

        OnAfterGetAppliesToDocDueDate(Rec, AccType, AccNo, Result);
    end;

    procedure GetAppliesToDocPmtDiscountDate() Result: Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalAccountType: Enum "Gen. Journal Account Type";
        GenJournalAccountNo: Code[20];
    begin
        GetAccTypeAndNo(Rec, GenJournalAccountType, GenJournalAccountNo);
        case GenJournalAccountType of
            GenJournalAccountType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgerEntry, GenJournalAccountNo);
                    Result := CustLedgerEntry."Pmt. Discount Date";
                end;
            GenJournalAccountType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendorLedgerEntry, GenJournalAccountNo);
                    Result := VendorLedgerEntry."Pmt. Discount Date";
                end;
        end;

        OnAfterGetAppliesToDocPmtDiscountDate(Rec, GenJournalAccountType, GenJournalAccountNo, Result);
    end;

    local procedure GetAppliesToDocCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAppliesToDocCustLedgEntry(Rec, CustLedgEntry, AccNo, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if CustLedgEntry.FindFirst() then;
        end else
            if "Applies-to ID" <> '' then begin
                CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if CustLedgEntry.FindFirst() then;
            end;
    end;

    local procedure GetAppliesToDocVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; AccNo: Code[20])
    begin
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.FindFirst() then;
        end else
            if "Applies-to ID" <> '' then begin
                VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
                VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if VendLedgEntry.FindFirst() then;
            end;
    end;

    local procedure GetAppliesToDocEmplLedgEntry(var EmplLedgEntry: Record "Employee Ledger Entry"; AccNo: Code[20])
    begin
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if EmplLedgEntry.FindFirst() then;
        end else
            if "Applies-to ID" <> '' then begin
                EmplLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if EmplLedgEntry.FindFirst() then;
            end;
    end;

    procedure SetJournalLineFieldsFromApplication()
    var
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        "Exported to Payment File" := false;
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                if "Applies-to ID" <> '' then begin
                    if FindFirstCustLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToID(Rec, CustLedgEntry);
                        CustLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := CustLedgEntry.FindFirst();
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstCustLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToDocNo(Rec, CustLedgEntry);
                            "Exported to Payment File" := CustLedgEntry."Exported to Payment File";
                            "Applies-to Ext. Doc. No." := CustLedgEntry."External Document No.";
                        end;
            AccType::Vendor:
                if "Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToID(Rec, VendLedgEntry);
                        VendLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := VendLedgEntry.FindFirst();
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToDocNo(Rec, VendLedgEntry);
                            "Exported to Payment File" := VendLedgEntry."Exported to Payment File";
                            "Applies-to Ext. Doc. No." := VendLedgEntry."External Document No.";
                        end;
            AccType::Employee:
                if "Applies-to ID" <> '' then begin
                    if FindFirstEmplLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToID(Rec, EmplLedgEntry);
                        EmplLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := EmplLedgEntry.FindFirst();
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstEmplLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToDocNo(Rec, EmplLedgEntry);
                            "Exported to Payment File" := EmplLedgEntry."Exported to Payment File";
                        end;
        end;

        OnAfterSetJournalLineFieldsFromApplication(Rec, AccType, AccNo, xRec);
    end;

    procedure GetAccTypeAndNo(GenJnlLine2: Record "Gen. Journal Line"; var AccType: Enum "Gen. Journal Account Type"; var AccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAccTypeAndNo(GenJnlLine2, AccType, AccNo, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine2."Bal. Account Type" in
           [GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor, GenJnlLine2."Bal. Account Type"::Employee]
        then begin
            AccType := GenJnlLine2."Bal. Account Type";
            AccNo := GenJnlLine2."Bal. Account No.";
        end else begin
            AccType := GenJnlLine2."Account Type";
            AccNo := GenJnlLine2."Account No.";
        end;
    end;

    local procedure FindFirstCustLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open);
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange("Applies-to ID", AppliesToID);
        CustLedgEntry.SetRange(Open, true);
        OnFindFirstCustLedgEntryWithAppliesToIDOnAfterSetFilters(Rec, CustLedgEntry);
        exit(CustLedgEntry.FindFirst());
    end;

    local procedure FindFirstCustLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document No.", AppliestoDocNo);
        CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        OnFindFirstCustLedgEntryWithAppliesToDocNoOnAfterSetFilters(Rec, AccNo, CustLedgEntry);
        exit(CustLedgEntry.FindFirst());
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange("Applies-to ID", AppliesToID);
        VendLedgEntry.SetRange(Open, true);
        OnFindFirstVendLedgEntryWithAppliesToIDOnAfterSetFilters(Rec, VendLedgEntry);
        exit(VendLedgEntry.FindFirst());
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", AppliestoDocNo);
        VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        OnFindFirstVendLedgEntryWithAppliesToDocNoOnAfterSetFilters(Rec, AccNo, VendLedgEntry);
        exit(VendLedgEntry.FindFirst());
    end;

    local procedure FindFirstEmplLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        EmplLedgEntry.Reset();
        EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open);
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange("Applies-to ID", AppliesToID);
        EmplLedgEntry.SetRange(Open, true);
        exit(EmplLedgEntry.FindFirst());
    end;

    local procedure FindFirstEmplLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        EmplLedgEntry.Reset();
        EmplLedgEntry.SetCurrentKey("Document No.");
        EmplLedgEntry.SetRange("Document No.", AppliestoDocNo);
        EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        exit(EmplLedgEntry.FindFirst());
    end;

    protected procedure ClearPostingGroups()
    begin
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';

        OnAfterClearPostingGroups(Rec);
    end;

    protected procedure ClearBalancePostingGroups()
    begin
        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';

        OnAfterClearBalPostingGroups(Rec);
    end;

    procedure CancelBackgroundPosting()
    var
        GenJnlPostViaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
    begin
        GenJnlPostViaJobQueue.CancelQueueEntry(Rec);
        Reset();
        FilterGroup(2);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
    end;

    local procedure CleanLine()
    begin
        UpdateLineBalance();
        UpdateSource();
        CreateDimFromDefaultDim(0);
        if not ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]) then
            "Recipient Bank Account" := '';
        if xRec."Account No." <> '' then begin
            ClearPostingGroups();
            "Tax Area Code" := '';
            "Tax Liable" := false;
            "Tax Group Code" := '';
            "Bill-to/Pay-to No." := '';
            "Ship-to/Order Address Code" := '';
            "Sell-to/Buy-from No." := '';
            UpdateCountryCodeAndVATRegNo('');
        end;

        case "Account Type" of
            "Account Type"::"G/L Account":
                UpdateAccountID();
            "Account Type"::Customer:
                UpdateCustomerID();
            "Account Type"::"Bank Account":
                UpdateBankAccountID();
        end;

        OnAfterCleanLine(Rec, xRec);
    end;

    procedure ReplaceDescription() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReplaceDescription(Rec, GenJnlTemplate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Bal. Account No." = '' then
            Result := true
        else begin
            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            Result := GenJnlBatch."Bal. Account No." <> '';
        end;
        OnAfterReplaceDescription(GenJnlBatch, Result);
    end;

    local procedure AddCustVendIC(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Boolean
    begin
        SetRange("Account Type", AccountType);
        SetRange("Account No.", AccountNo);
        if not IsEmpty() then
            exit(false);

        Reset();
        if FindLast() then;
        "Line No." += 10000;

        "Account Type" := AccountType;
        "Account No." := AccountNo;
        Insert();
        exit(true);
    end;

    local procedure AssignJobCurrencyCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignJobCurrencyCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Job.Get("Job No.");
        Job.TestBlocked();
        Rec."Job Currency Code" := Job."Currency Code";
    end;

    procedure IsCustVendICAdded(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsCustVendICAdded(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJournalLine."Account No." <> '') and
           (GenJournalLine."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"])
        then
            exit(AddCustVendIC(GenJournalLine."Account Type", GenJournalLine."Account No."));

        if (GenJournalLine."Bal. Account No." <> '') and
           (GenJournalLine."Bal. Account Type" in ["Bal. Account Type"::Customer,
                                                   "Bal. Account Type"::Vendor,
                                                   "Bal. Account Type"::"IC Partner"])
        then
            exit(AddCustVendIC(GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No."));

        exit(false);
    end;

    procedure IsExportedToPaymentFile(): Boolean
    begin
        exit(IsPaymentJournallLineExported() or IsAppliedToVendorLedgerEntryExported());
    end;

    procedure IsPaymentJournallLineExported(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        OldFilterGroup: Integer;
        HasExportedLines: Boolean;
    begin
        GenJnlLine.CopyFilters(Rec);
        OldFilterGroup := GenJnlLine.FilterGroup;
        GenJnlLine.FilterGroup := 10;
        GenJnlLine.SetRange("Exported to Payment File", true);
        HasExportedLines := not GenJnlLine.IsEmpty();
        GenJnlLine.SetRange("Exported to Payment File");
        GenJnlLine.FilterGroup := OldFilterGroup;
        exit(HasExportedLines);
    end;

    procedure IsAppliedToVendorLedgerEntryExported(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJnlLine.CopyFilters(Rec);

        if GenJnlLine.FindSet() then
            repeat
                if GenJnlLine.IsApplied() then begin
                    VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                    if GenJnlLine."Applies-to Doc. No." <> '' then begin
                        VendLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                        VendLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                    end;
                    if GenJnlLine."Applies-to ID" <> '' then
                        VendLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendLedgerEntry.SetRange("Exported to Payment File", true);
                    if not VendLedgerEntry.IsEmpty() then
                        exit(true);
                end;

                VendLedgerEntry.Reset();
                VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                VendLedgerEntry.SetRange("Applies-to Doc. Type", GenJnlLine."Document Type");
                VendLedgerEntry.SetRange("Applies-to Doc. No.", GenJnlLine."Document No.");
                VendLedgerEntry.SetRange("Exported to Payment File", true);
                if not VendLedgerEntry.IsEmpty() then
                    exit(true);
            until GenJnlLine.Next() = 0;

        exit(false);
    end;

    local procedure ClearAppliedAutomatically()
    begin
        if CurrFieldNo <> 0 then
            "Applied Automatically" := false;
    end;

    local procedure ClearApplication(AccountType: Enum "Gen. Journal Account Type")
    begin
        if not (AccountType in [AccountType::Customer, AccountType::Vendor, AccountType::Employee]) then
            exit;

        if "Applies-to ID" <> '' then
            Validate("Applies-to ID", '');
        if "Applies-to Doc. No." <> '' then
            Validate("Applies-to Doc. No.", '');
    end;

    procedure SetPostingDateAsDueDate(DueDate: Date; DateOffset: DateFormula): Boolean
    var
        NewPostingDate: Date;
    begin
        if DueDate = 0D then
            exit(false);

        NewPostingDate := CalcDate(DateOffset, DueDate);
        if NewPostingDate < WorkDate() then begin
            Validate("Posting Date", WorkDate());
            exit(true);
        end;

        Validate("Posting Date", NewPostingDate);
        exit(false);
    end;

    procedure CalculatePostingDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
        EmptyDateFormula: DateFormula;
    begin
        GenJnlLine.Copy(Rec);
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");

        if GenJnlLine.FindSet() then begin
            Window.Open(CalcPostDateMsg);
            repeat
                Evaluate(EmptyDateFormula, '<0D>');
                GenJnlLine.SetPostingDateAsDueDate(GenJnlLine.GetAppliesToDocDueDate(), EmptyDateFormula);
                GenJnlLine.Modify(true);
                Window.Update(1, GenJnlLine."Document No.");
            until GenJnlLine.Next() = 0;
            Window.Close();
        end;
    end;

    procedure ImportBankStatement()
    var
        ProcessGenJnlLines: Codeunit "Process Gen. Journal  Lines";
    begin
        ProcessGenJnlLines.ImportBankStatement(Rec);

        OnAfterImportBankStatement(Rec);
    end;

    procedure ExportPaymentFile()
    var
        BankAcc: Record "Bank Account";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportPaymentFile(Rec, IsHandled);
        if IsHandled then
            exit;

        if not FindSet() then
            Error(NothingToExportErr);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
        TestField("Check Printed", false);
        TestField("Document Type");

        IsHandled := false;
        OnExportPaymentFileOnBeforeCheckDocNoOnLines(Rec, IsHandled);
        if not IsHandled then
            CheckDocNoOnLines();
        if IsExportedToPaymentFile() then
            if not ConfirmManagement.GetResponseOrDefault(ExportAgainQst, true) then
                exit;

        OnExportPaymentFileOnBeforeRunExport(Rec);
        BankAcc.Get("Bal. Account No.");
        if BankAcc.GetPaymentExportCodeunitID() > 0 then
            CODEUNIT.Run(BankAcc.GetPaymentExportCodeunitID(), Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", Rec);
        OnExportPaymentFileOnAfterRunExport(Rec);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
        PaymentToleranceMgt.SetSuppressCommit(SuppressCommit);
    end;

    procedure TotalExportedAmount() Result: Decimal
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTotalExportedAmount(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) then
            exit(0);
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);
        CreditTransferEntry.CalcSums("Transfer Amount");
        exit(CreditTransferEntry."Transfer Amount");
    end;

    procedure DrillDownExportedAmount()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownExportedAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) then
            exit;
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);
        PAGE.Run(PAGE::"Credit Transfer Reg. Entries", CreditTransferEntry);
    end;

    local procedure CopyDimensionsFromJobTaskLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDimensionsFromJobTaskLine(TempJobJnlLine, Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        "Dimension Set ID" := TempJobJnlLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := TempJobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TempJobJnlLine."Shortcut Dimension 2 Code";
    end;

    procedure CopyDocumentFields(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                              ExtDocNo: Text[35];
                                              SourceCode: Code[10];
                                              NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;

        OnAfterCopyDocumentFields(Rec, DocType, DocNo, ExtDocNo, SourceCode, NoSeriesCode);
    end;

    procedure CopyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        "Document Type" := CustLedgerEntry."Document Type";
        Description := CustLedgerEntry.Description;
        "Shortcut Dimension 1 Code" := CustLedgerEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := CustLedgerEntry."Global Dimension 2 Code";
        "Dimension Set ID" := CustLedgerEntry."Dimension Set ID";
        "Posting Group" := CustLedgerEntry."Customer Posting Group";
        "Source Type" := "Source Type"::Customer;
        "Source No." := CustLedgerEntry."Customer No.";

        OnAfterCopyGenJnlLineFromCustLedgEntry(CustLedgerEntry, Rec);
    end;

    procedure CopyVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        "Document Type" := VendorLedgerEntry."Document Type";
        Description := VendorLedgerEntry.Description;
        "Shortcut Dimension 1 Code" := VendorLedgerEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := VendorLedgerEntry."Global Dimension 2 Code";
        "Dimension Set ID" := VendorLedgerEntry."Dimension Set ID";
        "Posting Group" := VendorLedgerEntry."Vendor Posting Group";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := VendorLedgerEntry."Vendor No.";

        OnAfterCopyGenJnlLineFromVendLedgEntry(VendorLedgerEntry, Rec);
    end;

    procedure CopyFromGenJnlAllocation(GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
        "Account No." := GenJnlAlloc."Account No.";
        "Shortcut Dimension 1 Code" := GenJnlAlloc."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := GenJnlAlloc."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlAlloc."Dimension Set ID";
        "Gen. Posting Type" := GenJnlAlloc."Gen. Posting Type";
        "Gen. Bus. Posting Group" := GenJnlAlloc."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GenJnlAlloc."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GenJnlAlloc."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GenJnlAlloc."VAT Prod. Posting Group";
        "Tax Area Code" := GenJnlAlloc."Tax Area Code";
        "Tax Liable" := GenJnlAlloc."Tax Liable";
        "Tax Group Code" := GenJnlAlloc."Tax Group Code";
        "Use Tax" := GenJnlAlloc."Use Tax";
        "VAT Calculation Type" := GenJnlAlloc."VAT Calculation Type";
        "VAT Amount" := GenJnlAlloc."VAT Amount";
        "VAT Base Amount" := GenJnlAlloc.Amount - GenJnlAlloc."VAT Amount";
        "VAT %" := GenJnlAlloc."VAT %";
        "Source Currency Amount" := GenJnlAlloc."Additional-Currency Amount";
        Amount := GenJnlAlloc.Amount;
        "Amount (LCY)" := GenJnlAlloc.Amount;
        "VAT Amount (LCY)" := CalcVATAmountLCY();

        OnAfterCopyGenJnlLineFromGenJnlAllocation(GenJnlAlloc, Rec);
    end;

    procedure CopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        "Document Date" := IssuedFinChargeMemoHeader."Document Date";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedFinChargeMemoHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedFinChargeMemoHeader."VAT Bus. Posting Group";
        end;
        Validate("Currency Code", IssuedFinChargeMemoHeader."Currency Code");
        Description := IssuedFinChargeMemoHeader."Posting Description";
        "Source Type" := "Source Type"::Customer;
        "Source No." := IssuedFinChargeMemoHeader."Customer No.";
        "Reason Code" := IssuedFinChargeMemoHeader."Reason Code";
        "Posting No. Series" := IssuedFinChargeMemoHeader."No. Series";
        "Country/Region Code" := IssuedFinChargeMemoHeader."Country/Region Code";
        "VAT Registration No." := IssuedFinChargeMemoHeader."VAT Registration No.";
        "Shortcut Dimension 1 Code" := IssuedFinChargeMemoHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := IssuedFinChargeMemoHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := IssuedFinChargeMemoHeader."Dimension Set ID";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedFinChargeMemoHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedFinChargeMemoHeader."VAT Bus. Posting Group";
        end;

        OnAfterCopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader, Rec);
    end;

    procedure CopyFromIssuedFinChargeMemoLine(IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line")
    begin
        "Gen. Prod. Posting Group" := IssuedFinChargeMemoLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := IssuedFinChargeMemoLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := IssuedFinChargeMemoLine."VAT Calculation Type";
        "VAT %" := IssuedFinChargeMemoLine."VAT %";
        Validate(Amount, IssuedFinChargeMemoLine.Amount + IssuedFinChargeMemoLine."VAT Amount");
        "VAT Amount" := IssuedFinChargeMemoLine."VAT Amount";
    end;

    procedure CopyFromIssuedReminderHeader(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        "Document Date" := IssuedReminderHeader."Document Date";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedReminderHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedReminderHeader."VAT Bus. Posting Group";
        end;
        Validate("Currency Code", IssuedReminderHeader."Currency Code");
        Description := IssuedReminderHeader."Posting Description";
        "Source Type" := "Source Type"::Customer;
        "Source No." := IssuedReminderHeader."Customer No.";
        "Reason Code" := IssuedReminderHeader."Reason Code";
        "Posting No. Series" := IssuedReminderHeader."No. Series";
        "Country/Region Code" := IssuedReminderHeader."Country/Region Code";
        "VAT Registration No." := IssuedReminderHeader."VAT Registration No.";
        "Shortcut Dimension 1 Code" := IssuedReminderHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := IssuedReminderHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := IssuedReminderHeader."Dimension Set ID";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedReminderHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedReminderHeader."VAT Bus. Posting Group";
        end;

        OnAfterCopyFromIssuedReminderHeader(IssuedReminderHeader, Rec);
    end;

    procedure CopyFromIssuedReminderLine(IssuedReminderLine: Record "Issued Reminder Line")
    begin
        "Gen. Prod. Posting Group" := IssuedReminderLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := IssuedReminderLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := IssuedReminderLine."VAT Calculation Type";
        "VAT %" := IssuedReminderLine."VAT %";
        Validate(Amount, IssuedReminderLine.Amount + IssuedReminderLine."VAT Amount");
        "VAT Amount" := IssuedReminderLine."VAT Amount";

        OnAfterCopyFromIssuedReminderLine(Rec, IssuedReminderLine);
    end;

    procedure CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
        "Account No." := PrepmtInvLineBuffer."G/L Account No.";
        "Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        "Tax Area Code" := PrepmtInvLineBuffer."Tax Area Code";
        "Tax Liable" := PrepmtInvLineBuffer."Tax Liable";
        "Tax Group Code" := PrepmtInvLineBuffer."Tax Group Code";
        "Use Tax" := false;
        "VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        "Job No." := PrepmtInvLineBuffer."Job No.";
        Amount := PrepmtInvLineBuffer.Amount;
        "Source Currency Amount" := PrepmtInvLineBuffer."Amount (ACY)";
        "VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        "Source Curr. VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount (ACY)";
        "VAT Amount" := PrepmtInvLineBuffer."VAT Amount";
        "Source Curr. VAT Amount" := PrepmtInvLineBuffer."VAT Amount (ACY)";
        "VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        "VAT Base Before Pmt. Disc." := PrepmtInvLineBuffer."VAT Base Before Pmt. Disc.";

        OnAfterCopyGenJnlLineFromPrepmtInvBuffer(PrepmtInvLineBuffer, Rec);
    end;

    procedure CopyFromPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        "Source Currency Code" := PurchHeader."Currency Code";
        "Currency Factor" := PurchHeader."Currency Factor";
        Correction := PurchHeader.Correction;
        "VAT Base Discount %" := PurchHeader."VAT Base Discount %";
        "Sell-to/Buy-from No." := PurchHeader."Buy-from Vendor No.";
        "Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        "Country/Region Code" := PurchHeader."VAT Country/Region Code";
        "VAT Registration No." := PurchHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchHeader."Pay-to Vendor No.";
        "Posting No. Series" := PurchHeader."Posting No. Series";
        "IC Partner Code" := PurchHeader."Pay-to IC Partner Code";
        "Ship-to/Order Address Code" := PurchHeader."Order Address Code";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "On Hold" := PurchHeader."On Hold";
        if "Account Type" = "Account Type"::Vendor then
            "Posting Group" := PurchHeader."Vendor Posting Group";
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := PurchHeader."Journal Templ. Name";

        if PurchHeader."Remit-to Code" <> '' then
            "Remit-to Code" := PurchHeader."Remit-to Code";

        OnAfterCopyGenJnlLineFromPurchHeader(PurchHeader, Rec);
    end;

    procedure CopyFromPurchHeaderPrepmt(PurchHeader: Record "Purchase Header")
    begin
        "Source Currency Code" := PurchHeader."Currency Code";
        "VAT Base Discount %" := PurchHeader."VAT Base Discount %";
        "Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        "Country/Region Code" := PurchHeader."VAT Country/Region Code";
        "VAT Registration No." := PurchHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchHeader."Pay-to Vendor No.";
        "IC Partner Code" := PurchHeader."Buy-from IC Partner Code";
        "VAT Posting" := "VAT Posting"::"Manual VAT Entry";
        "System-Created Entry" := true;
        Prepayment := true;

        OnAfterCopyGenJnlLineFromPurchHeaderPrepmt(PurchHeader, Rec);
    end;

    procedure CopyFromPurchHeaderPrepmtPost(PurchHeader: Record "Purchase Header"; UsePmtDisc: Boolean)
    begin
        "Account Type" := "Account Type"::Vendor;
        "Account No." := PurchHeader."Pay-to Vendor No.";
        SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");
        "Source Currency Code" := PurchHeader."Currency Code";
        "Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        "Sell-to/Buy-from No." := PurchHeader."Buy-from Vendor No.";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := PurchHeader."Pay-to Vendor No.";
        "IC Partner Code" := PurchHeader."Buy-from IC Partner Code";
        "System-Created Entry" := true;
        Prepayment := true;
        "Due Date" := PurchHeader."Prepayment Due Date";
        "Payment Terms Code" := PurchHeader."Payment Terms Code";
        "Payment Method Code" := PurchHeader."Payment Method Code";
        if UsePmtDisc then begin
            "Pmt. Discount Date" := PurchHeader."Prepmt. Pmt. Discount Date";
            "Payment Discount %" := PurchHeader."Prepmt. Payment Discount %";
        end;

        OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost(PurchHeader, Rec, UsePmtDisc);
    end;

    procedure CopyFromPurchHeaderApplyTo(PurchHeader: Record "Purchase Header")
    begin
        "Applies-to Doc. Type" := PurchHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := PurchHeader."Applies-to Doc. No.";
        "Applies-to ID" := PurchHeader."Applies-to ID";
        "Allow Application" := PurchHeader."Bal. Account No." = '';

        OnAfterCopyGenJnlLineFromPurchHeaderApplyTo(PurchHeader, Rec);
    end;

    procedure CopyFromPurchHeaderPayment(PurchHeader: Record "Purchase Header")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        "Due Date" := PurchHeader."Due Date";
        "Invoice Received Date" := PurchHeader."Invoice Received Date";
        "Payment Terms Code" := PurchHeader."Payment Terms Code";
        "Pmt. Discount Date" := PurchHeader."Pmt. Discount Date";
        "Payment Discount %" := PurchHeader."Payment Discount %";
        "Creditor No." := PurchHeader."Creditor No.";
        if PurchHeader."Payment Reference" <> '' then
            "Payment Reference" := PurchHeader."Payment Reference"
        else begin
            PurchasesPayablesSetup.Get();
            if PurchasesPayablesSetup."Copy Inv. No. To Pmt. Ref." then
                "Payment Reference" := PurchHeader."Vendor Invoice No.";
        end;
        "Payment Method Code" := PurchHeader."Payment Method Code";

        OnAfterCopyGenJnlLineFromPurchHeaderPayment(PurchHeader, Rec);
    end;

    procedure CopyFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        "Source Currency Code" := SalesHeader."Currency Code";
        "Currency Factor" := SalesHeader."Currency Factor";
        "VAT Base Discount %" := SalesHeader."VAT Base Discount %";
        Correction := SalesHeader.Correction;
        "EU 3-Party Trade" := SalesHeader."EU 3-Party Trade";
        "Sell-to/Buy-from No." := SalesHeader."Sell-to Customer No.";
        "Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        "Country/Region Code" := SalesHeader."VAT Country/Region Code";
        "VAT Registration No." := SalesHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        "Posting No. Series" := SalesHeader."Posting No. Series";
        "Ship-to/Order Address Code" := SalesHeader."Ship-to Code";
        "IC Partner Code" := SalesHeader."Bill-to IC Partner Code";
        "Salespers./Purch. Code" := SalesHeader."Salesperson Code";
        "Your Reference" := SalesHeader."Your Reference";
        "On Hold" := SalesHeader."On Hold";
        if "Account Type" = "Account Type"::Customer then
            "Posting Group" := SalesHeader."Customer Posting Group";
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := SalesHeader."Journal Templ. Name";

        OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader, Rec);
    end;

    procedure CopyFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header")
    begin
        "Source Currency Code" := SalesHeader."Currency Code";
        "VAT Base Discount %" := SalesHeader."VAT Base Discount %";
        "EU 3-Party Trade" := SalesHeader."EU 3-Party Trade";
        "Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        "Country/Region Code" := SalesHeader."VAT Country/Region Code";
        "VAT Registration No." := SalesHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        "IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
        "VAT Posting" := "VAT Posting"::"Manual VAT Entry";
        "System-Created Entry" := true;
        Prepayment := true;

        OnAfterCopyGenJnlLineFromSalesHeaderPrepmt(SalesHeader, Rec);
    end;

    procedure CopyFromSalesHeaderPrepmtPost(SalesHeader: Record "Sales Header"; UsePmtDisc: Boolean)
    begin
        "Account Type" := "Account Type"::Customer;
        "Account No." := SalesHeader."Bill-to Customer No.";
        SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");
        "Source Currency Code" := SalesHeader."Currency Code";
        "Sell-to/Buy-from No." := SalesHeader."Sell-to Customer No.";
        "Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        "Salespers./Purch. Code" := SalesHeader."Salesperson Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        "IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
        "System-Created Entry" := true;
        Prepayment := true;
        "Due Date" := SalesHeader."Prepayment Due Date";
        "Payment Terms Code" := SalesHeader."Prepmt. Payment Terms Code";
        "Payment Method Code" := SalesHeader."Payment Method Code";
        "Posting Group" := SalesHeader."Customer Posting Group";
        if UsePmtDisc then begin
            "Pmt. Discount Date" := SalesHeader."Prepmt. Pmt. Discount Date";
            "Payment Discount %" := SalesHeader."Prepmt. Payment Discount %";
        end;

        OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost(SalesHeader, Rec, UsePmtDisc);
    end;

    procedure CopyFromSalesHeaderApplyTo(SalesHeader: Record "Sales Header")
    begin
        "Applies-to Doc. Type" := SalesHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := SalesHeader."Applies-to Doc. No.";
        "Applies-to ID" := SalesHeader."Applies-to ID";
        "Allow Application" := SalesHeader."Bal. Account No." = '';

        OnAfterCopyGenJnlLineFromSalesHeaderApplyTo(SalesHeader, Rec);
    end;

    procedure CopyFromSalesHeaderPayment(SalesHeader: Record "Sales Header")
    begin
        "Due Date" := SalesHeader."Due Date";
        "Payment Terms Code" := SalesHeader."Payment Terms Code";
        "Payment Method Code" := SalesHeader."Payment Method Code";
        "Pmt. Discount Date" := SalesHeader."Pmt. Discount Date";
        "Payment Discount %" := SalesHeader."Payment Discount %";
        "Direct Debit Mandate ID" := SalesHeader."Direct Debit Mandate ID";

        OnAfterCopyGenJnlLineFromSalesHeaderPayment(SalesHeader, Rec);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure CopyToGenJournalLine() in table Service Header', '25.0')]
    procedure CopyFromServiceHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        ServiceHeader.CopyToGenJournalLine(Rec);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CopyToGenJournalLineApplyTo() in table Service Header', '25.0')]
    procedure CopyFromServiceHeaderApplyTo(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        ServiceHeader.CopyToGenJournalLineApplyTo(Rec);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CopyToGenJournalLinePayment() in table Service Header', '25.0')]
    procedure CopyFromServiceHeaderPayment(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        ServiceHeader.CopyToGenJournalLinePayment(Rec);
    end;
#endif

    procedure CopyFromPaymentCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        "Document No." := CustLedgEntry."Document No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := CustLedgEntry."Customer No.";
        "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
        "Posting Group" := CustLedgEntry."Customer Posting Group";
        "Source Type" := "Source Type"::Customer;
        "Source No." := CustLedgEntry."Customer No.";
        "Source Currency Code" := CustLedgEntry."Currency Code";
        "System-Created Entry" := true;
        "Financial Void" := true;
        Correction := true;
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := CustLedgEntry."Journal Templ. Name";

        OnAfterCopyGenJnlLineFromPaymentCustLedgEntry(CustLedgEntry, Rec);
    end;

    procedure CopyFromPaymentVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        "Document No." := VendLedgEntry."Document No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := VendLedgEntry."Vendor No.";
        "Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        "Posting Group" := VendLedgEntry."Vendor Posting Group";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := VendLedgEntry."Vendor No.";
        "Source Currency Code" := VendLedgEntry."Currency Code";
        "System-Created Entry" := true;
        "Financial Void" := true;
        Correction := true;
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := VendLedgEntry."Journal Templ. Name";

        OnAfterCopyGenJnlLineFromPaymentVendLedgEntry(VendLedgEntry, Rec);
    end;

    procedure CopyFromPaymentEmpLedgEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        "Document No." := EmployeeLedgerEntry."Document No.";
        "Account Type" := "Account Type"::Employee;
        "Account No." := EmployeeLedgerEntry."Employee No.";
        "Shortcut Dimension 1 Code" := EmployeeLedgerEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := EmployeeLedgerEntry."Global Dimension 2 Code";
        "Dimension Set ID" := EmployeeLedgerEntry."Dimension Set ID";
        "Posting Group" := EmployeeLedgerEntry."Employee Posting Group";
        "Source Type" := "Source Type"::Employee;
        "Source No." := EmployeeLedgerEntry."Employee No.";
        "Source Currency Code" := EmployeeLedgerEntry."Currency Code";
        "System-Created Entry" := true;
        "Financial Void" := true;
        Correction := true;

        OnAfterCopyGenJnlLineFromPaymentEmplLedgEntry(EmployeeLedgerEntry, Rec);
    end;

    procedure CopyVATSetupToJnlLines(): Boolean
    begin
        if ("Journal Template Name" <> '') and ("Journal Batch Name" <> '') then
            if GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                exit(GenJnlBatch."Copy VAT Setup to Jnl. Lines");
        exit("Copy VAT Setup to Jnl. Lines");
    end;

    local procedure SetAmountWithCustLedgEntry()
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetAmountWithCustLedgEntry(Rec, CustLedgEntry);

        if "Currency Code" <> CustLedgEntry."Currency Code" then
            CheckModifyCurrencyCode(GenJnlLine."Account Type"::Customer, CustLedgEntry."Currency Code");
        if Amount = 0 then begin
            CustLedgEntry.CalcFields("Remaining Amount");
            IsHandled := false;
            OnSetAmountWithCustLedgEntryOnBeforeSetAmountWithRemaining(Rec, CustLedgEntry, IsHandled);
            if not IsHandled then
                SetAmountWithRemaining(
                  PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(Rec, CustLedgEntry, 0, false),
                  CustLedgEntry."Amount to Apply", CustLedgEntry."Remaining Amount", CustLedgEntry.GetRemainingPmtDiscPossible(Rec."Posting Date"));
        end;
    end;

    local procedure SetAmountWithVendLedgEntry()
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetAmountWithVendLedgEntry(Rec, VendLedgEntry);

        if "Currency Code" <> VendLedgEntry."Currency Code" then
            CheckModifyCurrencyCode("Account Type"::Vendor, VendLedgEntry."Currency Code");
        if Amount = 0 then begin
            VendLedgEntry.CalcFields("Remaining Amount");
            IsHandled := false;
            OnSetAmountWithVendLedgEntryOnBeforeSetAmountWithRemaining(Rec, VendLedgEntry, IsHandled);
            if not IsHandled then
                SetAmountWithRemaining(
                  PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(Rec, VendLedgEntry, 0, false),
                  VendLedgEntry."Amount to Apply", VendLedgEntry."Remaining Amount", VendLedgEntry.GetRemainingPmtDiscPossible(Rec."Posting Date"));
        end;
    end;

    local procedure SetAmountWithEmplLedgEntry()
    begin
        if Amount = 0 then begin
            EmplLedgEntry.CalcFields("Remaining Amount");
            SetAmountWithRemaining(false, EmplLedgEntry."Amount to Apply", EmplLedgEntry."Remaining Amount", 0.0);
        end;
    end;

    procedure CheckModifyCurrencyCode(AccountType: Enum "Gen. Journal Account Type"; CustVendLedgEntryCurrencyCode: Code[10])
    begin
        if Amount = 0 then
            UpdateCurrencyCode(CustVendLedgEntryCurrencyCode)
        else begin
            OnCheckModifyCurrencyCodeOnBeforeCheckAgainstApplnCurrency(Rec, VendLedgEntry, CustLedgEntry, AccountType);
            GenJnlApply.CheckAgainstApplnCurrency(
              "Currency Code", CustVendLedgEntryCurrencyCode, AccountType, true);
        end;
    end;

    protected procedure SetAmountWithRemaining(CalcPmtDisc: Boolean; AmountToApply: Decimal; RemainingAmount: Decimal; RemainingPmtDiscPossible: Decimal)
    begin
        if AmountToApply <> 0 then
            if CalcPmtDisc and (Abs(AmountToApply) >= Abs(RemainingAmount - RemainingPmtDiscPossible)) then
                Amount := -(RemainingAmount - RemainingPmtDiscPossible)
            else
                Amount := -AmountToApply
        else
            if CalcPmtDisc then
                Amount := -(RemainingAmount - RemainingPmtDiscPossible)
            else
                Amount := -RemainingAmount;
        if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor] then
            Amount := -Amount;

        OnAfterSetAmountWithRemaining(Rec, CustLedgEntry);
        ValidateAmount();
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if (BatchFilter = '') and ("Journal Batch Name" <> '') then
            BatchFilter := "Journal Batch Name";

        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if (TemplateFilter = '') and ("Journal Template Name" <> '') then begin
                TemplateFilter := "Journal Template Name";
                SetFilter("Journal Template Name", TemplateFilter);
            end;
            if TemplateFilter <> '' then
                GenJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            if DelChr(BatchFilter, '=', SpecialSymbolsTok) <> BatchFilter then
                BatchFilter := '''' + BatchFilter + '''';
            GenJournalBatch.SetFilter(Name, BatchFilter);
            GenJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure GetDeferralAmount() DeferralAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralAmount(Rec, DeferralAmount, IsHandled);
        if IsHandled then
            exit;

        if "VAT Base Amount" <> 0 then
            DeferralAmount := "VAT Base Amount"
        else
            DeferralAmount := Amount;

        OnAfterGetDeferralAmount(Rec, DeferralAmount);
    end;

    procedure ShowDeferrals(PostingDate: Date; CurrencyCode: Code[10]) ReturnValue: Boolean
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(
          DeferralUtilities.OpenLineScheduleEdit(
            "Deferral Code", Enum::"Deferral Document Type"::"G/L".AsInteger(), "Journal Template Name", "Journal Batch Name", 0, '', "Line No.",
            GetDeferralAmount(), PostingDate, Description, CurrencyCode));
    end;

    procedure IsForPurchase(): Boolean
    begin
        if ("Account Type" = "Account Type"::Vendor) or ("Bal. Account Type" = "Bal. Account Type"::Vendor) then
            exit(true);

        exit(false);
    end;

    procedure IsForSales(): Boolean
    begin
        if ("Account Type" = "Account Type"::Customer) or ("Bal. Account Type" = "Bal. Account Type"::Customer) then
            exit(true);

        exit(false);
    end;

    procedure IsForGLAccount(): Boolean
    begin
        if "Account Type" = "Account Type"::"G/L Account" then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLinePostRestrictions()
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLinePrintCheckRestrictions()
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnCheckGenJournalLineExportRestrictions()
    begin
    end;

    procedure NeedCheckZeroAmount(): Boolean
    begin
        exit(
          ("Account No." <> '') and
          not "System-Created Entry" and
          not "Allow Zero-Amount Posting" and
          ("Account Type" <> "Account Type"::"Fixed Asset"));
    end;

    procedure IsRecurring(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        if "Journal Template Name" <> '' then
            if GenJournalTemplate.Get("Journal Template Name") then
                exit(GenJournalTemplate.Recurring);

        exit(false);
    end;

    local procedure SuggestBalancingAmount(LastGenJnlLine: Record "Gen. Journal Line"; BottomLine: Boolean)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if "Document No." = '' then
            exit;
        if GetFilters <> '' then
            exit;

        GenJournalLine.SetRange("Journal Template Name", LastGenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", LastGenJnlLine."Journal Batch Name");
        if BottomLine then
            GenJournalLine.SetFilter("Line No.", '<=%1', LastGenJnlLine."Line No.")
        else
            GenJournalLine.SetFilter("Line No.", '<%1', LastGenJnlLine."Line No.");

        if GenJournalLine.FindLast() then begin
            if BottomLine then begin
                GenJournalLine.SetRange("Document No.", LastGenJnlLine."Document No.");
                GenJournalLine.SetRange("Posting Date", LastGenJnlLine."Posting Date");
            end else begin
                GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
                GenJournalLine.SetRange("Posting Date", GenJournalLine."Posting Date");
            end;
            GenJournalLine.SetRange("Bal. Account No.", '');
            if GenJournalLine.FindFirst() then begin
                GenJournalLine.CalcSums(Amount);
                if GenJournalLine.Amount = 0 then
                    exit;

                "Document No." := GenJournalLine."Document No.";
                "Posting Date" := GenJournalLine."Posting Date";
                Validate(Amount, -GenJournalLine.Amount);
            end;
        end;
    end;

    local procedure GetGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Account No.");
        CheckGLAcc(GLAcc);
        SetDescriptionFromGLAcc(GLAcc);

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
        if CopyVATSetupToJnlLines() then begin
            "Gen. Posting Type" := GLAcc."Gen. Posting Type";
            "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        end;
        "Tax Area Code" := GLAcc."Tax Area Code";
        "Tax Liable" := GLAcc."Tax Liable";
        "Tax Group Code" := GLAcc."Tax Group Code";
        if Rec."Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                ClearPostingGroups();
        Validate("Deferral Code", GLAcc."Default Deferral Template Code");

        GLSetup.Get();
        if ("Currency Code" = '') or (("Currency Code" = GLSetup."LCY Code") and (GLAcc."Source Currency Code" <> '')) then
            "Currency Code" := GLAcc."Source Currency Code";

        OnAfterAccountNoOnValidateGetGLAccount(Rec, GLAcc, CurrFieldNo);
    end;

    local procedure SetDescriptionFromGLAcc(GLAccount: Record "G/L Account")
    begin
        OnBeforeSetDescriptionFromGLAcc(Rec, GLAccount);

        if ReplaceDescription() and (not GLAccount."Omit Default Descr. in Jnl.") then
            UpdateDescription(GLAccount.Name)
        else
            if GLAccount."Omit Default Descr. in Jnl." then
                Description := '';
        OnAfterSetDescriptionFromGLAcc(Rec, GLAccount)
    end;

    local procedure GetGLBalAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Bal. Account No.");
        CheckGLAcc(GLAcc);
        UpdateDescriptionFromBalAccount(GLAcc.Name);
        if "Account No." = '' then
            "Currency Code" := '';
        OnGetGLBalAccountOnAfterSetDescription(Rec, GLAcc);
        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if CopyVATSetupToJnlLines() then begin
            "Bal. Gen. Posting Type" := GLAcc."Gen. Posting Type";
            "Bal. Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Bal. Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "Bal. VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
            "Bal. VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        end;
        "Bal. Tax Area Code" := GLAcc."Tax Area Code";
        "Bal. Tax Liable" := GLAcc."Tax Liable";
        "Bal. Tax Group Code" := GLAcc."Tax Group Code";
        if Rec."Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                ClearBalancePostingGroups();

        GLSetup.Get();
        if ("Currency Code" = '') or (("Currency Code" = GLSetup."LCY Code") and (GLAcc."Source Currency Code" <> '')) then
            "Currency Code" := GLAcc."Source Currency Code";

        OnAfterAccountNoOnValidateGetGLBalAccount(Rec, GLAcc, CurrFieldNo);
    end;

    local procedure GetCustomerAccount()
    var
        Cust: Record Customer;
    begin
        Cust.Get("Account No.");
        OnGetCustomerAccountOnAfterCustGet(Rec, Cust, CurrFieldNo);
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Account Type", "Account No.");
        UpdateDescription(Cust.Name);
        "Payment Method Code" := Cust."Payment Method Code";
        Validate("Recipient Bank Account", Cust."Preferred Bank Account Code");
        "Posting Group" := Cust."Customer Posting Group";
        SetSalespersonPurchaserCode(Cust."Salesperson Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Cust."Currency Code";
        ClearPostingGroups();
        CheckConfirmDifferentCustomerAndBillToCustomer(Cust, "Account No.");
        OnGetCustomerAccountOnBeforeValidatePaymentTermsCode(Rec, Cust, HideValidationDialog);
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetCustomerAccount(Rec, Cust, CurrFieldNo);
    end;

    local procedure CheckConfirmDifferentCustomerAndBillToCustomer(Cust: Record Customer; AccountNo: Code[20])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckConfirmDifferentCustomerAndBillToCustomer(Rec, Cust, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> AccountNo) and not HideValidationDialog then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption(), Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
    end;

    local procedure GetCustomerBalAccount()
    var
        Cust: Record Customer;
    begin
        Cust.Get("Bal. Account No.");
        OnGetCustomerBalAccountOnAfterCustGet(Rec, Cust, CurrFieldNo);
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        UpdateDescriptionFromBalAccount(Cust.Name);
        "Payment Method Code" := Cust."Payment Method Code";
        Validate("Recipient Bank Account", Cust."Preferred Bank Account Code");
        "Posting Group" := Cust."Customer Posting Group";
        SetSalespersonPurchaserCode(Cust."Salesperson Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Cust."Currency Code";
        CheckSetCurrencyCodeForBankCustLine(Cust);
        ClearBalancePostingGroups();
        CheckConfirmDifferentCustomerAndBillToCustomer(Cust, "Bal. Account No.");
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetCustomerBalAccount(Rec, Cust, CurrFieldNo);
    end;

    local procedure CheckSetCurrencyCodeForBankCustLine(Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSetCurrencyCodeForBankCustLine(Rec, Cust, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Cust."Currency Code";
    end;

    local procedure GetVendorAccount()
    var
        Vend: Record Vendor;
    begin
        Vend.Get("Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Account Type", "Account No.");
        UpdateDescription(Vend.Name);
        "Payment Method Code" := Vend."Payment Method Code";
        "Creditor No." := Vend."Creditor No.";

        OnGenJnlLineGetVendorAccount(Vend);

        Validate("Recipient Bank Account", Vend."Preferred Bank Account Code");
        "Posting Group" := Vend."Vendor Posting Group";
        SetSalespersonPurchaserCode(Vend."Purchaser Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Vend."Currency Code";
        ClearPostingGroups();
        CheckConfirmDifferentVendorAndPayToVendor(Vend, "Account No.");
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetVendorAccount(Rec, Vend, CurrFieldNo);
    end;

    local procedure GetCustVendNo(var CustVendNo: Code[20]; GenJnlLineToCheck: Record "Gen. Journal Line")
    begin
        if GenJnlLineToCheck."Account Type" in [GenJnlLineToCheck."Account Type"::Customer, GenJnlLineToCheck."Account Type"::Vendor] then
            CustVendNo := GenJnlLineToCheck."Account No.";
        if GenJnlLineToCheck."Bal. Account Type" in [GenJnlLineToCheck."Bal. Account Type"::Customer, GenJnlLineToCheck."Bal. Account Type"::Vendor] then
            CustVendNo := GenJnlLineToCheck."Bal. Account No.";
    end;

    local procedure CheckConfirmDifferentVendorAndPayToVendor(Vend: Record Vendor; AccountNo: Code[20])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckConfirmDifferentVendorAndPayToVendor(Rec, Vend, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> AccountNo) and
           not HideValidationDialog
        then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption(), Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
    end;

    local procedure GetEmployeeAccount()
    var
        Employee: Record Employee;
    begin
        Employee.Get("Account No.");
        Employee.CheckBlockedEmployeeOnJnls(false);
        UpdateDescriptionWithEmployeeName(Employee);
        "Posting Group" := Employee."Employee Posting Group";
        SetSalespersonPurchaserCode(Employee."Salespers./Purch. Code", "Salespers./Purch. Code");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Employee."Currency Code";
        ClearPostingGroups();

        OnAfterAccountNoOnValidateGetEmployeeAccount(Rec, Employee);
    end;

    local procedure GetVendorBalAccount()
    var
        Vend: Record Vendor;
    begin
        Vend.Get("Bal. Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        UpdateDescriptionFromBalAccount(Vend.Name);
        "Payment Method Code" := Vend."Payment Method Code";
        Validate("Recipient Bank Account", Vend."Preferred Bank Account Code");
        "Posting Group" := Vend."Vendor Posting Group";
        SetSalespersonPurchaserCode(Vend."Purchaser Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Vend."Currency Code";
        CheckSetCurrencyCodeForBankVendLine(Vend);
        ClearBalancePostingGroups();
        CheckConfirmDifferentVendorAndPayToVendor(Vend, "Bal. Account No.");
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetVendorBalAccount(Rec, Vend, CurrFieldNo);
    end;

    local procedure CheckSetCurrencyCodeForBankVendLine(Vend: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSetCurrencyCodeForBankVendLine(Rec, Vend, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Vend."Currency Code";
    end;

    local procedure GetEmployeeBalAccount()
    var
        Employee: Record Employee;
    begin
        Employee.Get("Bal. Account No.");
        Employee.CheckBlockedEmployeeOnJnls(false);
        if "Account No." = '' then
            UpdateDescriptionWithEmployeeName(Employee);
        "Posting Group" := Employee."Employee Posting Group";
        SetSalespersonPurchaserCode(Employee."Salespers./Purch. Code", "Salespers./Purch. Code");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Employee."Currency Code";
        ClearBalancePostingGroups();

        OnAfterAccountNoOnValidateGetEmployeeBalAccount(Rec, Employee, CurrFieldNo);
    end;

    local procedure GetBankAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Account No.");
        BankAcc.TestField(Blocked, false);
        if ReplaceDescription() then
            UpdateDescription(BankAcc.Name);
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
        ClearPostingGroups();

        OnAfterAccountNoOnValidateGetBankAccount(Rec, BankAcc, CurrFieldNo);
    end;

    local procedure GetBankBalAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bal. Account No.");
        BankAcc.TestField(Blocked, false);
        UpdateDescriptionFromBalAccount(BankAcc.Name);

        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if BankAcc."Currency Code" = '' then
            if "Account No." = '' then
                "Currency Code" := ''
            else
                ClearCurrencyCode()
        else
            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                BankAcc.TestField("Currency Code", "Currency Code")
            else
                "Currency Code" := BankAcc."Currency Code";
        ClearBalancePostingGroups();

        OnAfterAccountNoOnValidateGetBankBalAccount(Rec, xRec, BankAcc, CurrFieldNo);
    end;

    local procedure GetFAAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        UpdateDescription(FA.Description);
        GetFADeprBook("Account No.");
        GetFAVATSetup();
        GetFAAddCurrExchRate();

        OnAfterAccountNoOnValidateGetFAAccount(Rec, FA, CurrFieldNo);
    end;

    local procedure GetFABalAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Bal. Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        UpdateDescriptionFromBalAccount(FA.Description);
        GetFADeprBook("Bal. Account No.");
        GetFAVATSetup();
        GetFAAddCurrExchRate();

        OnAfterAccountNoOnValidateGetFABalAccount(Rec, FA);
    end;

    local procedure GetICPartnerAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Account No.");
        ICPartner.CheckICPartner();
        UpdateDescription(ICPartner.Name);
        if ("Bal. Account No." = '') or ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearPostingGroups();
        "IC Partner Code" := "Account No.";

        OnAfterAccountNoOnValidateGetICPartnerAccount(Rec, ICPartner);
    end;

    local procedure GetAllocationAccount()
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount.Get("Account No.");
        UpdateDescription(AllocationAccount.Name);
    end;

    local procedure GetICPartnerBalAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Bal. Account No.");
        UpdateDescriptionFromBalAccount(ICPartner.Name);

        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearBalancePostingGroups();
        "IC Partner Code" := "Bal. Account No.";

        OnAfterAccountNoOnValidateGetICPartnerBalAccount(Rec, ICPartner);
    end;

    procedure CreateFAAcquisitionLines(var FAGenJournalLine: Record "Gen. Journal Line")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        BalancingGenJnlLine: Record "Gen. Journal Line";
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
    begin
        TestField("Journal Template Name");
        TestField("Journal Batch Name");
        TestField("Posting Date");
        TestField("Account Type");
        TestField("Account No.");
        TestField("Posting Date");

        // Creating Fixed Asset Line
        FAGenJournalLine.Init();
        FAGenJournalLine.Validate("Journal Template Name", "Journal Template Name");
        FAGenJournalLine.Validate("Journal Batch Name", "Journal Batch Name");
        FAGenJournalLine.Validate("Line No.", GetNewLineNo("Journal Template Name", "Journal Batch Name"));
        FAGenJournalLine.Validate("Document Type", "Document Type");
        FAGenJournalLine.Validate("Document No.", GenerateLineDocNo("Journal Batch Name", "Posting Date", "Journal Template Name"));
        FAGenJournalLine.Validate("Account Type", "Account Type");
        FAGenJournalLine.Validate("Account No.", "Account No.");
        FAGenJournalLine.Validate(Amount, Amount);
        FAGenJournalLine.Validate("Currency Code", "Currency Code");
        FAGenJournalLine.Validate("Posting Date", "Posting Date");
        FAGenJournalLine.Validate("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
        FAGenJournalLine.Validate("External Document No.", "External Document No.");
        FAGenJournalLine.Insert(true);

        // Creating Balancing Line
        BalancingGenJnlLine.Copy(FAGenJournalLine);
        BalancingGenJnlLine.Validate("Account Type", "Bal. Account Type");
        BalancingGenJnlLine.Validate("Account No.", "Bal. Account No.");
        BalancingGenJnlLine.Validate(Amount, -Amount);
        BalancingGenJnlLine.Validate("Line No.", GetNewLineNo("Journal Template Name", "Journal Batch Name"));
        BalancingGenJnlLine.Insert(true);

        FAGenJournalLine.TestField("Posting Group");

        // Inserting additional fields in Fixed Asset line required for acquisition
        if FAPostingGr.GetPostingGroup(FAGenJournalLine."Posting Group", FAGenJournalLine."Depreciation Book Code") then begin
            LocalGLAcc.Get(FAPostingGr."Acquisition Cost Account");
            LocalGLAcc.CheckGLAcc();
            FAGenJournalLine.Validate("Gen. Posting Type", LocalGLAcc."Gen. Posting Type");
            FAGenJournalLine.Validate("Gen. Bus. Posting Group", LocalGLAcc."Gen. Bus. Posting Group");
            FAGenJournalLine.Validate("Gen. Prod. Posting Group", LocalGLAcc."Gen. Prod. Posting Group");
            FAGenJournalLine.Validate("VAT Bus. Posting Group", LocalGLAcc."VAT Bus. Posting Group");
            FAGenJournalLine.Validate("VAT Prod. Posting Group", LocalGLAcc."VAT Prod. Posting Group");
            FAGenJournalLine.Validate("Tax Group Code", LocalGLAcc."Tax Group Code");
            FAGenJournalLine.Validate("VAT Prod. Posting Group");
            FAGenJournalLine.Modify(true)
        end;

        OnAfterCreateFAAcquisitionLines(FAGenJournalLine, Rec, BalancingGenJnlLine);

        // Inserting Source Code
        if "Source Code" = '' then begin
            GenJnlTemplate.Get("Journal Template Name");
            FAGenJournalLine.Validate("Source Code", GenJnlTemplate."Source Code");
            FAGenJournalLine.Modify(true);
            BalancingGenJnlLine.Validate("Source Code", GenJnlTemplate."Source Code");
            BalancingGenJnlLine.Modify(true);
        end;
    end;

    local procedure GenerateLineDocNo(BatchName: Code[10]; PostingDate: Date; TemplateName: Code[20]) DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        if GenJournalBatch."No. Series" <> '' then
            DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series", PostingDate);
    end;

    local procedure GetFilterAccountNo(): Code[20]
    begin
        if GetFilter("Account No.") <> '' then
            if GetRangeMin("Account No.") = GetRangeMax("Account No.") then
                exit(GetRangeMax("Account No."));
    end;

    /// <summary>
    /// Sets the account number of the current general journal line based on the existing account number filter.
    /// </summary>
    procedure SetAccountNoFromFilter()
    var
        AccountNo: Code[20];
    begin
        AccountNo := GetFilterAccountNo();
        if AccountNo = '' then begin
            FilterGroup(2);
            AccountNo := GetFilterAccountNo();
            FilterGroup(0);
        end;
        if AccountNo <> '' then
            "Account No." := AccountNo;
    end;

    /// <summary>
    /// Returns the next unused journal line number for a template and batch.
    /// </summary>
    /// <param name="TemplateName">Template name to filter general journal line with.</param>
    /// <param name="BatchName">Batch name to filter general journal line with.</param>
    /// <returns>Next unused line number.</returns>
    procedure GetNewLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Validate("Journal Template Name", TemplateName);
        GenJournalLine.Validate("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        if GenJournalLine.FindLast() then
            exit(GenJournalLine."Line No." + 10000);
        exit(10000);
    end;

    /// <summary>
    /// Runs a report that voids electronic payments associated with a general journal line.
    /// </summary>
    /// <remarks>
    /// The report voids or transmits electronic payments, ensuring accurate and efficient payment processing.
    /// </remarks>
    procedure VoidPaymentFile()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalLine2: Record "Gen. Journal Line";
        VoidTransmitElecPmnts: Report "Void/Transmit Elec. Pmnts";
    begin
        TempGenJnlLine.Reset();
        TempGenJnlLine := Rec;
        TempGenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TempGenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine2.CopyFilters(TempGenJnlLine);
        GenJournalLine2.SetFilter("Document Type", 'Payment|Refund');
        GenJournalLine2.SetFilter("Bank Payment Type", 'Electronic Payment|Electronic Payment-IAT');
        GenJournalLine2.SetRange("Exported to Payment File", true);
        GenJournalLine2.SetRange("Check Transmitted", false);
        if not GenJournalLine2.FindFirst() then
            Error(NoEntriesToVoidErr);

        Clear(VoidTransmitElecPmnts);
        VoidTransmitElecPmnts.SetUsageType(1);   // Void
        VoidTransmitElecPmnts.SetTableView(TempGenJnlLine);
        if "Account Type" = "Account Type"::"Bank Account" then
            VoidTransmitElecPmnts.SetBankAccountNo("Account No.")
        else
            if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                VoidTransmitElecPmnts.SetBankAccountNo("Bal. Account No.");
        VoidTransmitElecPmnts.RunModal();
    end;

    /// <summary>
    /// Runs the report which transmits electronic payments associated with the general journal line.
    /// </summary>
    /// <remarks>
    /// The report voids or transmits electronic payments, ensuring accurate and efficient payment processing.
    /// </remarks>
    procedure TransmitPaymentFile()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        VoidTransmitElecPmnts: Report "Void/Transmit Elec. Pmnts";
    begin
        TempGenJnlLine.Reset();
        TempGenJnlLine := Rec;
        TempGenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TempGenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        Clear(VoidTransmitElecPmnts);
        VoidTransmitElecPmnts.SetUsageType(2);   // Transmit
        VoidTransmitElecPmnts.SetTableView(TempGenJnlLine);
        if "Account Type" = "Account Type"::"Bank Account" then
            VoidTransmitElecPmnts.SetBankAccountNo("Account No.")
        else
            if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                VoidTransmitElecPmnts.SetBankAccountNo("Bal. Account No.");
        VoidTransmitElecPmnts.RunModal();
    end;

    local procedure SetSalespersonPurchaserCode(SalesperPurchCodeToCheck: Code[20]; var SalesperPuchCodeToAssign: Code[20])
    begin
        if SalesperPurchCodeToCheck <> '' then
            if SalespersonPurchaser.Get(SalesperPurchCodeToCheck) then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    SalesperPuchCodeToAssign := ''
                else
                    SalesperPuchCodeToAssign := SalesperPurchCodeToCheck;
    end;

    /// <summary>
    /// Tests if the salesperson/purchaser privacy is not blocked of the provided general journal line.
    /// If privacy is blocked, an error is raised.
    /// </summary>
    /// <param name="GenJournalLine2">General journal line to check.</param>
    procedure ValidateSalesPersonPurchaserCode(GenJournalLine2: Record "Gen. Journal Line")
    begin
        if GenJournalLine2."Salespers./Purch. Code" <> '' then
            if SalespersonPurchaser.Get(GenJournalLine2."Salespers./Purch. Code") then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    Error(SalespersonPurchPrivacyBlockErr, GenJournalLine2."Salespers./Purch. Code");
    end;

    /// <summary>
    /// Checks if the privacy is blocked for the accounts associated with the general journal line.
    /// </summary>
    procedure CheckIfPrivacyBlocked()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
    begin
        if FindSet() then
            repeat
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            Customer.Get("Account No.");
                            if Customer."Privacy Blocked" then
                                Error(Customer.GetPrivacyBlockedGenericErrorText(Customer));
                            if Customer.Blocked = Customer.Blocked::All then
                                Error(BlockedErr, Customer.Blocked, Customer.TableCaption(), Customer."No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vendor.Get("Account No.");
                            if Vendor."Privacy Blocked" then
                                Error(Vendor.GetPrivacyBlockedGenericErrorText(Vendor));
                            if Vendor.Blocked in [Vendor.Blocked::All, Vendor.Blocked::Payment] then
                                Error(BlockedErr, Vendor.Blocked, Vendor.TableCaption(), Vendor."No.");
                        end;
                    "Account Type"::Employee:
                        begin
                            Employee.Get("Account No.");
                            if Employee."Privacy Blocked" then
                                Error(BlockedEmplErr, Employee."No.");
                        end;
                    else
                        OnCheckIfPrivacyBlockedCaseElse(Rec);
                end;
            until Next() = 0;
    end;

    local procedure CheckIfPostingDateIsEarlier(GenJournalLine: Record "Gen. Journal Line"; ApplyPostingDate: Date; ApplyDocType: Enum "Gen. Journal Document Type"; ApplyDocNo: Code[20];
                                                                                                                                      RecordVariant: Variant)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfPostingDateIsEarlier(GenJournalLine, ApplyPostingDate, ApplyDocType.AsInteger(), ApplyDocNo, IsHandled, RecordVariant, CustLedgEntry);
        if IsHandled then
            exit;

        if GenJournalLine."Posting Date" < ApplyPostingDate then
            Error(
              Text015, GenJournalLine."Document Type", GenJournalLine."Document No.", ApplyDocType, ApplyDocNo);
    end;

    local procedure CheckJobQueueStatus(GenJnlLine: Record "Gen. Journal Line")
    begin
        if not (GenJnlLine."Job Queue Status" in ["Job Queue Status"::" ", "Job Queue Status"::Error]) then
            Error(WrongJobQueueStatus);
    end;

    local procedure ClearCurrencyCode()
    var
        BankAccount: Record "Bank Account";
    begin
        if (xRec."Bal. Account Type" = xRec."Bal. Account Type"::"Bank Account") and (xRec."Bal. Account No." <> '') then begin
            BankAccount.Get(xRec."Bal. Account No.");
            if BankAccount."Currency Code" = "Currency Code" then
                "Currency Code" := '';
        end;
    end;

    local procedure CheckBalAccountNoOnJobNoValidation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountNoOnJobNoValidation(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Bal. Account No." <> '' then
            if not ("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"]) then
                Error(Text016, FieldCaption("Bal. Account Type"));
    end;

    local procedure HasNoMultipleLine(): Boolean
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine2.SetFilter("Line No.", '<>%1', "Line No.");
        GenJnlLine2.SetRange("Document No.", "Document No.");
        GenJnlLine2.SetRange("Account No.", xRec."Account No.");
        GenJnlLine2.SetRange("Applies-to ID", xRec."Applies-to ID");
        exit(GenJnlLine2.IsEmpty());
    end;

    local procedure CheckOpenApprovalEntryExistForCurrentUser()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        OnBeforeCheckOpenApprovalEntryExistForCurrentUser(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;
        ApprovalsMgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Rec);
        if GenJournalBatch.Get("Journal Template Name", "Journal Batch Name") then
            ApprovalsMgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(GenJournalBatch);
    end;

    local procedure GetAccCurrencyCode() CurrencyCode: Code[10]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
        ICPartner: Record "IC Partner";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAccCurrencyCode(Rec, CurrencyCode, IsHandled);
        if IsHandled then
            exit(CurrencyCode);

        if ("Account No." = '') or ("Currency Code" = '') then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    Customer.Get("Account No.");
                    CurrencyCode := Customer."Currency Code";
                end;
            "Account Type"::Vendor:
                begin
                    Vendor.Get("Account No.");
                    CurrencyCode := Vendor."Currency Code";
                end;
            "Account Type"::Employee:
                begin
                    Employee.Get("Account No.");
                    CurrencyCode := Employee."Currency Code";
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccount.Get("Account No.");
                    CurrencyCode := BankAccount."Currency Code";
                end;
            "Account Type"::"IC Partner":
                begin
                    ICPartner.Get("Account No.");
                    CurrencyCode := ICPartner."Currency Code";
                end;
        end;

        exit(CurrencyCode);
    end;

    local procedure RestrictGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        if GenJournalLine."System-Created Entry" or GenJournalLine.IsTemporary then
            exit;

        if ApprovalsMgmt.IsGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine) then
            RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, RestrictLineUsageDetailsTxt);

        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if ApprovalsMgmt.IsGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch) then
                RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, RestrictBatchUsageDetailsTxt);
    end;

    /// <summary>
    /// Calculates the currency factor for the general journal line based on the job currency factor and the journal line currency factor.
    /// </summary>
    /// <returns>Resulted currency factor</returns>
    procedure GetGenJnlLineToJobCurrencyFactor(): Decimal
    begin
        if "Currency Factor" = 0 then begin
            if "Job Currency Factor" = 0 then
                exit(1);
            exit("Job Currency Factor");
        end;
        if "Job Currency Factor" = 0 then
            exit(1 / "Currency Factor");
        exit("Job Currency Factor" / "Currency Factor");
    end;

    /// <summary>
    /// Event triggered before creating dimensions from the Default Dimensions during the validation of the "Account No." field.
    /// By subscribing to this event, developers can override the default dimension creation process for the "Account No." field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="IsHandled">A boolean variable that can be set to true to stop the validation process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAccountNoOnValidateOnBeforeCreateDim(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after the setup of a new General Journal Line is complete.
    /// This event allows developers to add custom logic or adjustments after the setup of a new General Journal Line is finalized.
    /// </summary>
    /// <param name="GenJournalLine">The new General Journal Line that has been set up.</param>
    /// <param name="GenJnlTemplate">The General Journal Template used for the new line.</param>
    /// <param name="GenJnlBatch">The General Journal Batch used for the new line.</param>
    /// <param name="LastGenJnlLine">The last General Journal Line used for assigning data to General Journal Line setup process.</param>
    /// <param name="Balance">Genaral journal line balance.</param>
    /// <param name="BottomLine">Indicates whether the current line is the last line in a batch of general journal lines.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplate: Record "Gen. Journal Template"; GenJournalBatch: Record "Gen. Journal Batch"; LastGenJournalLine: Record "Gen. Journal Line"; Balance: Decimal; BottomLine: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after setting the description from a G/L account for the general journal line.
    /// Subscribing to this event allows developers to extend the behavior
    /// after the description has been updated. This can be useful for implementing additional logic,
    /// logging, or further modifications to the description.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the description has been set.
    /// </param>
    /// <param name="GLAccount">
    /// The G/L account record from which the description was derived.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDescriptionFromGLAcc(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Event triggered after clearing customer application entry fields in the "Cust. Ledger Entry" record.
    /// This event allows developers to add custom logic after customer application entry fields have been cleared.
    /// </summary>
    /// <param name="CustLedgerEntry">The "Cust. Ledger Entry" record whose application entry fields have been cleared.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearCustApplnEntryFields(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after clearing employee application entry fields in the "Empl. Ledger Entry" record.
    /// This event allows developers to add custom logic after employee application entry fields have been cleared.
    /// </summary>
    /// <param name="EmployeeLedgerEntry">The "Empl. Ledger Entry" record whose application entry fields have been cleared.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearEmplApplnEntryFields(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after clearing vendor application entry fields in the "Vend. Ledger Entry" record.
    /// This event allows developers to add custom logic after vendor application entry fields have been cleared.
    /// </summary>
    /// <param name="VendorLedgerEntry">The "Vend. Ledger Entry" record whose application entry fields have been cleared.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVendApplnEntryFields(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a customer ledger entry to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from customer ledger entries. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="CustLedgerEntry">
    /// The customer ledger entry record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the customer ledger entry has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a vendor ledger entry to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from vendor ledger entries. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="VendLedgerEntry">
    /// The vendor ledger entry record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the vendor ledger entry has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromVendLedgEntry(VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a general journal allocation to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from general journal allocations. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="GenJnlAllocation">
    /// The general journal allocation record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the general journal allocation has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromGenJnlAllocation(GenJnlAllocation: Record "Gen. Jnl. Allocation"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a sales header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from sales headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="SalesHeader">
    /// The sales header record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the sales header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying prepayment-related data from a sales header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring prepayment-related data from sales headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied prepayment data.
    /// </summary>
    /// <param name="SalesHeader">
    /// The sales header record from which prepayment-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which prepayment-related data from the sales header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying prepayment-related data for posting from a sales header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring prepayment-related data for posting from sales headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied prepayment posting data.
    /// </summary>
    /// <param name="SalesHeader">
    /// The sales header record from which prepayment-related data for posting is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which prepayment-related data for posting from the sales header has been copied.
    /// </param>
    /// <param name="UsePmtDisc">
    /// A boolean variable indicating whether payment discount-related fields should be included.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after copying application-related data from a sales header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring application-related data from sales headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied application data.
    /// </summary>
    /// <param name="SalesHeader">
    /// The sales header record from which application-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which application-related data from the sales header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderApplyTo(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying payment-related data from a sales header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring payment-related data from sales headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied payment data.
    /// </summary>
    /// <param name="SalesHeader">
    /// The sales header record from which payment-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which payment-related data from the sales header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPayment(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a purchase header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from purchase headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="PurchaseHeader">
    /// The purchase header record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the purchase header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a purchase header for prepayment to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring prepayment-related data from purchase headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data specific to prepayments.
    /// </summary>
    /// <param name="PurchaseHeader">
    /// The purchase header record from which prepayment data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which prepayment data from the purchase header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmt(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a purchase header for prepayment posting to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring prepayment-related data from purchase headers during posting. This can be useful for implementing
    /// additional logic, validations, or custom handling specific to prepayment posting scenarios.
    /// </summary>
    /// <param name="PurchaseHeader">
    /// The purchase header record from which prepayment posting data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which prepayment posting data from the purchase header has been copied.
    /// </param>
    /// <param name="UsePmtDisc">
    /// A boolean variable indicating whether payment discounts should be considered when copying data.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from a purchase header for application purposes to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring application-related data from purchase headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data specific to applications.
    /// </summary>
    /// <param name="PurchaseHeader">
    /// The purchase header record from which application-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which application-related data from the purchase header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderApplyTo(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying payment-related data from a purchase header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring payment-related data from purchase headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied payment data.
    /// </summary>
    /// <param name="PurchaseHeader">
    /// The purchase header record from which payment-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which payment-related data from the purchase header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPayment(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterCopyGenJnlLineFromServHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnAfterCopyGenJnlLineFromServHeader(ServiceHeader, GenJournalLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToGenJnlLine in table Service Header', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromServHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyGenJnlLineFromServHeaderApplyTo(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnAfterCopyGenJnlLineFromServHeaderApplyTo(ServiceHeader, GenJournalLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToGenJnlLineApplyTo in table Service Header', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromServHeaderApplyTo(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyGenJnlLineFromServHeaderPayment(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnAfterCopyGenJnlLineFromServHeaderPayment(ServiceHeader, GenJournalLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToGenJnlLinePayment in table Service Header', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromServHeaderPayment(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
#endif

    /// <summary>
    /// Event triggered after copying data from a prepayment invoice line buffer to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from prepayment invoice line buffers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="PrepmtInvLineBuffer">
    /// The prepayment invoice line buffer record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the prepayment invoice line buffer has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPrepmtInvBuffer(PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying payment-related data from a customer ledger entry to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring payment-related data from customer ledger entries. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied payment data.
    /// </summary>
    /// <param name="CustLedgEntry">
    /// The customer ledger entry record from which payment-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which payment-related data from the customer ledger entry has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPaymentCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying payment-related data from a vendor ledger entry to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring payment-related data from vendor ledger entries. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied payment data.
    /// </summary>
    /// <param name="VendLedgEntry">
    /// The vendor ledger entry record from which payment-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which payment-related data from the vendor ledger entry has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPaymentVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying payment-related data from an employee ledger entry to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring payment-related data from employee ledger entries. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied payment data.
    /// </summary>
    /// <param name="EmployeeLedgerEntry">
    /// The employee ledger entry record from which payment-related data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which payment-related data from the employee ledger entry has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPaymentEmplLedgEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportBankStatement(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a G/L account in the context of the general journal line validation process.
    /// Subscribing to this event allows developers to override or extend the behavior
    /// when handling G/L account data. This can be useful for implementing additional logic,
    /// validations, or customization related to G/L accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record involved in the G/L account validation process.
    /// </param>
    /// <param name="GLAccount">
    /// The G/L account record that has been retrieved and validated.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account"; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving and setting up a balancing G/L account for the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when handling balancing G/L account data. This can be useful for implementing additional logic,
    /// validations, or customization related to balancing G/L accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing G/L account is being processed.
    /// </param>
    /// <param name="GLAccount">
    /// The balancing G/L account record that has been retrieved and processed.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the balancing G/L account.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account"; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after validating the customer account for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// after the customer account has been validated. This can be useful for implementing additional logic,
    /// logging, or further modifications based on the validated customer data.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the customer account has been validated.
    /// </param>
    /// <param name="Customer">
    /// The customer record that has been validated.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the customer account validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after validating the balancing customer account for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// after the balancing customer account has been validated. This can be useful for implementing additional logic,
    /// logging, or further modifications based on the validated balancing customer data.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing customer account has been validated.
    /// </param>
    /// <param name="Customer">
    /// The customer record that has been validated as the balancing account.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the balancing customer account validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after validating the vendor account for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// after the vendor account has been validated. This can be useful for implementing additional logic,
    /// logging, or further modifications based on the validated vendor data.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the vendor account has been validated.
    /// </param>
    /// <param name="Vendor">
    /// The vendor record that has been validated.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the vendor account validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a vendor record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing vendor account data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing vendor accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing vendor account is being processed.
    /// </param>
    /// <param name="Vendor">
    /// The vendor record that has been retrieved and processed as the balancing account.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the balancing vendor account.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving an employee record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing employee account data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to employee accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the employee account is being processed.
    /// </param>
    /// <param name="Employee">
    /// The employee record that has been retrieved and processed.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetEmployeeAccount(var GenJournalLine: Record "Gen. Journal Line"; var Employee: Record Employee)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving an employee record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing employee account data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing employee accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing employee account is being processed.
    /// </param>
    /// <param name="Employee">
    /// The employee record that has been retrieved and processed as the balancing account.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the balancing employee account.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetEmployeeBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Employee: Record Employee; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a bank account record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing bank account data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to bank accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the bank account is being processed.
    /// </param>
    /// <param name="BankAccount">
    /// The bank account record that has been retrieved and processed.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the bank account validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetBankAccount(var GenJournalLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account"; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a bank account record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing bank account data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing bank accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing bank account is being processed.
    /// </param>
    /// <param name="xGenJournalLine">
    /// The previous version of the general journal line record, used for comparison or additional logic.
    /// </param>
    /// <param name="BankAccount">
    /// The bank account record that has been retrieved and processed as the balancing account.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the balancing bank account validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetBankBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account"; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a fixed asset record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing fixed asset data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to fixed assets.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the fixed asset account is being processed.
    /// </param>
    /// <param name="FixedAsset">
    /// The fixed asset record that has been retrieved and processed.
    /// </param>
    /// <param name="CurrFieldNo">
    /// The current field number being processed in the context of the fixed asset validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetFAAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset"; CurrFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a fixed asset record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing fixed asset data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing fixed asset accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing fixed asset account is being processed.
    /// </param>
    /// <param name="FixedAsset">
    /// The fixed asset record that has been retrieved and processed as the balancing account.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetFABalAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving an intercompany partner record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing intercompany partner account data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to intercompany partner accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the intercompany partner account is being processed.
    /// </param>
    /// <param name="ICPartner">
    /// The intercompany partner record that has been retrieved and processed.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetICPartnerAccount(var GenJournalLine: Record "Gen. Journal Line"; var ICPartner: Record "IC Partner")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving an intercompany partner record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing intercompany partner data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing intercompany partner accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing intercompany partner account is being processed.
    /// </param>
    /// <param name="ICPartner">
    /// The intercompany partner record that has been retrieved and processed as the balancing account.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetICPartnerBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var ICPartner: Record "IC Partner")
    begin
    end;

    /// <summary>
    /// Event triggered after the temporary Job Journal Line has been created.
    /// This event allows developers to add custom logic or modify the temporary Job Journal Line after it has been created.
    /// </summary>
    /// <param name="JobJournalLine">The temporary Job Journal Line record that was created.</param>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes were applied.</param>
    /// <param name="CurrFieldNo">The number of the current field being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for the Vendor Ledger Entry during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to adjust or add additional filters to the Vendor Ledger Entry record after the default filters have been set.
    /// </summary>
    /// <param name="GenJournalLine">The current general journal line being processed.</param>
    /// <param name="VendorLedgerEntry">The vendor ledger entry record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnAfterVendLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for the Customer Ledger Entry during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to adjust or add additional filters to the Customer Ledger Entry record after the default filters have been set.
    /// </summary>
    /// <param name="Rec">The current Gen. Journal Line being processed.</param>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record with filters set.</param>
    /// <param name="TempGenJnlLine">A temporary Gen. Journal Line record used for processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnAfterCustLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    /// <summary>
    /// Event triggered before updating amounts for ledger entries during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to add custom logic before the default updates to amounts are made for ledger entries.
    /// </summary>
    /// <param name="GenJournalLine">The current Gen. Journal Line being processed.</param>
    /// <param name="TempGenJnlLine">A temporary Gen. Journal Line record used for processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnBeforeUpdAmtToEntries(var GenJournalLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after updating amounts for ledger entries during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to add additional processing after amounts have been updated for the related ledger entries.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="TempGenJnlLine">A temporary General Journal Line record used during the processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnAfterUpdAmtToEntries(var GenJournalLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before validating apply requirements during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to add custom logic before the default apply requirements validation has been finished.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnBeforeValidateApplyRequirements(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before assigning the Job Currency Code to the current record.
    /// This event allows developers to add custom logic or skip the default logic for assigning the Job Currency Code.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for assigning the Job Currency Code.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignJobCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before clearing customer/vendor/employee application entries in the General Journal Line.
    /// This event allows developers to change the custom logic before the default logic for clearing customer/vendor/employees application entries has been executed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="AccType">The account type of the General Journal Line.</param>
    /// <param name="AccNo">The account number associated with the General Journal Line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before creating a temporary Job Journal Line.
    /// This event allows developers to implement custom logic or skip the default creation process for the temporary Job Journal Line.
    /// </summary>
    /// <param name="JobJournalLine">The temporary Job Journal Line record being created.</param>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes were applied.</param>
    /// <param name="CurrFieldNo">The number of the current field being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for creating the temporary Job Journal Line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before the drill-down on the exported amount has been performed.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when drilling down on the exported amount. This can be useful for implementing
    /// custom filtering, logging, or other specialized logic regarding credit transfer entries.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The record from which the drill-down on the exported amount has been initialized.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean flag indicating whether the default drill-down logic should be skipped.
    /// Setting this flag to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownExportedAmount(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting up a new General Journal Line.
    /// This event allows developers to add custom logic or skip the default setup logic for a new General Journal Line.
    /// </summary>
    /// <param name="GenJnlTemplate">The General Journal Template being used for the new line.</param>
    /// <param name="GenJnlBatch">The General Journal Batch being used for the new line.</param>
    /// <param name="GenJnlLine">The General Journal Line record being set up.</param>
    /// <param name="LastGenJnlLine">The last General Journal Line used for assigning data to General Journal Line setup process.</param>
    /// <param name="GLSetupRead">Indicates whether the GL Setup has been read.</param>
    /// <param name="Balance">Genaral journal line balance.</param>
    /// <param name="BottomLine">Indicates whether the current line is the last line in a batch of general journal lines.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default setup logic for the new line.</param>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var GLSetupRead: Boolean; Balance: Decimal; BottomLine: Boolean; var IsHandled: Boolean; var Rec: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after updating prices from the temporary Job Journal Line.
    /// This event allows developers to implement custom logic after the prices and costs have been updated from the temporary Job Journal Line
    /// to the current General Journal Line record.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with updated prices and costs.</param>
    /// <param name="JobJournalLine">The temporary Job Journal Line record used to update the prices and costs.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePricesFromJobJnlLine(var GenJournalLine: Record "Gen. Journal Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Sales/Purch. (LCY)" field in the Gen. Journal Line.
    /// This event allows developers to add custom calculations after the "Sales/Purch. (LCY)" value has been updated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line where the "Sales/Purch. (LCY)" field has been updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesPurchLCY(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after creating fixed asset acquisition lines in the general journal.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when generating fixed asset acquisition lines and the corresponding balancing lines. This can be useful
    /// for implementing additional logic, validations, or handling specific business rules related to fixed asset acquisitions.
    /// </summary>
    /// <param name="FAGenJournalLine">
    /// The general journal line record representing the fixed asset acquisition line.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the fixed asset acquisition lines are being created.
    /// </param>
    /// <param name="BalancingGenJournalLine">
    /// The general journal line record representing the balancing line for the fixed asset acquisition.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateFAAcquisitionLines(var FAGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line"; var BalancingGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after clearing the posting group fields on the current record.
    /// This event allows developers to change custom logic after the posting groups have been reset.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with cleared posting group fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearPostingGroups(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after clearing the balance posting group fields on the current record.
    /// This event allows developers to change custom logic after the balance posting groups have been reset.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with cleared balance posting group fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearBalPostingGroups(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the "Due Date" of the related applied document.
    /// This event allows developers to add custom logic or override the retrieved due date.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="AccType">The account type used to determine the document due date (e.g., Customer, Vendor).</param>
    /// <param name="AccNo">The account number associated with the selected account type.</param>
    /// <param name="Result">A date variable representing the retrieved document due date.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToDocDueDate(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; var Result: Date)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the "Pmt. Discount Date" of the related applied document.
    /// This event allows developers to add custom logic or override the retrieved payment discount date.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="GenJournalAccountType">The account type used to determine the payment discount date (e.g., Customer, Vendor).</param>
    /// <param name="GenJournalAccountNo">The account number associated with the selected account type.</param>
    /// <param name="Result">A date variable representing the retrieved payment discount date.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToDocPmtDiscountDate(var GenJournalLine: Record "Gen. Journal Line"; GenJournalAccountType: Enum "Gen. Journal Account Type"; GenJournalAccountNo: Code[20]; var Result: Date)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the "Entry No." based on the account type and account number.
    /// This event allows developers to add custom logic after retrieving the "Entry No.".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="AccType">The account type used to determine the document entry number (e.g., Customer, Vendor, Employee).</param>
    /// <param name="AccNo">The account number associated with the selected account type.</param>
    /// <param name="Result">An integer representing the retrieved document entry number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToDocEntryNo(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; var Result: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after the Customer Ledger Entry has been retrieved and processed.
    /// This event allows developers to add custom logic to update the General Journal Line.
    /// </summary>
    /// <param name="Rec">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record that was retrieved and processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after calculating the deferral amount.
    /// Subscribing to this event allows developers to extend the behavior
    /// after the deferral amount has been determined. This can be useful for implementing custom
    /// logic, logging, or further adjustments to the calculated deferral amount.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the deferral amount has been calculated.
    /// </param>
    /// <param name="DeferralAmount">
    /// The calculated deferral amount that can be further adjusted by the subscriber.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeferralAmount(var GenJournalLine: Record "Gen. Journal Line"; var DeferralAmount: Decimal)
    begin
    end;

    /// <summary>
    /// Event triggered after the Employee Ledger Entry has been fully retrieved and processed.
    /// This event allows developers to add custom logic to update the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="EmployeeLedgerEntry">The Employee Ledger Entry record that was retrieved and processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmplLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the depreciation book for a fixed asset.
    /// This event allows developers to add custom logic after the depreciation book is retrieved.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record where the depreciation book code has been updated.</param>
    /// <param name="FANo">The Fixed Asset number for which the depreciation book has been determined.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFADeprBook(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving the VAT Posting Setup record based on the provided VAT Business Posting Group and VAT Product Posting Group.
    /// This event allows developers to change the default logic after the VAT Posting Setup record has been retrieved or initialized.
    /// </summary>
    /// <param name="VATPostingSetup">The VAT Posting Setup record that was retrieved or initialized.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    /// <summary>
    /// Event triggered after the Vendor Ledger Entry has been retrieved and processed.
    /// This event allows developers to add custom logic to update the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record that was retrieved and processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after initializing a new General Journal Line with the provided data.
    /// This event allows developers to add custom logic after the initialization of a new General Journal Line has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The initialized General Journal Line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after calculating sales tax during the validation of the "VAT Base Amount" or "Bal. VAT Base Amount" fields.
    /// This event allows developers to add custom logic after the sales tax has been calculated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CurrFieldNo">The number of the field currently being validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after the reverse calculation of sales tax during VAT calculation.
    /// Subscribing to this event allows developers to execute custom logic immediately after the reverse calculation of sales tax has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="CurrFieldNo">The number of the currently validated field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverseCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after the "Amount to Apply" has been set for the relevant ledger entry.
    /// This event allows developers to add custom logic after the "Amount to Apply" has been calculated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToAmount(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Country/Region Code" and "VAT Registration No." fields.
    /// This event allows developers to add custom logic after the fields have been updated based on the No. provided.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with updated fields.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the update.</param>
    /// <param name="No">The account number (Customer or Vendor) used to retrieve the "Country/Region Code" and "VAT Registration No".</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCountryCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered after the "Amount" field has been validated in the General Journal Line.
    /// This event allows developers to change the calculations of General Journal Line fields.
    /// </summary>
    /// <param name="GenJnlLine">The current General Journal Line that was processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAmount(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after validating requirements to apply for a General Journal Line.
    /// This event allows developers to add custom logic after the validation process for apply requirements has been completed.
    /// </summary>
    /// <param name="TempGenJnlLine">The temporary General Journal Line record that was validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateApplyRequirements(TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    /// <summary>
    /// Event triggered after validating a shortcut dimension code in the General Journal Line.
    /// This event allows developers to add custom logic after the shortcut dimension code has been validated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension that was validated.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code that was validated.</param>
    /// <param name="CurrFieldNo">The number of field currently being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after checking the "Direct Posting" field on a G/L Account in the General Journal Line.
    /// This event allows developers to change the default logic after the "Direct Posting" field has been validated.
    /// </summary>
    /// <param name="GLAccount">The G/L Account record that was validated.</param>
    /// <param name="GenJournalLine">The current General Journal Line that was processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDirectPosting(var GLAccount: Record "G/L Account"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after setting the amount using the remaining values from a ledger entry.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when setting the amount based on calculated payment discounts, amounts to apply, and remaining values.
    /// This can be useful for implementing custom calculations, validations, or additional business logic.
    /// </summary>
    /// <param name="GenJnlLine">
    /// The general journal line record whose amount is being set.
    /// </param>
    /// <param name="CustLedgEntry">
    /// The customer ledger entry record used in the calculation of the amount, if applicable.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after completing the processing of setting journal line fields from application data.
    /// This event allows developers to add additional logic after journal line fields have been set.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="AccType">The account type used during processing (e.g., Customer, Vendor, Employee).</param>
    /// <param name="AccNo">The account number associated with the selected account type.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes were applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20];
                                                                                                                            xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Applies-to Doc. Type" and "Applies-to Doc. No." fields in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when these fields are updated. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to document type and applies-to fields.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record where the "Applies-to Doc. Type" and "Applies-to Doc. No." fields have been updated.
    /// </param>
    /// <param name="DocType">
    /// The updated document type represented as an integer.
    /// </param>
    /// <param name="DocNo">
    /// The updated document number.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDocumentTypeAndAppliesToFields(var GenJournalLine: Record "Gen. Journal Line"; DocType: Integer; DocNo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before clearing the "Job No." field in the General Journal Line.
    /// This event allows developers to add custom logic or skip the default validation process.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CurrentFieldNo">The number of field currently being validated.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default clearing of the "Job No." field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlankJobNo(var GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Account Type" field in the General Journal Line.
    /// This event allows developers to change the default validation logic for the "Account Type" field.
    /// </summary>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "Account Type" field.</param>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAccountTypeOnJobValidation(var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before checking the "Direct Posting" field on a G/L Account in the General Journal Line.
    /// This event allows developers to change the default logic for the "Direct Posting" field.
    /// </summary>
    /// <param name="GLAccount">The G/L Account record being validated.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "Direct Posting" field.</param>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectPosting(var GLAccount: Record "G/L Account"; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocNoOnLines(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered prior to checking if the posting date of a general journal line is before the applied document's posting date.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when validating posting dates. This can be useful for implementing additional logic, custom validations,
    /// or handling specific scenarios related to posting date comparisons.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record being validated.
    /// </param>
    /// <param name="ApplyPostingDate">
    /// The posting date of the document being applied.
    /// </param>
    /// <param name="ApplyDocType">
    /// The document type of the document being applied, represented as an integer.
    /// </param>
    /// <param name="ApplyDocNo">
    /// The document number of the document being applied.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for the posting date comparison should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    /// <param name="RecordVariant">
    /// A variant representing additional data or context related to the applied document.
    /// </param>
    /// <param name="CustLedgerEntry">
    /// The customer ledger entry record, if applicable, associated with the validation process.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPostingDateIsEarlier(GenJournalLine: Record "Gen. Journal Line"; ApplyPostingDate: Date; ApplyDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; ApplyDocNo: Code[20]; var IsHandled: Boolean; RecordVariant: Variant; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;


    /// <summary>
    /// Event triggered before copying dimensions from the job task line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when copying dimension information from the job journal line. This can be useful for
    /// implementing custom dimension handling, additional validations, or logging.
    /// </summary>
    /// <param name="TempJobJnlLine">
    /// The temporary job journal line record from which dimensions will be copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The current general journal line record to which dimensions will be copied.
    /// </param>
    /// <param name="xGenJournalLine">
    /// The previous version of the general journal line record, used for comparison or other logic.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default copy-dimension logic should be skipped.
    /// Setting this flag to 'true' will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimensionsFromJobTaskLine(TempJobJnlLine: Record "Job Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before determining the Account Type and Account No. from a General Journal Line.
    /// This event allows developers to add custom logic or skip the default logic for setting account type and number.
    /// </summary>
    /// <param name="GenJournalLine2">The General Journal Line record being processed.</param>
    /// <param name="AccType">The Account Type to be determined from the General Journal Line (e.g., Customer, Vendor, Employee).</param>
    /// <param name="AccNo">The account number to be determined from the General Journal Line.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining Account Type and Account No.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAccTypeAndNo(GenJournalLine2: Record "Gen. Journal Line"; var AccType: Enum "Gen. Journal Account Type"; var AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving the deferral posting date.
    /// This event allows developers to implement custom logic or override the default procedure for determining the deferral posting date.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="DeferralPostDate">The deferral posting date to be returned. This value is used if IsHandled is set to true.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for retrieving the deferral posting date.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralPostDate(GenJournalLine: Record "Gen. Journal Line"; var DeferralPostDate: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving the depreciation book for a fixed asset.
    /// This event allows developers to implement custom logic before the process of setting the depreciation book code has begun.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record where the depreciation book code is being determined.</param>
    /// <param name="FANo">The Fixed Asset No. for which the depreciation book is being retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFADeprBook(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving the Vendor Ledger Entry.
    /// This event allows developers to add custom logic or skip the default logic for retrieving the Vendor Ledger Entry.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="isHandled">A boolean variable that, if set to true, skips the default logic for retrieving the Vendor Ledger Entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving the Customer Ledger Entry.
    /// This event allows developers to implement custom logic or skip the default logic for retrieving the Customer Ledger Entry.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="isHandled">A boolean variable that, if set to true, skips the default logic for retrieving the Customer Ledger Entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before determining if the General Journal Line is empty.
    /// This event allows developers to add custom logic or override the default logic used to determine if the line is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being evaluated.</param>
    /// <param name="Result">A boolean variable representing whether the line is considered empty. If IsHandled is set to true, this value determines the result.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic and uses the value of Result variable.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmptyLine(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before determining if a Customer, Vendor, or IC Partner is added based on the General Journal Line.
    /// This event allows developers to add custom logic or skip the default logic for checking the addition of Customer, Vendor, or IC Partner.
    /// </summary>
    /// <param name="GenJournalLine">The General Journal Line record being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining if a Customer, Vendor, or IC Partner is added.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCustVendICAdded(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before determining if the description is considered ad-hoc.
    /// This event allows developers to add custom logic or skip the default logic for identifying ad-hoc descriptions.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes.</param>
    /// <param name="Result">A boolean variable indicating whether the description is considered ad-hoc.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining ad-hoc descriptions.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsAdHocDescription(GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before determining if the balance account description is ad-hoc.
    /// This event allows developers to add custom logic or skip the default logic for determining ad-hoc balance account descriptions.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes.</param>
    /// <param name="Result">A boolean variable indicating whether the description is considered ad-hoc.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining ad-hoc balance account descriptions.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsAdHocBalAccDescription(GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before the job task has been set.
    /// This event allows developers to implement custom logic or override the default process.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being evaluated.</param>
    /// <param name="Result">A boolean variable that determines the result of the evaluation if IsHandled is set to true.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, overrides the default logic and uses the value of Result.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskIsSet(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before the logic of the function LookUpAppliesToDocCust has been executed.
    /// This event allows developers to add custom logic before the standard lookup process has been executed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="AccNo">The Customer No. used for filtering during the lookup.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default lookup process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocCust(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before the function LookUpAppliesToDocEmpl has been executed.
    /// This event allows developers to add custom logic or override the default lookup process for an Employee.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="AccNo">The Employee No. used for filtering during the lookup process.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default lookup logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocEmpl(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before the function LookUpAppliesToDocVend has been executed.
    /// This event allows developers to add custom logic or completely override the default lookup process for a Vendor.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="AccNo">The Vendor No. used for filtering during the lookup process.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default lookup logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocVend(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before renumbering document number on the General Journal Lines.
    /// This event allows developers to change the default logic for renumbering document number on General Journal Lines.
    /// </summary>
    /// <param name="DocNo">The current document number being processed.</param>
    /// <param name="GenJnlLine2">The General Journal Line record being processed for renumbering.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default renumbering logic for document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before renumbering the "Applies-to ID" field in the General Journal Line and related ledger entries.
    /// This event allows developers to add custom logic before the renumbering process has begun.
    /// </summary>
    /// <param name="GenJnlLine2">The General Journal Line where "Applies-to ID" has to be replaced.</param>
    /// <param name="OriginalAppliesToID">The "Applies-to ID" to be replaced.</param>
    /// <param name="NewAppliesToID">The new "Applies-to ID" value.</param>
    /// <param name="AccType">The account type of the General Journal Line being processed.</param>
    /// <param name="AccNo">The account number related to the General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberAppliesToID(GenJournalLine: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]);
    begin
    end;

    /// <summary>
    /// Event triggered before the "Apply Customer Entries" page has been opened in lookup mode.
    /// This event allows developers to add custom logic before opening the "Apply Customer Entries" page in lookup mode.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record initiating the lookup process.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record used to filter and display data in the lookup.</param>
    /// <param name="AccNo">The Customer No. used for filtering entries during the lookup.</param>
    /// <param name="Result">A boolean variable indicating the outcome of the lookup operation if the default logic is skipped.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic and uses the value of Result.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunApplyCustEntriesPageLookupOk(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before running the "Apply Vendor Entries" page in lookup mode.
    /// This event allows developers to add custom logic or override the function before the "Apply Vendor Entries" page has been opened in lookup mode.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record initiating the lookup process.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record used for filtering and processing during the lookup.</param>
    /// <param name="AccNo">The Vendor No. used to set filters on the Vendor Ledger Entry.</param>
    /// <param name="Result">A boolean variable indicating the result if the default logic is skipped.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic and uses the value of Result.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunApplyVendEntriesPageLookupOk(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; AccNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the total transfer amount.
    /// This event allows developers to add custom logic or skip the default logic for calculating the total transfer amount.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed for calculating the total transfer amount.</param>
    /// <param name="Result">A decimal variable representing the total transfer amount.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default calculation process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTotalExportedAmount(var GenJournalLine: Record "Gen. Journal Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the amount with a customer ledger entry.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when initializing the process of setting the amount with a customer ledger entry. This can be useful
    /// for implementing custom logic or validations before the amount has been set.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record involved in the operation.
    /// </param>
    /// <param name="CustLedgerEntry">
    /// The customer ledger entry record used for setting the amount.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountWithCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before setting the amount with a vendor ledger entry.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when initializing the process of setting the amount with a vendor ledger entry. This can be useful
    /// for implementing custom logic or validations before the amount has been set.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record involved in the operation.
    /// </param>
    /// <param name="VendorLedgerEntry">
    /// The vendor ledger entry record used for setting the amount.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountWithVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before setting the "Amount to Apply" for a Ledger Entry.
    /// This event allows developers to add custom logic before the process of setting the "Amount to Apply" has begun.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApplyToAmount(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after setting all filters on the Customer Ledger Entry during the lookup process.
    /// This event allows developers to add filtering or validations after the Customer Ledger Entry filters have been applied.
    /// </summary>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record with the applied filters.</param>
    /// <param name="GenJournalLine">The current record for which the lookup is being performed.</param>
    /// <param name="AccNo">The Customer No. used for filtering during the lookup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before updating amounts on the temporary Job Journal Line.
    /// This event allows developers to add custom logic or skip the default process for updating amounts on the temporary Job Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes were applied.</param>
    /// <param name="TempJobJournalLine">The temporary Job Journal Line record being updated.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for updating amounts.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsOnTempJobJnlLine(GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; TempJobJournalLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before updating the "Applies-to Amount" in the General Journal Line.
    /// This event allows developers to add custom logic or skip the default update process for the "Applies-to Amount" field.
    /// </summary>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    /// <param name="xRec">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="CurrFieldNo">The number of the field currently being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for updating the "Applies-to Amount" field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateApplyToAmount(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before updating the "Country/Region Code" and "VAT Registration No." fields.
    /// This event allows developers to add custom logic or override the default process before the fields have been updated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being updated.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the update.</param>
    /// <param name="No">The account number (Customer or Vendor) used to retrieve the "Country/Region Code" and "VAT Registration No".</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCountryCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before the validation of the "Amount (LCY)" field.
    /// This event allows developers to add custom logic or override the default validation process by setting the IsHandled variable to true.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed during the validation.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the current changes were made.</param>
    /// <param name="CurrFieldNo">The number of the field currently being validated.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, indicates the validation process will be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAmountLCY(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Campaign No." field in the General Journal Line.
    /// This event allows developers to add custom logic or skip the default validation process for the "Campaign No." field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "Campaign No." field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCampaignNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating application requirements for a General Journal Line.
    /// This event allows developers to add custom logic or override the default validation process for the application.
    /// </summary>
    /// <param name="TempGenJournalLine">The temporary General Journal Line record being validated.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateApplyRequirements(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Bal. Gen. Bus. Posting Group" field in the General Journal Line.
    /// This event allows developers to add custom logic or modify the condition for checking if the "Bal. Gen. Bus. Posting Group" field is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CheckIfFieldIsEmpty">A boolean variable that, if set to true, requires the "Bal. Gen. Bus. Posting Group" to be blank.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBalGenBusPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Bal. Gen. Posting Type" field in the General Journal Line.
    /// This event allows developers to add custom logic or modify the condition for checking if the "Bal. Gen. Posting Type" field is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CheckIfFieldIsEmpty">A boolean variable that, if set to true, requires the "Bal. Gen. Posting Type" field to be blank.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBalGenPostingType(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Bal. Gen. Prod. Posting Group" field in the General Journal Line.
    /// This event allows developers to add custom logic or modify the condition for checking if the "Bal. Gen. Prod. Posting Group" field is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CheckIfFieldIsEmpty">A boolean variable that, if set to true, requires the "Bal. Gen. Prod. Posting Group" to be blank.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBalGenProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the currency code on the General Journal Line.
    /// This event allows developers to add custom logic or override the default currency code validation logic.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default currency code validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Deferral Code" field in the General Journal Line.
    /// This event allows developers to add custom logic or completely skip the default validation process for the "Deferral Code" field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "Deferral Code" field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDeferralCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the Document Date from the Posting Date on the General Journal Line.
    /// This event allows developers to add custom logic or override the default validation logic for the Document Date based on the Posting Date.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default Document Date validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentDateFromPostingDate(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "VAT Prod. Posting Group" field in the General Journal Line.
    /// This event allows developers to add custom logic or completely skip the default validation logic for the "VAT Prod. Posting Group" field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "VAT Prod. Posting Group" field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Gen. Bus. Posting Group" field in the General Journal Line.
    /// This event allows developers to add custom logic or modify the condition for checking if the "Gen. Bus. Posting Group" field is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CheckIfFieldIsEmpty">A boolean variable that, if set to true, requires the "Gen. Bus. Posting Group" to be blank.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenBusPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Gen. Posting Type" field in the General Journal Line.
    /// This event allows developers to add custom logic or modify the condition for checking if the "Gen. Posting Type" field is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CheckIfFieldIsEmpty">A boolean variable that, if set to true, requires the "Gen. Posting Type" to be blank.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenPostingType(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Gen. Prod. Posting Group" field in the General Journal Line.
    /// This event allows developers to add custom logic or modify the condition for checking if the "Gen. Prod. Posting Group" field is empty.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CheckIfFieldIsEmpty">A boolean variable that, if set to true, requires the "Gen. Prod. Posting Group" to be blank.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating a shortcut dimension code in the General Journal Line.
    /// This event allows developers to change the default logic for shortcut dimension code validation.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension being validated.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code being validated.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before finding the Job Currency Factor during the creation of a temporary Job Journal Line.
    /// This event allows developers to customize the logic for retrieving the Job Currency Factor.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CurrExchRate">The Currency Exchange Rate record used for retrieving exchange rate.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJobJnlLineOnBeforeFindJobCurrencyFactor(var GenJournalLine: Record "Gen. Journal Line"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    /// <summary>
    /// Event triggered before validating fields during the creation of a temporary Job Journal Line.
    /// This event allows developers to add custom logic before field validations have been executed.
    /// </summary>
    /// <param name="TempJobJnlLine">The temporary Job Journal Line record being processed.</param>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before changes.</param>
    /// <param name="CurrFieldNo">The number of the field currently being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJobJnlLimeOnBeforeValidateFields(var TempJobJnlLine: Record "Job Journal Line"; var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after running the payment export process.
    /// This event allows developers to change custom logic after the export has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record that was processed for payment export.</param>
    [IntegrationEvent(false, false)]
    local procedure OnExportPaymentFileOnAfterRunExport(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before running the payment export process.
    /// This event allows developers to execute custom logic or modify parameters before the export codeunit has been run.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed for payment export.</param>
    [IntegrationEvent(false, false)]
    local procedure OnExportPaymentFileOnBeforeRunExport(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before checking document numbers on journal lines during the payment file export process.
    /// This event allows developers to add custom validation logic or skip the default document number checks.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed for payment export.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default document number validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnExportPaymentFileOnBeforeCheckDocNoOnLines(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for finding the first Customer Ledger Entry with the specified "Applies-to ID" and "Customer No."
    /// This event allows developers to add custom logic or modify the applied filters before retrieving the record.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindFirstCustLedgEntryWithAppliesToIDOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for finding the first Vendor Ledger Entry with the specified "Applies-to ID" and "Vendor No.".
    /// This event allows developers to add custom logic or modify the applied filters before retrieving the record.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record with the applied filters. This can be modified by the subscriber.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindFirstVendLedgEntryWithAppliesToIDOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for finding the first Customer Ledger Entry with the specified "Applies-to Doc. No.", "Applies-to Doc. Type" and "Customer No."
    /// This event allows developers to add custom logic or modify the applied filters before retrieving the record.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="AccNo">The customer account number used to filter Customer Ledger Entries.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindFirstCustLedgEntryWithAppliesToDocNoOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for finding the first Vendor Ledger Entry with the specified "Applies-to Doc. No."
    /// This event allows developers to add custom logic or modify the applied filters before retrieving the record.
    /// </summary>
    /// <param name="Rec">The current General Journal Line record being processed.</param>
    /// <param name="AccNo">The vendor account number used to filter Vendor Ledger Entries.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record with the applied filters. This can be modified by the subscriber.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindFirstVendLedgEntryWithAppliesToDocNoOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before G/L Account check and its values transfer to General Journal Line.
    /// This event allows developers to add custom logic or modifications before the G/L Account has been checked in the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="GLAccount">The G/L Account record being validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetFAVATSetupOnBeforeCheckGLAcc(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Event triggered after assigning the "Customer No." from the Customer Ledger Entry to the General Journal Line.
    /// This event allows developers to add custom logic after the "Customer No." has been assigned to the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record used to assign the "Customer No.".</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgerEntryOnAfterAssignCustomerNo(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after assigning the "Vendor No." from the Vendor Ledger Entry to the General Journal Line.
    /// This event allows developers to add custom logic after the "Vendor No." has been assigned to the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record used to assign the "Vendor No.".</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgerEntryOnAfterAssignVendorNo(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Document Type" and "Applies-to Doc. No." fields during the lookup process.
    /// This event allows developers to add custom logic after the "Document Type" and "Applies-to Doc. No." fields have been set.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with updated fields.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record used for updating the fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after a Customer Ledger Entry record has been selected in the "Apply Customer Entries" page.
    /// This event allows developers to add custom logic to the Customer Ledger Entry after it has been selected from the page.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="CustLedgEntry">The selected Customer Ledger Entry record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterApplyCustEntriesGetRecord(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after all filters have been set on the Employee Ledger Entry during the lookup process.
    /// This event allows developers to add additional filters or validations after the Employee Ledger Entry filters have been applied.
    /// </summary>
    /// <param name="EmployeeLedgerEntry">The Employee Ledger Entry record with the applied filters.</param>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocEmplOnAfterSetFilters(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Applies-to Doc. Type" and "Applies-to Doc. No." fields during the lookup process.
    /// This event allows developers to add custom logic or modifications after the "Applies-to Doc. Type" and "Applies-to Doc. No." fields have been set.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with updated fields.</param>
    /// <param name="EmployeeLedgerEntry">The Employee Ledger Entry record used to update the fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocEmplOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after all filters have been set on the Vendor Ledger Entry during the lookup process.
    /// This event allows developers to add additional filters or validations after the Vendor Ledger Entry filters have been applied.
    /// </summary>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record with the applied filters.</param>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="AccNo">The Vendor No. used for filtering during the lookup process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered after updating the "Document Type" and "Applies-to Doc. No." fields during the lookup process.
    /// This event allows developers to add additional logic or modifications after the "Document Type" and "Applies-to Doc. No." fields have been set.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record with updated fields.</param>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record used to update the fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before evaluating the "Check Printed" field during the modification of the General Journal Line.
    /// This event allows developers to add custom logic or skip the default check for the "Check Printed" field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being modified.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the modification.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for checking the "Check Printed" field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeTestCheckPrinted(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the "Customer Ledger Entry" record during the renumbering of "Applies-to ID".
    /// This event allows developers to modify or extend the filters applied to the "Customer Ledger Entry" record.
    /// </summary>
    /// <param name="GenJournalLine">The General Journal Line where "Applies-to ID" is to be replaced.</param>
    /// <param name="AccNo">The account number associated with the General Journal Line.</param>
    /// <param name="CustLedgEntry">The "Customer Ledger Entry" record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRenumberAppliesToIDOnAfterCustLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the "Vendor Ledger Entry" record during the renumbering of "Applies-to ID".
    /// This event allows developers to modify or extend the filters applied to the "Vendor Ledger Entry" record.
    /// </summary>
    /// <param name="GenJournalLine">The General Journal Line where "Applies-to ID" is to be replaced.</param>
    /// <param name="AccNo">The account number associated with the General Journal Line.</param>
    /// <param name="VendLedgEntry">The "Vendor Ledger Entry" record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRenumberAppliesToIDOnAfterVendLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after applying filters to the Customer Ledger Entry during the "Amount to Apply" setting process.
    /// This event allows developers to add or modify filters after they have been applied to the Customer Ledger Entry record.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnAfterCustLedgEntrySetFilters(GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after applying filters to the Vendor Ledger Entry during the "Amount to Apply" setting process.
    /// This event allows developers to add or modify filters after they have been applied to the Vendor Ledger Entry record.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnAfterVendLedgEntrySetFilters(GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before modifying a Customer Ledger Entry record to set the "Amount to Apply".
    /// This event allows developers to add custom logic before the edit process has begun.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record being edited.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnBeforeCustEntryEdit(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before editing a Vendor Ledger Entry record to set the "Amount to Apply".
    /// This event allows developers to add custom logic before the edit process has begun.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record being edited.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnBeforeVendEntryEdit(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before editing an Employee Ledger Entry record to set the "Amount to Apply".
    /// This event allows developers to add custom logic before the edit process has begun.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="EmployeeLedgerEntry">The Employee Ledger Entry record being edited.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnBeforeEmplEntryEdit(var GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before incrementing the "Document No." during the setup of a new General Journal Line.
    /// This event allows developers to customize or skip the logic for generating the next document number.
    /// </summary>
    /// <param name="GenJnlLine">The General Journal Line record being processed.</param>
    /// <param name="LastGenJnlLine">The last General Journal Line used for assigning data to General Journal Line setup process.</param>
    /// <param name="Balance">The General Journal Line balance.</param>
    /// <param name="BottomLine">A boolean variable that indicates whether the current line is the last line in a batch of general journal lines.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for incrementing the document number.</param>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    /// <param name="GenJnlBatch">The General Journal Batch being used for the new line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeIncrDocNo(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var BottomLine: Boolean; var IsHandled: Boolean; var Rec: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch")
    begin
    end;

    /// <summary>
    /// Event triggered before setting the "Document No." for a new General Journal Line.
    /// This event allows developers to customize or skip the logic for setting the document number.
    /// </summary>
    /// <param name="GenJnlLine">The General Journal Line record being processed.</param>
    /// <param name="LastGenJnlLine">The last General Journal Line used for assigning data to General Journal Line setup process.</param>
    /// <param name="Balance">The General Journal Line balance.</param>
    /// <param name="BottomLine">A boolean variable that indicates whether the current line is the last line in a batch of general journal lines.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for setting the document number.</param>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeSetDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var BottomLine: Boolean; var IsHandled: Boolean; var Rec: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before setting the balancing account fields during the setup of a new General Journal Line.
    /// This event allows developers to customize or skip the logic for setting balancing account fields.
    /// </summary>
    /// <param name="GenJnlLine">The General Journal Line record being processed.</param>
    /// <param name="LastGenJnlLine">The last General Journal Line used for assigning data to General Journal Line setup process.</param>
    /// <param name="Balance">The General Journal Line balance.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for setting balancing account fields.</param>
    /// <param name="GenJnlTemplate">The General Journal Template being used for the new line.</param>
    /// <param name="GenJnlBatch">The General Journal Batch being used for the new line.</param>
    /// <param name="BottomLine">A boolean variable that indicates whether the current line is the last line in a batch of General Journal Lines.</param>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    /// <param name="CurrFieldNo">The number of the field currently being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeSetBalAccount(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var IsHandled: Boolean; GenJnlTemplate: Record "Gen. Journal Template"; GenJnlBatch: Record "Gen. Journal Batch"; BottomLine: Boolean; var Rec: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first Customer Ledger Entry using the "Applies-to ID".
    /// This event allows developers to add custom logic after a Customer Ledger Entry has been successfully retrieved by "Applies-to ID".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record that was found based on "Applies-to ID".</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first Customer Ledger Entry using the "Applies-to Doc. No.".
    /// This event allows developers to add custom logic after a Customer Ledger Entry has been successfully retrieved by "Applies-to Doc. No.".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record that was found based on "Applies-to Doc. No.".</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first Vendor Ledger Entry using the "Applies-to ID".
    /// This event allows developers to add custom logic after a Vendor Ledger Entry has been successfully retrieved by "Applies-to ID".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record that was found based on "Applies-to ID".</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first Vendor Ledger Entry using the "Applies-to Doc. No.".
    /// This event allows developers to add custom logic after a Vendor Ledger Entry has been successfully retrieved by "Applies-to Doc. No.".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record that was found based on "Applies-to Doc. No.".</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first Employee Ledger Entry using the "Applies-to ID".
    /// This event allows developers to add custom logic after an Employee Ledger Entry has been successfully retrieved by "Applies-to ID".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Employee Ledger Entry record that was found based on "Applies-to ID".</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Employee Ledger Entry");
    begin
    end;

    /// <summary>
    /// Event triggered after assigning the "Balance (LCY)" field during the update of line balance.
    /// This event allows developers to change default logic of the Line Balance calculation.
    /// </summary>
    /// <param name="BalanceLCY">The calculated "Balance (LCY)" value.</param>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(true, false)]
    local procedure OnUpdateLineBalanceOnAfterAssignBalanceLCY(var BalanceLCY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after the "Amount (LCY)" field has been calculated.
    /// This event allows developers to add custom logic or adjustments after the "Amount (LCY)" field has been updated.
    /// </summary>
    /// <param name="AmountLCY">The calculated local currency amount assigned to the "Amount (LCY)" field.</param>
    [IntegrationEvent(true, false)]
    local procedure OnValidateAmountOnAfterAssignAmountLCY(var AmountLCY: Decimal)
    begin
    end;

    /// <summary>
    /// Event triggered before checking the customer's credit limit during the amount validation.
    /// This event allows developers to change the default logic for checking customer credit limit.
    /// </summary>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    /// <param name="CurrFieldNo">The number of the field currently being processed.</param>
    /// <param name="CustCheckCreditLimit">The codeunit managing customer credit limit check.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default customer credit limit check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountOnBeforeCheckCreditLimit(var GenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after calculation of the "Bal. VAT Amount (LCY)" field during the validation of the "Bal. VAT %" field.
    /// This event allows developers to add custom logic after the "Bal. VAT Amount (LCY)" field has been updated based on the calculated VAT.
    /// </summary>
    /// <param name="BalVATAmountLCY">The updated "Bal. VAT Amount (LCY)" value.</param>
    [IntegrationEvent(true, false)]
    local procedure OnValidateBalVATPctOnAfterAssignBalVATAmountLCY(var BalVATAmountLCY: Decimal)
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the "Due Date" based on the payment terms during the validation of the "Payment Terms Code" field.
    /// This event allows developers to add custom logic or override the default calculation for the "Due Date".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="PaymentTerms">The Payment Terms record retrieved with the "Payment Terms Code".</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default "Due Date" calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculateDueDate(var GenJournalLine: Record "Gen. Journal Line"; PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the "Pmt. Discount Date" based on the payment terms during the validation of the "Payment Terms Code" field.
    /// This event allows developers to add custom logic or override the default calculation for the "Pmt. Discount Date".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="PaymentTerms">The payment terms record associated with the "Payment Terms Code".</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default discount date calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(var GenJournalLine: Record "Gen. Journal Line"; PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Amount" field during the validation of the "Bal. VAT Base Amount" field.
    /// This event allows developers to add custom logic before the "Amount" field has been validated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="Currency">The currency record used for rounding and VAT calculations.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBalVATBaseAmountOnBeforeValidateAmount(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Amount" field during the validation of the "VAT Base Amount" field.
    /// This event allows developers to add custom logic or modify the General Journal Line before the "Amount" field has been validated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="Currency">The currency record used for rounding and VAT calculations.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateVATBaseAmountOnBeforeValidateAmount(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// This event is triggered before updating sales and purchase amounts in LCY during the validation of the VAT or Balance VAT percentage.
    /// Subscribing to this event allows developers to create custom logic for updating sales and purchase amounts in LCY
    /// based on the VAT percentage and related fields.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="Currency">The Currency record that provides data such as rounding precision.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateVATPctOnBeforeUpdateSalesPurchLCY(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Event triggered before performing VAT calculation based on VAT Posting Setup and checks of the "VAT Prod. Posting Group" field.
    /// This event allows developers to modify the VAT calculation and check process.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="VATPostingSetup">The VAT Posting Setup record associated with the "VAT Bus. Posting Group" and "VAT Prod. Posting Group".</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default VAT calculation and checks.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after assigning the "Account Type" related data retrieved during the validation of the "Account No." field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the changes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving data based on the value of the field "Account Type" during the validation of the "Account No." field.
    /// Subscribing to this event allows developers to add custom logic before related "Account Type" data has been retrieved.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the changes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountNoOnBeforeAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before checking the "Keep Description" field during the validation of the field "Account Type".
    /// This event allows developers to implement custom logic before the "Keep Description" field has been validated.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record on which the validation is being performed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the changes.</param>
    /// <param name="CurrFieldNo">The number of the field currently being validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountTypeOnBeforeCheckKeepDescription(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the Customer Ledger Entry when "Applies-to ID" has been specified.
    /// This event allows developers to add or modify filters after they have been applied to the Customer Ledger Entry.
    /// </summary>
    /// <param name="TempGenJnlLine">The temporary General Journal Line record being validated.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithAppliesToID(TempGenJnlLine: Record "Gen. Journal Line" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the Customer Ledger Entry when "Applies-to ID" has not been specified.
    /// This event allows developers to add or modify filters after they have been applied to the Customer Ledger Entry record when "Applies-to Doc. No." has been used.
    /// </summary>
    /// <param name="TempGenJnlLine">The temporary General Journal Line record being validated.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithoutAppliesToID(TempGenJnlLine: Record "Gen. Journal Line" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the Vendor Ledger Entry when "Applies-to ID" has been specified.
    /// This event allows developers to add or modify filters after they have been set to the Vendor Ledger Entry.
    /// </summary>
    /// <param name="TempGenJournalLine">The temporary General Journal Line record being validated.</param>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithAppliesToID(TempGenJournalLine: Record "Gen. Journal Line" temporary; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the Vendor Ledger Entry when "Applies-to Doc. No." has not been specified.
    /// This event allows developers to add or modify filters after they have been applied to the Vendor Ledger Entry record when "Applies-to Doc. No." has been used.
    /// </summary>
    /// <param name="TempGenJournalLine">The temporary General Journal Line record being validated.</param>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithoutAppliesToID(TempGenJournalLine: Record "Gen. Journal Line" temporary; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after assigning values to the record based on the "Bal. Account Type" field value during the "Bal. Account No." field validation.
    /// Subscribing to this event allows developers to add custom logic after the standard validation process has been executed based on the "Bal. Account Type" field value.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the changes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBalAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before assigning values to the record based on the "Bal. Account Type" field value during the "Bal. Account No." field validation.
    /// Subscribing to this event allows developers to add custom logic before the standard validation process has been executed based on the "Bal. Account Type" field value.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the changes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBalAccountNoOnBeforeAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    local procedure SetLastModifiedDateTime()
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
    begin
        "Last Modified DateTime" := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
    end;

    local procedure UpdateDocumentTypeAndAppliesTo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        "Applies-to Doc. Type" := DocType;
        "Applies-to Doc. No." := DocNo;
        "Applies-to ID" := '';

        OnAfterUpdateDocumentTypeAndAppliesToFields(Rec, DocType.AsInteger(), DocNo);

        if "Document Type" <> "Document Type"::" " then
            exit;

        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
            exit;

        case "Applies-to Doc. Type" of
            "Applies-to Doc. Type"::Payment:
                "Document Type" := "Document Type"::Invoice;
            "Applies-to Doc. Type"::"Credit Memo":
                "Document Type" := "Document Type"::Refund;
            "Applies-to Doc. Type"::Invoice,
            "Applies-to Doc. Type"::Refund:
                "Document Type" := "Document Type"::Payment;
        end;
    end;

    /// <summary>
    /// Updates the account ID with the system ID of the related G/L account.
    /// </summary>
    /// <remarks>
    /// If account number is empty, account Id is cleared.
    /// </remarks>
    procedure UpdateAccountID()
    var
        GLAccount: Record "G/L Account";
    begin
        if "Account Type" <> "Account Type"::"G/L Account" then
            exit;

        if "Account No." = '' then begin
            Clear("Account Id");
            exit;
        end;

        if not GLAccount.Get("Account No.") then
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

        "Account No." := GLAccount."No.";
    end;

    local procedure UpdateBalanceAccountId()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        clear("Balance Account Id");
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                begin
                    if not GLAccount.Get("Bal. Account No.") then
                        exit;
                    "Balance Account Id" := GLAccount.SystemId;
                end;
            "Bal. Account Type"::"Bank Account":
                begin
                    if not BankAccount.Get("Bal. Account No.") then
                        exit;
                    "Balance Account Id" := BankAccount.SystemId
                end;
        end;
    end;

    local procedure UpdateBalanceAccountNo()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        if IsNullGuid("Balance Account Id") then
            exit;
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                begin
                    if not GLAccount.GetBySystemId("Balance Account Id") then
                        exit;
                    Validate("Bal. Account No.", GLAccount."No.");
                end;
            "Bal. Account Type"::"Bank Account":
                begin
                    if not BankAccount.GetBySystemId("Balance Account Id") then
                        exit;
                    validate("Bal. Account No.", BankAccount."No.");
                end;
        end;
    end;

    /// <summary>
    /// Updates the account ID with the system ID of the related bank account.
    /// </summary>
    /// <remarks>
    /// If account number is empty, account ID is cleared.
    /// </remarks>
    procedure UpdateBankAccountID()
    var
        BankAccount: Record "Bank Account";
    begin
        if "Account Type" <> "Account Type"::"Bank Account" then
            exit;

        if "Account No." = '' then begin
            Clear("Account Id");
            exit;
        end;

        if not BankAccount.Get("Account No.") then
            exit;

        "Account Id" := BankAccount.SystemId;
    end;

    /// <summary>
    /// Updates the customer ID with the system ID of the related customer.
    /// </summary>
    /// <remarks>
    /// If account number is empty, customer ID is cleared.
    /// </remarks>
    procedure UpdateCustomerID()
    var
        Customer: Record Customer;
    begin
        if "Account Type" <> "Account Type"::Customer then
            exit;

        if "Account No." = '' then begin
            Clear("Customer Id");
            exit;
        end;

        if not Customer.Get("Account No.") then
            exit;

        "Customer Id" := Customer.SystemId;
    end;

    /// <summary>
    /// Updates the vendor ID with the system ID of the related vendor.
    /// </summary>
    /// <remarks>
    /// If account number is empty, vendor ID is cleared.
    /// </remarks>
    procedure UpdateVendorID()
    var
        Vendor: Record Vendor;
    begin
        if "Account Type" <> "Account Type"::Vendor then
            exit;

        if "Account No." = '' then begin
            Clear("Vendor Id");
            exit;
        end;

        if not Vendor.Get("Account No.") then
            exit;

        "Vendor Id" := Vendor.SystemId;
    end;

    local procedure UpdateCustomerNo()
    var
        Customer: Record Customer;
    begin
        if IsNullGuid("Customer Id") then
            exit;

        if not Customer.GetBySystemId("Customer Id") then
            exit;

        "Account No." := Customer."No.";
    end;

    local procedure UpdateVendorNo()
    var
        Vendor: Record Vendor;
    begin
        if IsNullGuid("Vendor Id") then
            exit;

        if not Vendor.GetBySystemId("Vendor Id") then
            exit;

        "Account No." := Vendor."No.";
    end;

    /// <summary>
    /// Updates the applies-to invoice ID with the system ID of the related sales or purchase invoice header.
    /// </summary>
    /// <remarks>
    /// If applies-to document number is empty, applies-to invoice ID is cleared.
    /// </remarks>
    procedure UpdateAppliesToInvoiceID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        AppliestoInvoiceId: Guid;
    begin
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::Invoice then
            exit;

        if "Applies-to Doc. No." = '' then begin
            Clear("Applies-to Invoice Id");
            exit;
        end;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if not SalesInvoiceHeader.Get("Applies-to Doc. No.") then
                        exit;

                    AppliestoInvoiceId := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
                    if Rec."Applies-to Invoice Id" <> AppliestoInvoiceId then
                        Rec."Applies-to Invoice Id" := AppliestoInvoiceId;
                end;
            "Account Type"::Vendor:
                begin
                    if not PurchInvHeader.Get("Applies-to Doc. No.") then
                        exit;

                    AppliestoInvoiceId := PurchInvAggregator.GetPurchaseInvoiceHeaderId(PurchInvHeader);
                    if Rec."Applies-to Invoice Id" <> AppliestoInvoiceId then
                        Rec."Applies-to Invoice Id" := AppliestoInvoiceId;
                end;
        end;
    end;

    local procedure UpdateAppliesToInvoiceNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvheader: Record "Purch. Inv. Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        if IsNullGuid("Applies-to Invoice Id") then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if not SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(Format("Applies-to Invoice Id"), SalesInvoiceHeader) then
                        Error(InvoiceForGivenIDDoesNotExistErr);

                    "Applies-to Doc. No." := SalesInvoiceHeader."No.";
                end;
            "Account Type"::Vendor:
                begin
                    if not PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(Format("Applies-to Invoice Id"), PurchInvheader) then
                        Error(InvoiceForGivenIDDoesNotExistErr);

                    "Applies-to Doc. No." := PurchInvheader."No.";
                end;
        end;
    end;

    local procedure CheckPostingGroupChange()
    var
        Customer: Record Customer;
        Employee: Record Employee;
        Vendor: Record Vendor;
        HumanResourcesSetup: Record "Human Resources Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PostingGroupChangeInterface: Interface "Posting Group Change Method";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingGroupChange(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        if ("Posting Group" <> xRec."Posting Group") and (xRec."Posting Group" <> '') then begin
            TestField("Account No.");
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        SalesReceivablesSetup.Get();
                        if SalesReceivablesSetup."Allow Multiple Posting Groups" then begin
                            Customer.Get("Account No.");
                            Customer.TestField("Allow Multiple Posting Groups");
                            PostingGroupChangeInterface := SalesReceivablesSetup."Check Multiple Posting Groups";
                            PostingGroupChangeInterface.ChangePostingGroup("Posting Group", xRec."Posting Group", Rec);
                        end;
                    end;
                "Account Type"::Vendor:
                    begin
                        PurchasesPayablesSetup.Get();
                        if PurchasesPayablesSetup."Allow Multiple Posting Groups" then begin
                            Vendor.Get("Account No.");
                            Vendor.TestField("Allow Multiple Posting Groups");
                            PostingGroupChangeInterface := PurchasesPayablesSetup."Check Multiple Posting Groups";
                            PostingGroupChangeInterface.ChangePostingGroup("Posting Group", xRec."Posting Group", Rec);
                        end;
                    end;
                "Account Type"::Employee:
                    begin
                        HumanResourcesSetup.Get();
                        if HumanResourcesSetup."Allow Multiple Posting Groups" then begin
                            Employee.Get("Account No.");
                            Employee.TestField("Allow Multiple Posting Groups");
                            PostingGroupChangeInterface := HumanResourcesSetup."Check Multiple Posting Groups";
                            PostingGroupChangeInterface.ChangePostingGroup("Posting Group", xRec."Posting Group", Rec);
                        end;
                    end;
                else
                    error(CannotChangePostingGroupForAccountTypeErr, "Account Type");
            end;
        end;
    end;

    /// <summary>
    /// Updates the journal batch ID with the system ID of the related general journal batch.
    /// </summary>
    /// <remarks>
    /// If the journal template name and journal batch name do not match those of the general journal batch record,
    /// the procedure is not executed.
    /// </remarks>
    procedure UpdateJournalBatchID()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit;

        "Journal Batch Id" := GenJournalBatch.SystemId;
    end;

    local procedure UpdateJournalBatchName()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.GetBySystemId("Journal Batch Id") then
            exit;

        "Journal Batch Name" := GenJournalBatch.Name;
    end;

    /// <summary>
    /// Updates the payment method ID with the system ID of the related payment method.
    /// </summary>
    procedure UpdatePaymentMethodId()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if "Payment Method Code" = '' then begin
            Clear("Payment Method Id");
            exit;
        end;

        if not PaymentMethod.Get("Payment Method Code") then
            exit;

        "Payment Method Id" := PaymentMethod.SystemId;
    end;

    local procedure UpdatePaymentMethodCode()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if IsNullGuid("Payment Method Id") then
            exit;

        if not PaymentMethod.GetBySystemId("Payment Method Id") then
            exit;

        "Payment Method Code" := PaymentMethod.Code;
    end;

    local procedure UpdateDescriptionWithEmployeeName(Employee: Record Employee)
    begin
        if StrLen(Employee.FullName()) <= MaxStrLen(Description) then
            UpdateDescription(CopyStr(Employee.FullName(), 1, MaxStrLen(Description)))
        else
            UpdateDescription(Employee.Initials);
    end;

    /// <summary>
    /// Event triggered after retrieving a vendor record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing vendor account data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to vendor accounts.
    /// </summary>
    /// <param name="Vendor">
    /// The vendor record that has been retrieved and processed.
    /// </param>
    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnGenJnlLineGetVendorAccount(Vendor: Record Vendor)
    begin
    end;

    /// <summary>
    /// Opens a page with deferral schedule for the general journal line.
    /// </summary>
    /// <remarks>
    /// Deferral schedule cannot be specified for a fixed asset account type.
    /// If the deferral schedule does not exist yet, a new one is created and committed before the page has been opened.
    /// </remarks>
    procedure ShowDeferralSchedule()
    begin
        if "Account Type" = "Account Type"::"Fixed Asset" then
            Error(AccTypeNotSupportedErr);

        ShowDeferrals("Posting Date", "Currency Code");
    end;

    /// <summary>
    /// Opens the general journal dimension filters page for the current general journal line.
    /// </summary>
    /// <remarks>
    /// Used to filter and analyze data based on specific properties or dimensions.
    /// </remarks>
    procedure ShowRecurringDimFilter()
    var
        GenJnlDimFilters: Page "Gen. Jnl. Dim. Filters";
    begin
        GenJnlDimFilters.SetGenJnlLine(Rec);
        GenJnlDimFilters.RunModal();
    end;

    local procedure DimFilterExists(): Boolean
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", "Line No.");
        exit(not GenJnlDimFilter.IsEmpty);
    end;

    local procedure LineDimExists(): Boolean
    begin
        exit("Dimension Set ID" <> 0);
    end;

    /// <summary>
    /// Checks if the shortcut dimension code is valid for the recurring method on a general journal line.
    /// </summary>
    /// <param name="ShortcutDimCode">Shortcut dimension code to check.</param>
    procedure CheckShortcutDimCodeRecurringMethod(ShortcutDimCode: Code[20])
    begin
        if ShortcutDimCode <> '' then
            if "Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"] then
                FieldError("Recurring Method");
    end;

    local procedure ShowSetDimFiltersNotification()
    begin
        if "Line No." <> 0 then
            if "Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"] then
                SendSetDimFiltersNotification()
            else
                RecallSetDimFiltersNotification();
    end;

    local procedure SendSetDimFiltersNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        GenJnlDimFilterMgt: Codeunit "Gen. Jnl. Dim. Filter Mgt.";
        SetDimFiltersNotification: Notification;
    begin
        RecallSetDimFiltersNotification();

        if not GenJnlDimFilterMgt.IsNotificationEnabled() or DimFilterExists() then
            exit;

        SetDimFiltersNotification.Id(CreateGuid());
        SetDimFiltersNotification.Message(SetDimFiltersMessageTxt);
        SetDimFiltersNotification.Scope(NotificationScope::LocalScope);
        SetDimFiltersNotification.AddAction(SetDimFiltersActionTxt, Codeunit::"Gen. Jnl. Dim. Filter Mgt.", 'SetGenJnlDimFilters');
        SetDimFiltersNotification.AddAction(DontShowAgainActionTxt, Codeunit::"Gen. Jnl. Dim. Filter Mgt.", 'HideNotification');
        SetDimFiltersNotification.SetData('JournalTemplateName', "Journal Template Name");
        SetDimFiltersNotification.SetData('JournalBatchName', "Journal Batch Name");
        SetDimFiltersNotification.SetData('JournalLineNo', Format("Line No."));
        NotificationLifecycleMgt.SendNotification(SetDimFiltersNotification, RecordId);
    end;

    /// <summary>
    /// Sends a general journal line to a specified posting codeunit for processing.
    /// </summary>
    /// <param name="PostingCodeunitID">Posting codeunit ID to use.</param>
    procedure SendToPosting(PostingCodeunitID: Integer)
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        BatchProcessingMgt.BatchProcessGenJournalLine(Rec, PostingCodeunitID);
    end;

    local procedure RecallSetDimFiltersNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(RecordId, "Line No." = 0);
    end;

    local procedure DeleteGenJnlDimFilters()
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", "Line No.");
        if not GenJnlDimFilter.IsEmpty() then
            GenJnlDimFilter.DeleteAll();
    end;

    local procedure CheckRecurringDimensionsAndFilters()
    begin
        if not ("Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"]) then begin
            if "Line No." <> 0 then
                if DimFilterExists() then
                    Error(RecurringMethodsDimFilterErr, "Recurring Method");
        end else
            if LineDimExists() then
                Error(RecurringMethodsLineDimdErr, "Recurring Method");
    end;

    local procedure CalcVATAmountLCY(): Decimal
    var
        LCYCurrency: Record Currency;
        VATAmountLCY: Decimal;
    begin
        if "Currency Code" = '' then
            exit("VAT Amount");

        OnCalcVATAmountLCYOnBeforeInitRoundingPrecision(Rec, LCYCurrency);
        LCYCurrency.InitRoundingPrecision();

        "VAT Difference" :=
            "VAT Amount" -
            Round(
                Amount * "VAT %" / (100 + "VAT %"),
                LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());

        if "VAT Difference" = 0 then
            VATAmountLCY := Round("Amount (LCY)" * "VAT %" / (100 + "VAT %"), LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection())
        else
            VATAmountLCY :=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", "VAT Amount", "Currency Factor"),
                    LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());

        exit(VATAmountLCY);
    end;

    /// <summary>
    /// Initializes the dimensions for the general journal line.
    /// </summary>
    /// <param name="FromFieldNo">The field number for which to initialize the dimensions.</param>
    procedure CreateDimFromDefaultDim(FromFieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FromFieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Account Type".AsInteger()), Rec."Account No.", FromFieldNo = Rec.Fieldno("Account No."));
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Bal. Account Type".AsInteger()), Rec."Bal. Account No.", FromFieldNo = Rec.Fieldno("Bal. Account No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FromFieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FromFieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Campaign, Rec."Campaign No.", FromFieldNo = Rec.FieldNo("Campaign No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FromFieldNo);
    end;

    /// <summary>
    /// Determines whether the fixed asset posting type of the current general journal line is set to the acquisition cost.
    /// </summary>
    /// <returns>True if fixed asset posting type is set to the acquisition cost, otherwise false.</returns>
    procedure IsAcquisitionCost(): Boolean
    var
        AcquisitionCost: Boolean;
    begin
        AcquisitionCost := "FA Posting Type" = "FA Posting Type"::"Acquisition Cost";
        OnAfterIsAcquisitionCost(Rec, AcquisitionCost);
        exit(AcquisitionCost);
    end;

    local procedure CalculateVATAmount(var VATAmount: Decimal; var VATAmountLCY: Decimal)
    var
        GenJnlLine1: Record "Gen. Journal Line";
        tempVATAmount: Decimal;
    begin
        if "Document No." = '' then
            exit;
        if ("Recurring Method" <> "Recurring Method"::" ") then begin
            CalculateVATAmountonGenJnlAllocation(Rec, VATAmount);
            tempVATAmount := "VAT Amount";
            "VAT Amount" := VATAmount;
            VATAmountLCY := CalcVATAmountLCY();
            "VAT Amount" := tempVATAmount;
        end;

        GenJnlLine1.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine1.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine1.SetRange("Document No.", "Document No.");
        GenJnlLine1.CalcSums("VAT Amount", "VAT Amount (LCY)");
        VATAmount := VATAmount + GenJnlLine1."VAT Amount";
        VATAmountLCY := VATAmountLCY + GenJnlLine1."VAT Amount (LCY)";

        if Amount < 0 then
            VATAmount := Abs(VATAmount)
        else
            VATAmount := -1 * Abs(VATAmount);

        if "Amount (LCY)" < 0 then
            VATAmountLCY := Abs(VATAmountLCY)
        else
            VATAmountLCY := -1 * Abs(VATAmountLCY);
    end;

    local procedure CalculateVATAmountonGenJnlAllocation(GenJnlLine1: Record "Gen. Journal Line"; var VATAmount: Decimal)
    var
        GenJnlAlloc1: Record "Gen. Jnl. Allocation";
    begin
        GenJnlAlloc1.SetRange("Journal Template Name", GenJnlLine1."Journal Template Name");
        GenJnlAlloc1.SetRange("Journal Batch Name", GenJnlLine1."Journal Batch Name");
        GenJnlAlloc1.SetRange("Journal Line No.", GenJnlLine1."Line No.");
        GenJnlAlloc1.CalcSums("VAT Amount");
        VATAmount := GenJnlAlloc1."VAT Amount";
    end;

    local procedure DeleteRelatedPaymentFileErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.DeleteJnlLineErrorsWhenRecDeleted(Rec);
    end;

    local procedure ShouldClearCustVendApplnEntry(): Boolean
    begin
        if xRec."Applies-to ID" = '' then
            exit(false);
        exit(HasNoMultipleLine());
    end;

    /// <summary>
    /// Event triggered after initializing default dimension sources for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when setting up default dimension sources. This can be useful for implementing additional logic,
    /// custom dimension sources, or handling specific business rules related to dimensions.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which default dimension sources are being initialized.
    /// </param>
    /// <param name="DefaultDimSource">
    /// A list of dictionaries containing the default dimension sources that have been initialized.
    /// </param>
    /// <param name="FromFieldNo">
    /// The field number that triggered the initialization of default dimension sources.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var GenJournalLine: Record "Gen. Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after performing the update of the current journal line.
    /// This event allows developers to change custom logic after the journal line has been cleaned.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record after the cleaning operations have been applied.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the cleaning operations were applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCleanLine(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after clearing customer/vendor/employee application entries in the General Journal Line.
    /// This event allows developers to change the default logic after the standard clearing process for customer/vendor/employee application entries has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="AccType">The account type of the General Journal Line.</param>
    /// <param name="AccNo">The account number of the General Journal Line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from an issued finance charge memo header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from issued finance charge memo headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="IssuedFinChargeMemoHeader">
    /// The issued finance charge memo header record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the issued finance charge memo header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from an issued reminder header to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from issued reminder headers. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="IssuedReminderHeader">
    /// The issued reminder header record from which data is being copied.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the issued reminder header has been copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromIssuedReminderHeader(IssuedReminderHeader: Record "Issued Reminder Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after filters have been set on the Customer Ledger Entry.
    /// This event allows developers to add or modify filters after they have been applied to the Customer Ledger Entry.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record with the applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgerEntryOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after renumbering the "Applies-to ID" field in the General Journal Line and related ledger entries.
    /// This event allows developers to add custom logic after the renumbering process has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The General Journal Line processed for renumbering.</param>
    /// <param name="OriginalAppliesToID">The "Applies to ID" to be replaced.</param>
    /// <param name="NewAppliesToID">The new "Applies-to ID" value.</param>
    /// <param name="AccountType">The account type of the processed General Journal Line.</param>
    /// <param name="AccountNo">The account number related to the processed General Journal Line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberAppliesToID(GenJournalLine: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]);
    begin
    end;

    /// <summary>
    /// Event triggered after evaluating whether the description should be replaced in the journal line.
    /// This event allows developers to add the custom logic after the default description check has been completed.
    /// </summary>
    /// <param name="GenJnlBatch">The General Journal Batch associated with the operation.</param>
    /// <param name="Result">A boolean variable indicating whether the description should be replaced.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReplaceDescription(GenJnlBatch: Record "Gen. Journal Batch"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after the renumbering of "Document No." on General Journal Lines has been completed.
    /// This event allows developers to add custom logic after the renumbering process has been finished.
    /// </summary>
    /// <param name="DocNo">The final document number assigned during the renumbering process.</param>
    /// <param name="GenJnlLine2">The last General Journal Line processed during renumbering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters for the Employee Ledger Entry during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to adjust or add additional filters to the Employee Ledger Entry record after the default filters have been set.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="EmplLedgEntry">The Employee Ledger Entry record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoValidateOnAfterEmplLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; var EmplLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the deferral amount.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when determining the deferral amount. This can be useful for implementing custom logic or validations
    /// before the deferral amount has been calculated.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the deferral amount is being calculated.
    /// </param>
    /// <param name="DeferralAmount">
    /// The calculated deferral amount that can be modified by the subscriber.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for calculating the deferral amount should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralAmount(var GenJournalLine: Record "Gen. Journal Line"; var DeferralAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving the Customer Ledger Entry based on the related applied document.
    /// This event allows developers to add custom logic or skip the default logic for retrieving Customer Ledger Entries.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="CustLedgEntry">The Customer Ledger Entry record to be retrieved and processed.</param>
    /// <param name="AccNo">The customer account number used to filter Customer Ledger Entries.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for retrieving Customer Ledger Entries.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAppliesToDocCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before determining if the General Journal Line has been applied.
    /// This event allows developers to implement custom logic or override the default behavior for determining if the line has been applied.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being evaluated.</param>
    /// <param name="Result">A boolean variable that indicates whether the line is applied. This value is used if IsHandled is set to true.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining if the line is applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsApplied(var GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered before executing the deletion logic for the General Journal Line.
    /// This event allows developers to add custom logic or skip the default deletion process for the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default deletion logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered before updating the "Source Type" and "Source No." fields in the General Journal Line.
    /// This event allows developers to change the default logic for updating the "Source Type" and "Source No." fields.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for updating the "Source Type" and "Source No." fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSource(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered before displaying the deferral schedule.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when showing deferrals. This can be useful for implementing custom logic, validations, or
    /// alternate workflows before the deferral schedule has been displayed.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record associated with the deferral operation.
    /// </param>
    /// <param name="ReturnValue">
    /// The boolean return value that can be modified by the subscriber to influence the behavior of the deferral operation.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for showing the deferrals should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(GenJournalLine: Record "Gen. Journal Line"; var ReturnValue: Boolean; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered after modifying the "Source Type" and "Source No." fields in the General Journal Line.
    /// This event allows developers to add custom logic after the "Source Type" and "Source No." fields have been modified.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line that was modified.</param>
    /// <param name="CurrFieldNo">The number of the field currently being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSource(var GenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after copying data from an issued reminder line to the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when transferring data from issued reminder lines. This can be useful for implementing
    /// additional logic, validations, or custom handling of the copied data.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record to which data from the issued reminder line has been copied.
    /// </param>
    /// <param name="IssuedReminderLine">
    /// The issued reminder line record from which data is being copied.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromIssuedReminderLine(var GenJournalLine: Record "Gen. Journal Line"; IssuedReminderLine: Record "Issued Reminder Line")
    begin
    end;

    /// <summary>
    /// Event triggered after creating dimensions for the General Journal Line.
    /// This event allows developers to add custom logic after dimensions have been created.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CurrFieldNo">The number of the field currently being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="OldDimSetID">The original Dimension Set ID before the changes.</param>
    /// <param name="DefaultDimSource">The list of default dimensions used to generate the new Dimension Set ID.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var GenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer; xGenJournalLine: Record "Gen. Journal Line"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    /// <summary>
    /// Event triggered after the dimensions have been edited in the General Journal Line.
    /// This event allows developers to perform additional actions after the dimension editing process has been completed, including checking if changes occurred.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line with the updated dimension set.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the changes.</param>
    /// <param name="OldDimSetID">The Dimension Set ID before the changes were made.</param>
    /// <param name="IsChanged">A boolean variable indicating whether the Dimension Set ID has been changed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; OldDimSetID: Integer; var IsChanged: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before showing and editing dimensions in the General Journal Line.
    /// This event allows developers to change the custom logic of this function.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default dimension editing logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before the lookup on a shortcut dimension code in the General Journal Line.
    /// This event allows developers to add custom logic or skip the default lookup process for the shortcut dimension code.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension being looked up.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code being looked up.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default lookup logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before performing the lookup for the "Applies-to Doc. No." field.
    /// This event allows developers to add custom logic or override the default lookup behavior by setting the IsHandled variable to true.
    /// </summary>
    /// <param name="GenJournalLine">The current  General Journal Line record on which the lookup is being performed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default lookup logic, and exits the lookup trigger.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the balancing account number when a job number has been specified.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when performing validation on the balancing account number. This can be useful for implementing custom validations
    /// or handling specific business rules related to balancing accounts and job numbers.
    /// </summary>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default validation behavior should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    /// <param name="GenJournalLine">
    /// The general journal line record being validated.
    /// </param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalAccountNoOnJobNoValidation(var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before determining whether to skip renumbering the "Document No." in the General Journal Line.
    /// This event allows developers to add custom logic or override the default renumbering process.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="Result">A boolean variable indicating whether the renumbering should be skipped.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic and uses the value of Result to determine if renumbering is skipped.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeSkipRenumberDocumentNo(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Job Task No." field in the General Journal Line.
    /// This event allows developers to add custom logic or skip the default validation for the "Job Task No." field.
    /// </summary>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "Job Task No." field.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateJobTaskNo(xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered when none of the predefined account types (Customer, Vendor, Employee) have been matched during the privacy block check.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when encountering unsupported or custom account types in the privacy block validation process. This can be useful for implementing additional logic
    /// or handling specific scenarios related to custom account types.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record being processed in the privacy block validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckIfPrivacyBlockedCaseElse(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before setting the "Applies-to ID" field for Customer Ledger Entries during clearing of customer application entries.
    /// This event allows developers to change the default behavior before the "Applies-to ID" has been set in Customer Ledger Entries.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record associated with the "Applies-to ID".</param>
    [IntegrationEvent(false, false)]
    local procedure OnClearCustVendApplnEntryOnBeforeCustEntrySetApplIDSetApplId(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a customer record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing customer account data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to customer accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the customer account is being processed.
    /// </param>
    /// <param name="Customer">
    /// The customer record that has been retrieved and processed.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the customer account.
    /// </param>
    [IntegrationEvent(true, false)]
    local procedure OnGetCustomerAccountOnAfterCustGet(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving a customer record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing customer account data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing customer accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing customer account is being processed.
    /// </param>
    /// <param name="Customer">
    /// The customer record that has been retrieved and processed as the balancing account.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the balancing customer account.
    /// </param>
    [IntegrationEvent(true, false)]
    local procedure OnGetCustomerBalAccountOnAfterCustGet(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered if the "FA Posting Type" does not match any predefined "FA Posting Type" values.
    /// This event allows developers to add custom logic for handling additional "FA Posting Type" cases.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="DepreciationBook">The Depreciation Book record related to the General Journal Line.</param>
    /// <param name="UseFAAddCurrExchRate">A boolean variable indicating whether the "FA Add.-Currency Factor" should be used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetFAAddCurrExchRateOnCaseElse(GenJournalLine: Record "Gen. Journal Line"; DepreciationBook: Record "Depreciation Book"; var UseFAAddCurrExchRate: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before resetting the "Bal. Account No." and "IC Account No." fields during the validation of the "Bal. Account Type" field.
    /// This event allows developers to add custom logic or modify the current record before the "Bal. Account No." and "IC Account No." fields have been reset.
    /// </summary>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    /// <param name="xRec">The previous state of the General Journal Line before the current changes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBalAccountTypeOnBeforeSetBalAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnAfterValidateCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after setting the description for a balancing G/L account.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when updating the description for a balancing G/L account. This can be useful for implementing additional logic
    /// or applying specific business rules.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing G/L account description has been set.
    /// </param>
    /// <param name="GLAcc">
    /// The balancing G/L account record used to derive the description.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnGetGLBalAccountOnAfterSetDescription(var GenJournalLine: Record "Gen. Journal Line"; GLAcc: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Event triggered before creating dimensions for the General Journal Line.
    /// This event allows developers to add custom logic or skip the dimension creation by setting the IsHandled variable to true.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default dimension creation logic.</param>
    /// <param name="CurrentFieldNo">The number of the field currently being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered before confirming whether the "Bill-to Customer" differs from the "Account No." in the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when checking for a mismatch between the "Bill-to Customer" and the "Account No.". This can be useful for
    /// implementing custom confirmation logic, validations, or additional checks.
    /// </summary>
    /// <param name="GenJorunalLine">
    /// The general journal line record involved in the validation process.
    /// </param>
    /// <param name="Customer">
    /// The customer record associated with the validation process.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the validation.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default confirmation behavior should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckConfirmDifferentCustomerAndBillToCustomer(var GenJorunalLine: Record "Gen. Journal Line"; Customer: Record Customer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before confirming whether the "Pay-to Vendor" differs from the "Account No." in the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when checking for a mismatch between the "Pay-to Vendor" and the "Account No.". This can be useful for
    /// implementing custom confirmation logic, validations, or additional checks.
    /// </summary>
    /// <param name="GenJorunalLine">
    /// The general journal line record involved in the validation process.
    /// </param>
    /// <param name="Vendor">
    /// The vendor record associated with the validation process.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the validation.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default confirmation behavior should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckConfirmDifferentVendorAndPayToVendor(var GenJorunalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before checking if the "VAT Prod. Posting Group" field is empty in the General Journal Line.
    /// This event allows developers to change the default logic for validating the "VAT Prod. Posting Group" field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="CallingFieldNo">The field number currently being validated or processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "VAT Prod. Posting Group" field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmptyVATProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the currency code for a bank account customer line in the general journal.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when determining the currency code for a bank account customer line. This can be useful for implementing custom logic,
    /// validations, or additional business rules related to currency code assignment.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the currency code is being determined.
    /// </param>
    /// <param name="Customer">
    /// The customer record associated with the bank account line.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the currency code assignment.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for setting the currency code should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSetCurrencyCodeForBankCustLine(var GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the currency code for a bank account vendor line in the general journal.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when determining the currency code for a bank account vendor line. This can be useful for implementing custom logic,
    /// validations, or additional business rules related to currency code assignment.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the currency code is being determined.
    /// </param>
    /// <param name="Vendor">
    /// The vendor record associated with the bank account line.
    /// </param>
    /// <param name="CallingFieldNo">
    /// The current field number being processed in the context of the currency code assignment.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for setting the currency code should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSetCurrencyCodeForBankVendLine(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before clearing job-related amounts in the General Journal Line.
    /// This event allows developers to change the default behavior of clearing job-related amounts.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for clearing job-related amounts.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearJobRelatedAmounts(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the "Currency Code" field in the General Journal Line.
    /// This event allows developers to change the logic for setting the "Currency Code" based on the account type and account number.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="AccType2">The account type for which the "Currency Code" is being set.</param>
    /// <param name="AccNo2">The account number for which the "Currency Code" is being set.</param>
    /// <param name="Result">A boolean variable that defines if the Currency Code is set.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for setting the "Currency Code".</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; AccType2: Enum "Gen. Journal Account Type"; AccNo2: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after a Vendor Ledger Entry record has been selected in the "Apply Vendor Entries" page.
    /// This event allows developers to modify or add logic to the Vendor Ledger Entry after it has been selected from the page.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="GenJnlLine">The General Journal Line record associated with the lookup process.</param>
    /// <param name="GenJnlApply">The "Gen. Jnl.-Apply" codeunit.</param>
    /// <param name="PaymentToleranceMgt">The "Payment Tolerance Management" codeunit.</param>
    /// <param name="VendLedgEntry">The selected Vendor Ledger Entry record.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, overrides the default processing logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterApplyVendEntriesGetRecord(var GenJournalLine: Record "Gen. Journal Line"; GenJnlLine: Record "Gen. Journal Line"; GenJnlApply: Codeunit "Gen. Jnl.-Apply"; PaymentToleranceMgt: Codeunit "Payment Tolerance Management"; VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after the entire lookup process for document application for a vendor has been completed.
    /// This event allows developers to perform final processing after the lookup process has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record after the lookup process has been executed.</param>
    /// <param name="VendLedgEntry">The Vendor Ledger Entry record used in the lookup.</param>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record, if applicable, used during the lookup process.</param>
    /// <param name="ApplyVendorEntries">The "Apply Vendor Entries" page used during the lookup process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpAppliesToDocVend(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; ApplyVendorEntries: Page "Apply Vendor Entries")
    begin
    end;

    /// <summary>
    /// Event triggered before calculating the "Balance (LCY)" sum of a document related to the General Journal Line.
    /// This event allows developers to add custom logic or modify filters on the General Journal Line record before the balance calculation has been completed.
    /// </summary>
    /// <param name="GenJournalLine">The General Journal Line record used for calculating the document balance, with filters applied.</param>
    /// <param name="GenJnlTemplate">The General Journal Template record associated with the General Journal Line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentBalanceOnBeforeCalcBalance(var GenJournalLine: Record "Gen. Journal Line"; GenJnlTemplate: Record "Gen. Journal Template")
    begin
    end;

    /// <summary>
    /// Event triggered before performing VAT calculation based on VAT Posting Setup and checks during the validation of "Bal. VAT Prod. Posting Group" field.
    /// This event allows developers to modify the VAT calculation and check process for balancing account.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="VATPostingSetup">The VAT Posting Setup record associated with the "Bal. VAT Bus. Posting Group" and "Bal. VAT Prod. Posting Group".</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default VAT calculation checks and calculations for the balancing account.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBalVATProdPostingGroupOnBeforeBalVATCalculationCheck(var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after determining whether the "FA Posting Type" has been set to "Acquisition Cost" in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// after checking the acquisition cost status. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to fixed asset posting types.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record being evaluated for acquisition cost.
    /// </param>
    /// <param name="AcquisitionCost">
    /// A boolean value indicating whether the "FA Posting Type" is "Acquisition Cost".
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAcquisitionCost(var GenJournalLine: Record "Gen. Journal Line"; var AcquisitionCost: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered after the lookup on a shortcut dimension code in the General Journal Line.
    /// This event allows developers to add custom logic after the shortcut dimension code lookup has been done.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before the current changes.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension looked up.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code that was looked up.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered before updating the currency factor during currency code validation.
    /// This event allows the implementation of custom logic before the currency factor has been recalculated based on the current exchange rate.
    /// </summary>
    /// <param name="GenJournalLine">The current record for which the currency factor is being updated.</param>
    /// <param name="CurrExchRate">The current exchange rate object used to calculate the currency factor.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyCodeOnBeforeUpdateCurrencyFactor(var GenJournalLine: Record "Gen. Journal Line"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    /// <summary>
    /// Event triggered before clearing application entries during the deletion of the General Journal Line.
    /// This event allows developers to change the default logic before application/allocation entries have been cleared.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed for deletion.</param>
    /// <param name="GenJournalBatch">The General Journal Batch associated with the current line.</param>
    /// <param name="GenJnlAlloc">The General Journal Allocation associated with the current line.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for clearing application/allocation entries.</param>
    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GenJnlAlloc: Record "Gen. Jnl. Allocation"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after the journal line fields have been set based on the application logic.
    /// This event allows developers to add custom logic after the journal line fields have been updated from the application.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed, with the updated journal line fields applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliestoDocNoOnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after deleting payment tolerance in the Applied Ledger Entries for the previous "Applies-to Doc. No." value during validation.
    /// This event allows developers to add custom logic after Applied Ledger Entries payment tolerance fields have been reset for the
    /// xGenJournalLine."Applies-to Doc. No." value.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before made changes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesToDocNoOnAfterDelPmtToApplnDocNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before checking if a job task is set during the validation of the "Job Task No." field.
    /// This event allows developers to add custom logic before determining if a job task has been set.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateJobTaskNoOnBeforeJobTaskIsSet(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before clearing data exchange entries related to the General Journal Line.
    /// This event allows developers to implement custom logic or override the default logic for deleting data exchange entries.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for deleting data exchange entries.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearDataExchangeEntries(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;


    /// <summary>
    /// Event triggered before default validation for the "Job No." field has been executed.
    /// This event allows developers to add custom logic or override the default validation for the "Job No." field.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being validated.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line record before the current changes were made.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateJobNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before checking for changes to the posting group in the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when validating posting group changes. This can be useful for implementing custom logic,
    /// validations, or handling specific business rules related to posting group modifications.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record currently being processed.
    /// </param>
    /// <param name="xGenJournalLine">
    /// The previous version of the general journal line record, used for comparison.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for checking posting group changes should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingGroupChange(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before suggesting a balancing amount during the setup of a new General Journal Line.
    /// This event allows developers to change the default logic before the system suggests a balancing amount for the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="GenJnlBatch">The General Journal Batch associated with the current line.</param>
    /// <param name="CurrFieldNo">The field number currently being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetupNewLineOnBeforeSuggestBalancingAmount(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; CurrentFieldNo: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after copying document fields into the current record.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when handling document fields. This can be useful for implementing additional logic
    /// or validations related to document types, numbers, or other fields.
    /// </summary>
    /// <param name="GenJnlLine">
    /// The current general journal line record to which the document fields have been copied.
    /// </param>
    /// <param name="DocType">
    /// The document type being copied.
    /// </param>
    /// <param name="DocNo">
    /// The document number being copied.
    /// </param>
    /// <param name="ExtDocNo">
    /// The external document number being copied.
    /// </param>
    /// <param name="SourceCode">
    /// The source code associated with the document being copied.
    /// </param>
    /// <param name="NoSeriesCode">
    /// The number series code used for posting, if specified.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDocumentFields(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                           ExtDocNo: Text[35];
                                                                                                           SourceCode: Code[10];
                                                                                                           NoSeriesCode: Code[20])
    begin
    end;

    /// <summary>
    /// Event triggered after finding the first Employee Ledger Entry using the "Applies-to Doc. No.".
    /// This event allows developers to add custom logic after an Employee Ledger Entry has successfully been located by "Applies-to Doc. No.".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="EmployeeLedgerEntry">The Employee Ledger Entry record that was found based on "Applies-to Doc. No.".</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry");
    begin
    end;

    /// <summary>
    /// Event triggered before clearing the applied General Journal Line.
    /// This event allows developers to add custom logic or skip the default clearing process for applied General Journal Lines.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default clearing logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyClearAppliedGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before updating the currency code on the General Journal Line.
    /// This event allows developers to implement custom logic or override the default currency code update logic.
    /// </summary>
    /// <param name="Rec">The current General Journal Line record being processed.</param>
    /// <param name="NewCurrencyCode">The new currency code to be applied to the General Journal Line.</param>
    /// <param name="isHandled">A boolean variable that, if set to true, skips the default currency code update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; NewCurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before checking and potentially modifying the currency code during application.
    /// Subscribing to this event allows developers to override or extend the behavior
    /// when validating the general journal line's currency code against the customer or vendor ledger entry's currency code.
    /// This can be useful for implementing custom validation logic or additional checks.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record being validated.
    /// </param>
    /// <param name="VendorLedgerEntry">
    /// The vendor ledger entry involved in the currency validation, if applicable.
    /// </param>
    /// <param name="CustLedgerEntry">
    /// The customer ledger entry involved in the currency validation, if applicable.
    /// </param>
    /// <param name="AccountType">
    /// The account type (e.g., Customer, Vendor) used to determine the context of the currency validation.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckModifyCurrencyCodeOnBeforeCheckAgainstApplnCurrency(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; AccountType: Enum "Gen. Journal Account Type")
    begin
    end;

    /// <summary>
    /// Event triggered after modifying the General Journal Line with a new "Document No." during the renumbering process.
    /// This event allows developers to change default logic after a General Journal Line has been updated with a new "Document No.".
    /// </summary>
    /// <param name="DocNo">The new "Document No." assigned to the General Journal Line.</param>
    /// <param name="GenJournalLine3">The General Journal Line record that was modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRenumberDocNoOnLinesOnAfterModifyGenJnlLine3(var DocNo: Code[20]; var GenJournalLine3: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before checking whether the description should be replaced in the journal line.
    /// This event allows developers to change the custom logic or skip the standard process.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="GenJournalTemplate">The General Journal Template associated with the operation.</param>
    /// <param name="Result">A boolean variable indicating whether the description should be replaced.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReplaceDescription(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalTemplate: Record "Gen. Journal Template"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the payment terms code for a customer account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when validating the payment terms code. This can be useful for implementing additional logic,
    /// validations, or specific workflows before the payment terms code has been validated.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the payment terms code is being validated.
    /// </param>
    /// <param name="Customer">
    /// The customer record associated with the general journal line.
    /// </param>
    /// <param name="HideValidationDialog">
    /// A boolean variable indicating whether the validation dialog should be hidden during the validation process.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnGetCustomerAccountOnBeforeValidatePaymentTermsCode(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; HideValidationDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before retrieving the "Due Date" of the related applied document.
    /// This event allows developers to add custom logic or skip the default logic for determining the "Due Date".
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed.</param>
    /// <param name="Result">A date variable representing the document's due date.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining the "Due Date".</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAppliesToDocDueDate(var GenJournalLine: Record "Gen. Journal Line"; var Result: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before validating the bank account's currency code during "Currency Code" validation.
    /// This event allows developers to add custom logic before the standard validation of the Bank Account Currency Code.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record on which the currency code validation is being performed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default bank account validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyCodeOnBeforeCheckBankAccountCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after updating allocations during the line balance update process.
    /// This event allows developers to change default calculation logic after allocations have been updated for the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    procedure OnUpdateLineBalanceOnAfterUpdateAllocations(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered before initializing the rounding precision of the currency in the General Journal Line.
    /// This event allows developers to add custom logic before the initialization of the currency rounding precision.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="Currency">The Currency record associated with the General Journal Line or General Ledger Setup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetCurrencyOnBeforeInitRoundingPrecision(var GenJournalLine: Record "Gen. Journal Line"; var Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Event triggered before initializing rounding precision during the calculation of VAT amount in LCY.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when calculating the VAT amount in LCY. This can be useful for implementing custom rounding logic,
    /// additional validations, or handling specific business rules related to VAT calculation.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the VAT amount in LCY is being calculated.
    /// </param>
    /// <param name="Currency">
    /// The currency record for the LCY (local currency), which can be modified before initialization.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLCYOnBeforeInitRoundingPrecision(var GenJournalLine: Record "Gen. Journal Line"; var Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Event triggered when none of the defined account types (Customer, Vendor, Employee) have been handled during the validation of the "Applies-to Doc. No." field.
    /// This event allows developers to add custom logic for other account types.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="xGenJournalLine">The previous state of the General Journal Line before changes were made.</param>
    /// <param name="TempGenJnlLine">A temporary General Journal Line record used for processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnCaseElse(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Event triggered after checking of the "G/L Account" in the General Journal Line.
    /// This event allows developers to add custom logic after the "G/L Account" validation checks have been completed.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line that was processed.</param>
    /// <param name="GLAccount">The G/L Account record that was validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Event triggered before setting the filter on the "Open" field of the Customer Ledger Entry during the lookup process.
    /// This event allows developers to override or modify the logic that sets the "Open" field filter on the Customer Ledger Entry.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default "Open" field filter setting.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnBeforeCustLedgerEntrySetRangeOpen(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before exporting the payment file.
    /// This event allows developers to add custom logic or skip the default logic for exporting the payment file.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record being processed for payment export.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default export payment file logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportPaymentFile(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before copying VAT setup to journal lines in the General Journal Line for the Fixed Asset.
    /// This event allows developers to add custom logic or skip the default process of copying VAT setup.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    /// <param name="GLAccount">The G/L Account record associated with the process.</param>
    /// <param name="FAPostingGroup">The Fixed Asset Posting Group record associated with the process.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for copying VAT setup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetFAVATSetupOnBeforeCopyVATSetupToJnlLines(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account"; var FAPostingGroup: Record "FA Posting Group"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the filter on the "Open" field of the Vendor Ledger Entry during the lookup process.
    /// This event allows developers to override or modify the default logic for setting the "Open" field filter on the Vendor Ledger Entry.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line record for which the lookup is being performed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default "Open" field filter logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnBeforeVendLedgerEntrySetRangeOpen(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the amount with the remaining amount from a customer ledger entry.
    /// Subscribing to this event allows developers to override or extend the behavior
    /// when determining the amount based on the remaining customer ledger entry data. This can be useful
    /// for customizing the calculation of the amount or applying specific business rules.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record involved in the operation.
    /// </param>
    /// <param name="CustLedgerEntry">
    /// The customer ledger entry record used for setting the remaining amount.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for setting the amount with the remaining data should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnSetAmountWithCustLedgEntryOnBeforeSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the amount with the remaining amount from a vendor ledger entry.
    /// Subscribing to this event allows developers to override or extend the behavior
    /// when determining the amount based on the remaining vendor ledger entry data. This can be useful
    /// for customizing the calculation of the amount or applying specific business rules.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record involved in the operation.
    /// </param>
    /// <param name="VendLedgerEntry">
    /// The vendor ledger entry record used for setting the remaining amount.
    /// </param>
    /// <param name="IsHandled">
    /// A boolean variable indicating whether the default behavior for setting the amount with the remaining data should be skipped.
    /// Setting this variable to true will skip the default behavior.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnSetAmountWithVendLedgEntryOnBeforeSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered before setting the description from a G/L account for the general journal line.
    /// Subscribing to this event allows developers to override or extend the default behavior
    /// when setting the description. This can be useful for implementing custom logic, validations,
    /// or additional processing before the description has been updated.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the description is being set.
    /// </param>
    /// <param name="GLAccount">
    /// The G/L account record from which the description is being derived.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDescriptionFromGLAcc(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Event triggered before checking of the "G/L Account" in the General Journal Line.
    /// This event allows developers to add custom logic before the "G/L Account" validation checks have been executed.
    /// </summary>
    /// <param name="GLAccount">The G/L Account record being validated.</param>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var GLAccount: Record "G/L Account"; var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event triggered after setting filters on the "Job Planning Line" during the lookup of the "Job Planning Line No." field.
    /// This event allows developers to change the filters applied to the "Job Planning Line" record or add custom logic before the lookup has been displayed.
    /// </summary>
    /// <param name="JobPlanningLine">The "Job Planning Line" record with the filters applied.</param>
    /// <param name="GenJournalLine">The current General Journal Line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupJobPlanningLineNoOnAfterJobPlanningLineSetFilter(var JobPlanningLine: Record "Job Planning Line"; var GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    /// <summary>
    /// Event triggered before validating the "Job Planning Line No." field in the General Journal Line.
    /// This event allows developers to add custom logic or skip the default validation process for the "Job Planning Line No." field.
    /// </summary>
    /// <param name="Rec">The current General Journal Line being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default validation logic for the "Job Planning Line No." field.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobPlanningLineNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Event triggered after editing the dimension set in the General Journal Line.
    /// This event allows developers to add custom logic after the dimension set has been updated in the General Journal Line.
    /// </summary>
    /// <param name="GenJournalLine">The current General Journal Line with the updated dimension set.</param>
    /// <param name="OldDimensionSetId">The Dimension Set ID prior to the changes made.</param>
    [IntegrationEvent(false, false)]
    local procedure OnShowDimensionsOnAfterEditDimensionSet(var GenJournalLine: Record "Gen. Journal Line"; OldDimensionSetId: Integer)
    begin
    end;

    /// <summary>
    /// Event triggered after calculating the remaining amount on the Vendor Ledger Entry.
    /// This event allows developers to add custom logic after the "Remaining Amount" field has been calculated on the Vendor Ledger Entry.
    /// </summary>
    /// <param name="VendorLedgerEntry">The Vendor Ledger Entry record with the calculated "Remaining Amount".</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgerEntryOnAfterCalcRemainingAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Event triggered after calculating the "Remaining Amount" on the Customer Ledger Entry.
    /// This event allows developers to add custom logic after the "Remaining Amount" field has been calculated on the Customer Ledger Entry.
    /// </summary>
    /// <param name="CustLedgerEntry">The Customer Ledger Entry record with the calculated "Remaining Amount".</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgerEntryOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToDocType(var GenJnlLine: Record "Gen. Journal Line"; xGenJnlLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line"; xGenJnlLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line"; xGenJnlLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOpenApprovalEntryExistForCurrentUser(GenJnlLine: Record "Gen. Journal Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAAddCurrExchRateOnBeforeFADeprBookTestField(var FADeprBook: Record "FA Depreciation Book"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLineBalanceOnBeforeUpdateAmounts(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertAmtFCYToLCYForSourceCurrency(var Rec: Record "Gen. Journal Line"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAccCurrencyCode(var GenJnlLine: Record "Gen. Journal Line"; var CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}
