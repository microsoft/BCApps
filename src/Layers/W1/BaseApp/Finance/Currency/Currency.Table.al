// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Integration.Dataverse;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.HumanResources.Payables;
using System.Utilities;
using System.Reflection;

/// <summary>
/// Represents currency settings and exchange rate information used throughout the system.
/// This table stores currency definitions, rounding settings, GL account mappings for currency transactions,
/// and provides calculated fields for customer and vendor balances in specific currencies.
/// </summary>
table 4 Currency
{
    Caption = 'Currency';
    LookupPageID = Currencies;
    Permissions = tabledata "General Ledger Setup" = r;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier code for the currency (e.g., USD, EUR, GBP).
        /// This field is required and must be non-blank.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
            begin
                if Symbol = '' then
                    Symbol := ResolveCurrencySymbol(Code);

                if (Code <> '') and (xRec.Code = '') then
                    UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification(Code);
            end;
        }
        /// <summary>
        /// Date when the currency record was last modified.
        /// This field is automatically maintained by the system.
        /// </summary>
        field(2; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        /// <summary>
        /// Date when the currency exchange rates were last adjusted.
        /// This field is automatically maintained by the system.
        /// </summary>
        field(3; "Last Date Adjusted"; Date)
        {
            Caption = 'Last Date Adjusted';
            Editable = false;
        }
        /// <summary>
        /// Three-letter ISO 4217 currency code (e.g., USD, EUR, GBP).
        /// Must be exactly 3 characters and contain only ASCII letters.
        /// </summary>
        field(4; "ISO Code"; Code[3])
        {
            Caption = 'ISO Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Regex: Codeunit Regex;
            begin
                if "ISO Code" = '' then
                    exit;
                if StrLen("ISO Code") < MaxStrLen("ISO Code") then
                    Error(ISOCodeLengthErr, StrLen("ISO Code"), MaxStrLen("ISO Code"), "ISO Code");
                if not Regex.IsMatch("ISO Code", '^[a-zA-Z]*$') then
                    FieldError("ISO Code", ASCIILetterErr);
            end;
        }
        /// <summary>
        /// Three-digit ISO 4217 numeric currency code (e.g., 840 for USD, 978 for EUR).
        /// Must be exactly 3 characters and contain only numeric digits.
        /// </summary>
        field(5; "ISO Numeric Code"; Code[3])
        {
            Caption = 'ISO Numeric Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "ISO Numeric Code" = '' then
                    exit;
                if StrLen("ISO Numeric Code") < MaxStrLen("ISO Numeric Code") then
                    Error(ISOCodeLengthErr, StrLen("ISO Numeric Code"), MaxStrLen("ISO Numeric Code"), "ISO Numeric Code");
                if not TypeHelper.IsNumeric("ISO Numeric Code") then
                    FieldError("ISO Numeric Code", NumericErr);
            end;
        }
        /// <summary>
        /// General Ledger account for posting unrealized currency gains.
        /// Used when currency exchange rates fluctuate positively between transaction and revaluation dates.
        /// </summary>
        field(6; "Unrealized Gains Acc."; Code[20])
        {
            Caption = 'Unrealized Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Unrealized Gains Acc.");
            end;
        }
        /// <summary>
        /// General Ledger account for posting realized currency gains.
        /// Used when currency gains are actually realized through settlement of transactions.
        /// </summary>
        field(7; "Realized Gains Acc."; Code[20])
        {
            Caption = 'Realized Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized Gains Acc.");
            end;
        }
        /// <summary>
        /// General Ledger account for posting unrealized currency losses.
        /// Used when currency exchange rates fluctuate negatively between transaction and revaluation dates.
        /// </summary>
        field(8; "Unrealized Losses Acc."; Code[20])
        {
            Caption = 'Unrealized Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Unrealized Losses Acc.");
            end;
        }
        /// <summary>
        /// General Ledger account for posting realized currency losses.
        /// Used when currency losses are actually realized through settlement of transactions.
        /// </summary>
        field(9; "Realized Losses Acc."; Code[20])
        {
            Caption = 'Realized Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized Losses Acc.");
            end;
        }
        /// <summary>
        /// Precision used for rounding invoice amounts in this currency.
        /// Determines the smallest unit to which invoice totals are rounded (e.g., 0.01 for cents).
        /// Must be compatible with the Amount Rounding Precision setting.
        /// </summary>
        field(10; "Invoice Rounding Precision"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            DecimalPlaces = 2 : 5;
            Caption = 'Invoice Rounding Precision';
            InitValue = 0.01;

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then
                    if "Invoice Rounding Precision" <> Round("Invoice Rounding Precision", "Amount Rounding Precision") then
                        FieldError(
                          "Invoice Rounding Precision",
                          StrSubstNo(Text000, "Amount Rounding Precision"));
            end;
        }
        /// <summary>
        /// Method used for rounding invoice amounts when applying Invoice Rounding Precision.
        /// Options: Nearest (standard rounding), Up (always round up), Down (always round down).
        /// </summary>
        field(12; "Invoice Rounding Type"; Option)
        {
            Caption = 'Invoice Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        /// <summary>
        /// Precision used for rounding general amounts in this currency.
        /// Determines the smallest unit to which amounts are rounded during calculations.
        /// </summary>
        field(13; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DecimalPlaces = 2 : 5;
            InitValue = 0.01;
            MinValue = 0;
            AutoFormatType = 1;
            AutoFormatExpression = Code;

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then begin
                    "Invoice Rounding Precision" := Round("Invoice Rounding Precision", "Amount Rounding Precision");
                    if "Amount Rounding Precision" > "Invoice Rounding Precision" then
                        "Invoice Rounding Precision" := "Amount Rounding Precision";
                end;
            end;
        }
        /// <summary>
        /// Precision used for rounding unit amounts (prices, rates) in this currency.
        /// Typically has higher precision than amount rounding for detailed calculations.
        /// </summary>
        field(14; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DecimalPlaces = 0 : 9;
            InitValue = 0.00001;
            MinValue = 0;
            AutoFormatType = 2;
            AutoFormatExpression = Code;
        }
        /// <summary>
        /// Descriptive name for the currency (e.g., "US Dollar", "Euro", "British Pound").
        /// </summary>
        field(15; Description; Text[30])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Format specification for displaying amounts in this currency.
        /// Defines minimum and maximum decimal places (e.g., "2:2" for exactly 2 decimal places).
        /// </summary>
        field(17; "Amount Decimal Places"; Text[5])
        {
            Caption = 'Amount Decimal Places';
            InitValue = '2:2';
            NotBlank = true;

            trigger OnValidate()
            begin
                GLSetup.CheckDecimalPlacesFormat("Amount Decimal Places");
            end;
        }
        /// <summary>
        /// Format specification for displaying unit amounts (prices, rates) in this currency.
        /// Typically allows more decimal places than regular amounts for precise calculations.
        /// </summary>
        field(18; "Unit-Amount Decimal Places"; Text[5])
        {
            Caption = 'Unit-Amount Decimal Places';
            InitValue = '2:5';
            NotBlank = true;

            trigger OnValidate()
            begin
                GLSetup.CheckDecimalPlacesFormat("Unit-Amount Decimal Places");
            end;
        }
        /// <summary>
        /// Flow filter to restrict calculations to a specific customer.
        /// Used with calculated fields to show customer-specific currency balances.
        /// </summary>
        field(19; "Customer Filter"; Code[20])
        {
            Caption = 'Customer Filter';
            FieldClass = FlowFilter;
            TableRelation = Customer;
        }
        /// <summary>
        /// Flow filter to restrict calculations to a specific vendor.
        /// Used with calculated fields to show vendor-specific currency balances.
        /// </summary>
        field(20; "Vendor Filter"; Code[20])
        {
            Caption = 'Vendor Filter';
            FieldClass = FlowFilter;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Flow filter to restrict calculations to a specific global dimension 1 value.
        /// Used with calculated fields for dimensional analysis of currency balances.
        /// </summary>
        field(21; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Flow filter to restrict calculations to a specific global dimension 2 value.
        /// Used with calculated fields for dimensional analysis of currency balances.
        /// </summary>
        field(22; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Flow filter to restrict calculations to a specific date or date range.
        /// Used with calculated fields to show currency balances as of specific dates.
        /// </summary>
        field(23; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Calculated field indicating whether customer ledger entries exist matching the current filters.
        /// Used to determine if customer balance calculations will return meaningful results.
        /// </summary>
        field(24; "Cust. Ledg. Entries in Filter"; Boolean)
        {
            CalcFormula = exist("Cust. Ledger Entry" where("Customer No." = field("Customer Filter"),
                                                            "Currency Code" = field(Code)));
            Caption = 'Cust. Ledg. Entries in Filter';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated customer balance in this currency based on detailed customer ledger entries.
        /// Amount is filtered by Customer Filter, dimension filters, and date filter settings.
        /// </summary>
        field(25; "Customer Balance"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Customer No." = field("Customer Filter"),
                                                                         "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                         "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                         "Posting Date" = field("Date Filter"),
                                                                         "Currency Code" = field(Code)));
            Caption = 'Customer Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated total of outstanding customer orders in this currency.
        /// Shows the sum of undelivered sales order amounts for the filtered customer.
        /// </summary>
        field(26; "Customer Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line"."Outstanding Amount" where("Document Type" = const(Order),
                                                                       "Bill-to Customer No." = field("Customer Filter"),
                                                                       "Currency Code" = field(Code),
                                                                       "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                       "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Customer Outstanding Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated total of shipped but not yet invoiced customer orders in this currency.
        /// Shows the sum of goods delivered but not yet billed to the customer.
        /// </summary>
        field(27; "Customer Shipped Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line"."Shipped Not Invoiced" where("Document Type" = const(Order),
                                                                         "Bill-to Customer No." = field("Customer Filter"),
                                                                         "Currency Code" = field(Code),
                                                                         "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                         "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Customer Shipped Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated customer balance due in this currency based on due dates.
        /// Shows amounts that are due for payment as of the specified date filter.
        /// </summary>
        field(28; "Customer Balance Due"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Customer No." = field("Customer Filter"),
                                                                         "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                         "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                         "Initial Entry Due Date" = field("Date Filter"),
                                                                         "Posting Date" = field(upperlimit("Date Filter")),
                                                                         "Currency Code" = field(Code)));
            Caption = 'Customer Balance Due';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated field indicating whether vendor ledger entries exist matching the current filters.
        /// Used to determine if vendor balance calculations will return meaningful results.
        /// </summary>
        field(29; "Vendor Ledg. Entries in Filter"; Boolean)
        {
            CalcFormula = exist("Vendor Ledger Entry" where("Vendor No." = field("Vendor Filter"),
                                                             "Currency Code" = field(Code)));
            Caption = 'Vendor Ledg. Entries in Filter';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated vendor balance in this currency based on detailed vendor ledger entries.
        /// Amount is filtered by Vendor Filter, dimension filters, and date filter settings.
        /// Note: Amount is negated to show payable amounts as positive values.
        /// </summary>
        field(30; "Vendor Balance"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("Vendor Filter"),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field(Code)));
            Caption = 'Vendor Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated total of outstanding vendor orders in this currency.
        /// Shows the sum of unreceived purchase order amounts for the filtered vendor.
        /// </summary>
        field(31; "Vendor Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Outstanding Amount" where("Document Type" = const(Order),
                                                                          "Pay-to Vendor No." = field("Vendor Filter"),
                                                                          "Currency Code" = field(Code),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Vendor Outstanding Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated total of received but not yet invoiced vendor orders in this currency.
        /// Shows the sum of goods received but not yet billed by the vendor.
        /// </summary>
        field(32; "Vendor Amt. Rcd. Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Amt. Rcd. Not Invoiced" where("Document Type" = const(Order),
                                                                              "Pay-to Vendor No." = field("Vendor Filter"),
                                                                              "Currency Code" = field(Code),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Vendor Amt. Rcd. Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated vendor balance due in this currency based on due dates.
        /// Shows amounts that are due for payment as of the specified date filter.
        /// Note: Amount is negated to show payable amounts as positive values.
        /// </summary>
        field(33; "Vendor Balance Due"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("Vendor Filter"),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Initial Entry Due Date" = field("Date Filter"),
                                                                           "Posting Date" = field(upperlimit("Date Filter")),
                                                                           "Currency Code" = field(Code)));
            Caption = 'Vendor Balance Due';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated customer balance in Local Currency (LCY) equivalent.
        /// Shows the same balance as Customer Balance but converted to local currency amounts.
        /// </summary>
        field(34; "Customer Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Customer No." = field("Customer Filter"),
                                                                                 "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = field("Date Filter"),
                                                                                 "Currency Code" = field(Code)));
            Caption = 'Customer Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Calculated vendor balance in Local Currency (LCY) equivalent.
        /// Shows the same balance as Vendor Balance but converted to local currency amounts.
        /// Note: Amount is negated to show payable amounts as positive values.
        /// </summary>
        field(35; "Vendor Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("Vendor Filter"),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field(Code)));
            Caption = 'Vendor Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// General Ledger account for posting realized currency gains on GL transactions.
        /// Used specifically for GL account postings as opposed to customer/vendor transactions.
        /// </summary>
        field(40; "Realized G/L Gains Account"; Code[20])
        {
            Caption = 'Realized G/L Gains Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized G/L Gains Account");
            end;
        }
        /// <summary>
        /// General Ledger account for posting realized currency losses on GL transactions.
        /// Used specifically for GL account postings as opposed to customer/vendor transactions.
        /// </summary>
        field(41; "Realized G/L Losses Account"; Code[20])
        {
            Caption = 'Realized G/L Losses Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized G/L Losses Account");
            end;
        }
        /// <summary>
        /// Precision used for rounding amounts during payment application processes.
        /// Determines the tolerance allowed when applying payments to invoices in this currency.
        /// </summary>
        field(44; "Appln. Rounding Precision"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            Caption = 'Appln. Rounding Precision';
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether this currency is part of the European Monetary Union (EMU).
        /// Used for special handling of Euro-related currencies and conversion logic.
        /// </summary>
        field(45; "EMU Currency"; Boolean)
        {
            Caption = 'EMU Currency';
        }
        /// <summary>
        /// System-calculated factor used in currency conversion calculations.
        /// This field is automatically maintained and should not be manually edited.
        /// </summary>
        field(46; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        /// <summary>
        /// General Ledger account for posting residual currency gains.
        /// Used for small rounding differences that occur during currency conversions.
        /// </summary>
        field(47; "Residual Gains Account"; Code[20])
        {
            Caption = 'Residual Gains Account';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// General Ledger account for posting residual currency losses.
        /// Used for small rounding differences that occur during currency conversions.
        /// </summary>
        field(48; "Residual Losses Account"; Code[20])
        {
            Caption = 'Residual Losses Account';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// General Ledger account for posting debit rounding differences during LCY conversion.
        /// Used when converting foreign currency amounts to local currency creates rounding differences.
        /// </summary>
        field(50; "Conv. LCY Rndg. Debit Acc."; Code[20])
        {
            Caption = 'Conv. LCY Rndg. Debit Acc.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// General Ledger account for posting credit rounding differences during LCY conversion.
        /// Used when converting foreign currency amounts to local currency creates rounding differences.
        /// </summary>
        field(51; "Conv. LCY Rndg. Credit Acc."; Code[20])
        {
            Caption = 'Conv. LCY Rndg. Credit Acc.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Maximum VAT difference amount allowed for transactions in this currency.
        /// Defines the tolerance for VAT calculation discrepancies during currency conversions.
        /// The amount is automatically rounded to the currency's Amount Rounding Precision.
        /// </summary>
        field(52; "Max. VAT Difference Allowed"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            Caption = 'Max. VAT Difference Allowed';

            trigger OnValidate()
            begin
                if "Max. VAT Difference Allowed" <> Round("Max. VAT Difference Allowed", "Amount Rounding Precision") then
                    Error(
                      Text001,
                      FieldCaption("Max. VAT Difference Allowed"), "Amount Rounding Precision");

                "Max. VAT Difference Allowed" := Abs("Max. VAT Difference Allowed");
            end;
        }
        /// <summary>
        /// Method used for rounding VAT amounts in this currency.
        /// Options: Nearest (standard rounding), Up (always round up), Down (always round down).
        /// </summary>
        field(53; "VAT Rounding Type"; Option)
        {
            Caption = 'VAT Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        /// <summary>
        /// Payment tolerance percentage allowed for this currency.
        /// This field is automatically maintained by the system and cannot be edited directly.
        /// </summary>
        field(54; "Payment Tolerance %"; Decimal)
        {
            Caption = 'Payment Tolerance %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        /// <summary>
        /// Maximum payment tolerance amount allowed for this currency.
        /// This field is automatically maintained by the system and cannot be edited directly.
        /// </summary>
        field(55; "Max. Payment Tolerance Amount"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance Amount';
            Editable = false;
            MinValue = 0;
        }
        /// <summary>
        /// Display symbol for the currency (e.g., $, €, £).
        /// If not specified, the system will attempt to resolve an appropriate symbol automatically.
        /// </summary>
        field(56; Symbol; Text[10])
        {
            Caption = 'Symbol';

            trigger OnValidate()
            begin
                CheckDuplicateCurrencySymbol(Rec.Symbol);
                CheckLCYSymbol(Rec.Symbol);
            end;
        }

        /// <summary>
        /// Timestamp of when the currency record was last modified.
        /// This field is automatically maintained by the system.
        /// </summary>
        field(57; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(166; "Currency Symbol Position"; Enum "Currency Symbol Position")
        {
            Caption = 'Currency Symbol Position';
            ToolTip = 'Specifies the position of the currency symbol in relation to the amount.';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        /// <summary>
        /// Calculated field indicating whether this currency record is coupled to Microsoft Dataverse.
        /// Used for integration scenarios where currency data is synchronized between systems.
        /// </summary>
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dataverse';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Currency)));
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    /// <summary>
    /// Validates that the currency is not being deleted while open ledger entries exist.
    /// Prevents deletion of currencies that are still in use by customer, vendor, or employee transactions.
    /// Also cleans up associated currency exchange rate records when deletion is allowed.
    /// </summary>
    trigger OnDelete()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Currency Code", Code);
        if not CustLedgEntry.IsEmpty() then
            Error(Text002, CustLedgEntry.TableCaption(), TableCaption(), Code);

        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Currency Code", Code);
        if not VendLedgEntry.IsEmpty() then
            Error(Text002, VendLedgEntry.TableCaption(), TableCaption(), Code);

        EmplLedgEntry.SetRange(Open, true);
        EmplLedgEntry.SetRange("Currency Code", Code);
        if not EmplLedgEntry.IsEmpty() then
            Error(Text002, EmplLedgEntry.TableCaption(), TableCaption(), Code);

        CurrExchRate.SetRange("Currency Code", Code);
        CurrExchRate.DeleteAll();
    end;

    /// <summary>
    /// Initializes required fields when a new currency record is created.
    /// Sets the Last Modified Date Time to the current system time.
    /// </summary>
    trigger OnInsert()
    begin
        TestField(Code);

        "Last Modified Date Time" := CurrentDateTime;
    end;

    /// <summary>
    /// Updates tracking fields when the currency record is modified.
    /// Sets Last Date Modified to today and Last Modified Date Time to current system time.
    /// </summary>
    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "Last Modified Date Time" := CurrentDateTime;
    end;

    /// <summary>
    /// Updates tracking fields when the currency record is renamed.
    /// Sets Last Date Modified to today and Last Modified Date Time to current system time.
    /// </summary>
    trigger OnRename()
    begin
        "Last Date Modified" := Today;
        "Last Modified Date Time" := CurrentDateTime;
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        TypeHelper: Codeunit "Type Helper";
        AccountSuggested: Boolean;
        DuplicateSymbolNotificationId: Label '8fcf129e-4be3-43c1-991d-d2fb116623eb', Locked = true;
        DuplicateSymbolNoteLbl: Label 'The currency symbol "%1" is used by multiple currencies. If shown in the UI this can be confusing. Please choose a different symbol.', Comment = '%1 = currency symbol';
        LCYSymbolNotificationId: Label '5d669b73-cfbc-4a8c-8c2e-cd9816a2591c', Locked = true;
        LCYSymbolNoteLbl: Label 'The currency symbol "%1" is used as local currency symbol. If shown in the UI this can be confusing. Please choose a different symbol.', Comment = '%1 = local currency symbol';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must be rounded to the nearest %1';
        Text001: Label '%1 must be rounded to the nearest %2.';
        Text002: Label 'There is one or more opened entries in the %1 table using %2 %3.', Comment = '1 either customer or vendor ledger entry table 2 name co currency table 3 currencency code';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        IncorrectEntryTypeErr: Label 'Incorrect Entry Type %1.';
#pragma warning restore AA0470
        EuroDescriptionTxt: Label 'Euro', Comment = 'Currency Description';
        CanadiandollarDescriptionTxt: Label 'Canadian dollar', Comment = 'Currency Description';
        BritishpoundDescriptionTxt: Label 'Pound Sterling', Comment = 'Currency Description';
        USdollarDescriptionTxt: Label 'US dollar', Comment = 'Currency Description';
        ISOCodeLengthErr: Label 'The length of the string is %1, but it must be equal to %2 characters. Value: %3.', Comment = '%1, %2 - numbers, %3 - actual value';
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';
        NoAccountSuggestedMsg: Label 'Cannot suggest G/L accounts as there is nothing to base suggestion on.';

    /// <summary>
    /// Initializes currency rounding precision fields with values from General Ledger Setup.
    /// Sets default values for Amount Rounding Precision, Unit-Amount Rounding Precision,
    /// Invoice Rounding settings, VAT settings, and raises the OnAfterInitRoundingPrecision event.
    /// </summary>
    procedure InitRoundingPrecision()
    begin
        GLSetup.Get();
        if GLSetup."Amount Rounding Precision" <> 0 then
            "Amount Rounding Precision" := GLSetup."Amount Rounding Precision"
        else
            "Amount Rounding Precision" := 0.01;
        if GLSetup."Unit-Amount Rounding Precision" <> 0 then
            "Unit-Amount Rounding Precision" := GLSetup."Unit-Amount Rounding Precision"
        else
            "Unit-Amount Rounding Precision" := 0.00001;
        "Max. VAT Difference Allowed" := GLSetup."Max. VAT Difference Allowed";
        "VAT Rounding Type" := GLSetup."VAT Rounding Type";
        "Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
        "Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";

        OnAfterInitRoundingPrecision(Rec, xRec, GLSetup);
    end;

    /// <summary>
    /// Validates that the specified G/L account number exists and is valid.
    /// Performs account validation checks to ensure the account can be used for posting.
    /// </summary>
    /// <param name="AccNo">The G/L account number to validate</param>
    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    /// <summary>
    /// Returns the directional symbol for VAT rounding based on the VAT Rounding Type setting.
    /// Used in rounding calculations to determine rounding behavior.
    /// </summary>
    /// <returns>Text character: = for Nearest, &gt; for Up, &lt; for Down</returns>
    procedure VATRoundingDirection(): Text[1]
    begin
        case "VAT Rounding Type" of
            "VAT Rounding Type"::Nearest:
                exit('=');
            "VAT Rounding Type"::Up:
                exit('>');
            "VAT Rounding Type"::Down:
                exit('<');
        end;
    end;

    /// <summary>
    /// Returns the directional symbol for invoice rounding based on the Invoice Rounding Type setting.
    /// Used in invoice rounding calculations to determine rounding behavior.
    /// </summary>
    /// <returns>Text character: = for Nearest, &gt; for Up, &lt; for Down</returns>
    procedure InvoiceRoundingDirection(): Text[1]
    begin
        case "Invoice Rounding Type" of
            "Invoice Rounding Type"::Nearest:
                exit('=');
            "Invoice Rounding Type"::Up:
                exit('>');
            "Invoice Rounding Type"::Down:
                exit('<');
        end;
    end;

    /// <summary>
    /// Validates that required rounding precision fields are properly set.
    /// Ensures both Unit-Amount Rounding Precision and Amount Rounding Precision have values.
    /// </summary>
    procedure CheckAmountRoundingPrecision()
    begin
        TestField("Unit-Amount Rounding Precision");
        TestField("Amount Rounding Precision");
    end;

    /// <summary>
    /// Determines the appropriate G/L account for posting currency gain/loss based on entry type.
    /// Routes to specific account getter methods based on the type of gain/loss being processed.
    /// Raises OnBeforeGetGainLossAccount event for customization opportunities.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuf">Detailed CV ledger entry buffer containing entry type information</param>
    /// <returns>G/L account code for posting the currency gain/loss</returns>
    procedure GetGainLossAccount(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"): Code[20]
    var
        ReturnValue: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetGainLossAccount(Rec, DtldCVLedgEntryBuf);

        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss":
                exit(GetUnrealizedLossesAccount());
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain":
                exit(GetUnrealizedGainsAccount());
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss":
                exit(GetRealizedLossesAccount());
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                exit(GetRealizedGainsAccount());
            else begin
                IsHandled := false;
                OnGetGainLossAccountOnOtherEntryType(Rec, DtldCVLedgEntryBuf, IsHandled, ReturnValue);
                if IsHandled then
                    exit(ReturnValue)
                else
                    Error(IncorrectEntryTypeErr, DtldCVLedgEntryBuf."Entry Type");
            end;
        end;
    end;

    /// <summary>
    /// Returns the G/L account for posting realized currency gains.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for realized gains</returns>
    procedure GetRealizedGainsAccount(): Code[20]
    begin
        TestField("Realized Gains Acc.");
        exit("Realized Gains Acc.");
    end;

    /// <summary>
    /// Returns the G/L account for posting realized currency losses.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for realized losses</returns>
    procedure GetRealizedLossesAccount(): Code[20]
    begin
        TestField("Realized Losses Acc.");
        exit("Realized Losses Acc.");
    end;

    /// <summary>
    /// Returns the G/L account for posting realized currency gains on G/L transactions.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for realized G/L gains</returns>
    procedure GetRealizedGLGainsAccount(): Code[20]
    begin
        TestField("Realized G/L Gains Account");
        exit("Realized G/L Gains Account");
    end;

    /// <summary>
    /// Returns the G/L account for posting realized currency losses on G/L transactions.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for realized G/L losses</returns>
    procedure GetRealizedGLLossesAccount(): Code[20]
    begin
        TestField("Realized G/L Losses Account");
        exit("Realized G/L Losses Account");
    end;

    /// <summary>
    /// Returns the G/L account for posting residual currency gains.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for residual gains</returns>
    procedure GetResidualGainsAccount(): Code[20]
    begin
        TestField("Residual Gains Account");
        exit("Residual Gains Account");
    end;

    /// <summary>
    /// Returns the G/L account for posting residual currency losses.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for residual losses</returns>
    procedure GetResidualLossesAccount(): Code[20]
    begin
        TestField("Residual Losses Account");
        exit("Residual Losses Account");
    end;

    /// <summary>
    /// Returns the G/L account for posting unrealized currency gains.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for unrealized gains</returns>
    procedure GetUnrealizedGainsAccount(): Code[20]
    begin
        TestField("Unrealized Gains Acc.");
        exit("Unrealized Gains Acc.");
    end;

    /// <summary>
    /// Returns the G/L account for posting unrealized currency losses.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for unrealized losses</returns>
    procedure GetUnrealizedLossesAccount(): Code[20]
    begin
        TestField("Unrealized Losses Acc.");
        exit("Unrealized Losses Acc.");
    end;

    /// <summary>
    /// Returns the G/L account for posting debit rounding differences during LCY conversion.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for LCY conversion debit rounding</returns>
    procedure GetConvLCYRoundingDebitAccount(): Code[20]
    begin
        TestField("Conv. LCY Rndg. Debit Acc.");
        exit("Conv. LCY Rndg. Debit Acc.");
    end;

    /// <summary>
    /// Returns the G/L account for posting credit rounding differences during LCY conversion.
    /// Validates that the account is specified before returning it.
    /// </summary>
    /// <returns>G/L account code for LCY conversion credit rounding</returns>
    procedure GetConvLCYRoundingCreditAccount(): Code[20]
    begin
        TestField("Conv. LCY Rndg. Credit Acc.");
        exit("Conv. LCY Rndg. Credit Acc.");
    end;

    /// <summary>
    /// Gets the display symbol for this currency, falling back to the currency code if no symbol is defined.
    /// </summary>
    /// <returns>Currency symbol or currency code if symbol is not specified</returns>
    procedure GetCurrencySymbol(): Text[10]
    begin
        if Symbol <> '' then
            exit(Symbol);

        exit(Code);
    end;

    /// <summary>
    /// Resolves an appropriate display symbol for a given currency code.
    /// First checks if the currency record has a custom symbol, then falls back to
    /// built-in symbol mappings for common currencies.
    /// Raises OnBeforeResolveCurrencySymbol event for customization.
    /// </summary>
    /// <param name="CurrencyCode">The currency code to resolve a symbol for</param>
    /// <returns>Currency symbol or empty string if no mapping is found</returns>
    procedure ResolveCurrencySymbol(CurrencyCode: Code[10]): Text[10]
    var
        Currency: Record Currency;
        PoundChar: Char;
        EuroChar: Char;
        YenChar: Char;
    begin
        OnBeforeResolveCurrencySymbol(Rec, CurrencyCode);
        if Currency.Get(CurrencyCode) then
            if Currency.Symbol <> '' then
                exit(Currency.Symbol);

        PoundChar := 163;
        YenChar := 165;
        EuroChar := 8364;

        case CurrencyCode of
            'AUD', 'BND', 'CAD', 'FJD', 'HKD', 'MXN', 'NZD', 'SBD', 'SGD', 'USD':
                exit('$');
            'GBP':
                exit(Format(PoundChar));
            'DKK', 'ISK', 'NOK', 'SEK':
                exit('kr');
            'EUR':
                exit(Format(EuroChar));
            'CNY', 'JPY':
                exit(Format(YenChar));
        end;

        exit('');
    end;

    /// <summary>
    /// Resolves a descriptive name for a given currency code.
    /// First checks if the currency record has a custom description, then falls back to
    /// built-in description mappings for common currencies.
    /// </summary>
    /// <param name="CurrencyCode">The currency code to resolve a description for</param>
    /// <returns>Currency description or empty string if no mapping is found</returns>
    procedure ResolveCurrencyDescription(CurrencyCode: Code[10]): Text
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrencyCode) then
            if Currency.Description <> '' then
                exit(Currency.Description);

        case CurrencyCode of
            'CAD':
                exit(CanadiandollarDescriptionTxt);
            'GBP':
                exit(BritishpoundDescriptionTxt);
            'USD':
                exit(USdollarDescriptionTxt);
            'EUR':
                exit(EuroDescriptionTxt);
        end;

        exit('');
    end;

    /// <summary>
    /// Resolves the currency symbol for use in General Ledger contexts.
    /// If a currency code is provided, resolves its symbol. If empty, returns the LCY symbol from GL Setup.
    /// </summary>
    /// <param name="CurrencyCode">The currency code to resolve, or empty for LCY</param>
    /// <returns>Currency symbol for the specified currency or LCY symbol</returns>
    procedure ResolveGLCurrencySymbol(CurrencyCode: Code[10]): Text[10]
    var
        Currency: Record Currency;
    begin
        if CurrencyCode <> '' then
            exit(Currency.ResolveCurrencySymbol(CurrencyCode));

        GLSetup.Get();
        exit(GLSetup.GetCurrencySymbol());
    end;

    /// <summary>
    /// Initializes the currency record by loading it if a currency code is provided.
    /// If no currency code is provided, initializes rounding precision from GL Setup.
    /// This is an overload that calls the full Initialize method with CheckAmountRoundingPrecision set to false.
    /// </summary>
    /// <param name="CurrencyCode">Currency code to initialize, or empty for LCY initialization</param>
    procedure Initialize(CurrencyCode: Code[10])
    begin
        Initialize(CurrencyCode, false);
    end;

    /// <summary>
    /// Initializes the currency record by loading it if a currency code is provided.
    /// If no currency code is provided, initializes rounding precision from GL Setup.
    /// Optionally validates that Amount Rounding Precision is properly set.
    /// </summary>
    /// <param name="CurrencyCode">Currency code to initialize, or empty for LCY initialization</param>
    /// <param name="CheckAmountRoundingPrecision">Whether to validate Amount Rounding Precision field</param>
    procedure Initialize(CurrencyCode: Code[10]; CheckAmountRoundingPrecision: Boolean)
    begin
        if CurrencyCode <> '' then begin
            Get(CurrencyCode);
            if CheckAmountRoundingPrecision then
                TestField("Amount Rounding Precision");
        end else
            InitRoundingPrecision();
    end;

    /// <summary>
    /// Suggests appropriate G/L accounts for currency posting based on existing currency setups.
    /// Analyzes other currency records to suggest commonly used accounts for gain/loss posting.
    /// Shows a message if no suggestions can be made.
    /// </summary>
    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        AccountSuggested := false;
        RecRef.GetTable(Rec);
        SuggestGainLossAccounts(RecRef);
        SuggestOtherAccounts(RecRef);
        if AccountSuggested then
            RecRef.Modify()
        else
            Message(NoAccountSuggestedMsg);
    end;

    /// <summary>
    /// Suggests G/L accounts for gain and loss posting based on other currency configurations.
    /// Private helper method that suggests accounts for unrealized and realized gains/losses.
    /// </summary>
    /// <param name="RecRef">Record reference to the current currency record being updated</param>
    local procedure SuggestGainLossAccounts(var RecRef: RecordRef)
    begin
        if "Unrealized Gains Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Unrealized Gains Acc."));
        if "Realized Gains Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Realized Gains Acc."));
        if "Unrealized Losses Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Unrealized Losses Acc."));
        if "Realized Losses Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Realized Losses Acc."));
    end;

    /// <summary>
    /// Suggests other G/L accounts for currency posting based on other currency configurations.
    /// Private helper method that suggests accounts for GL gains/losses, residual amounts, and rounding.
    /// </summary>
    /// <param name="RecRef">Record reference to the current currency record being updated</param>
    local procedure SuggestOtherAccounts(var RecRef: RecordRef)
    begin
        if "Realized G/L Gains Account" = '' then
            SuggestAccount(RecRef, FieldNo("Realized G/L Gains Account"));
        if "Realized G/L Losses Account" = '' then
            SuggestAccount(RecRef, FieldNo("Realized G/L Losses Account"));
        if "Residual Gains Account" = '' then
            SuggestAccount(RecRef, FieldNo("Residual Gains Account"));
        if "Residual Losses Account" = '' then
            SuggestAccount(RecRef, FieldNo("Residual Losses Account"));
        if "Conv. LCY Rndg. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Conv. LCY Rndg. Debit Acc."));
        if "Conv. LCY Rndg. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Conv. LCY Rndg. Credit Acc."));
    end;

    /// <summary>
    /// Analyzes other currency records to suggest the most commonly used account for a specific field.
    /// Private helper method that finds the most frequently used account across other currencies.
    /// </summary>
    /// <param name="RecRef">Record reference to the current currency record being updated</param>
    /// <param name="AccountFieldNo">Field number of the account field to suggest a value for</param>
    local procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        CurrencyRecRef: RecordRef;
        CurrencyFieldRef: FieldRef;
    begin
        CurrencyRecRef.Open(DATABASE::Currency);

        CurrencyRecRef.Reset();
        CurrencyFieldRef := CurrencyRecRef.Field(FieldNo(Code));
        CurrencyFieldRef.SetFilter('<>%1', Code);
        TempAccountUseBuffer.UpdateBuffer(CurrencyRecRef, AccountFieldNo);
        CurrencyRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
            AccountSuggested := true;
        end;
    end;

    procedure CheckDuplicateCurrencySymbol(CurrencySymbol: Text[10])
    var
        Currency: Record Currency;
        DuplicateeSymbolNotification: Notification;
    begin
        DuplicateeSymbolNotification.Id := DuplicateSymbolNotificationId;
        DuplicateeSymbolNotification.Recall();

        if CurrencySymbol = '' then
            exit;

        Currency.SetRange(Symbol, CurrencySymbol);
        if not Currency.IsEmpty() then begin
            DuplicateeSymbolNotification.Message(StrSubstNo(DuplicateSymbolNoteLbl, CurrencySymbol));
            DuplicateeSymbolNotification.Send();
        end;
    end;

    local procedure CheckLCYSymbol(CurrencySymbol: Text[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LCYSymbolNotification: Notification;
    begin
        if CurrencySymbol = '' then
            exit;

        LCYSymbolNotification.Id := LCYSymbolNotificationId;
        LCYSymbolNotification.Recall();

        GeneralLedgerSetup.Get();
        if CurrencySymbol = GeneralLedgerSetup."Local Currency Symbol" then begin
            LCYSymbolNotification.Message(StrSubstNo(LCYSymbolNoteLbl, CurrencySymbol));
            LCYSymbolNotification.Send();
        end;
    end;

    /// <summary>
    /// Integration event raised after initializing currency rounding precision settings.
    /// Allows customization of rounding precision initialization logic.
    /// </summary>
    /// <param name="Currency">Current currency record being initialized</param>
    /// <param name="xCurrency">Previous version of the currency record</param>
    /// <param name="GeneralLedgerSetup">General Ledger Setup record used for default values</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRoundingPrecision(var Currency: Record Currency; var xCurrency: Record Currency; var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    /// <summary>
    /// Integration event raised before determining the gain/loss account for currency transactions.
    /// Allows customization of account determination logic.
    /// </summary>
    /// <param name="Currency">Current currency record</param>
    /// <param name="DtldCVLedgEntryBuffer">Detailed CV ledger entry buffer containing transaction details</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGainLossAccount(var Currency: Record Currency; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before resolving a currency symbol.
    /// Allows customization of currency symbol resolution logic.
    /// </summary>
    /// <param name="Currency">Current currency record</param>
    /// <param name="CurrencyCode">Currency code being resolved</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeResolveCurrencySymbol(var Currency: Record Currency; var CurrencyCode: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised when determining gain/loss account for entry types not handled by default logic.
    /// Allows handling of custom entry types for currency gain/loss posting.
    /// </summary>
    /// <param name="Currency">Current currency record</param>
    /// <param name="DtldCVLedgEntryBuffer">Detailed CV ledger entry buffer containing transaction details</param>
    /// <param name="IsHandled">Set to true if the custom logic handles the entry type</param>
    /// <param name="ReturnValue">G/L account code to use for posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetGainLossAccountOnOtherEntryType(var Currency: Record Currency; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var IsHandled: Boolean; var ReturnValue: Code[20])
    begin
    end;
}
