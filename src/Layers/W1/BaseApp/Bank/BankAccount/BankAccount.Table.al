// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Statement;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Intrastat;
using Microsoft.Utilities;
using System;
using System.Email;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Threading;

/// <summary>
/// Master data table for bank account information and configuration.
/// Supports multi-currency accounts, payment processing, statement import, and reconciliation.
/// </summary>
/// <remarks>
/// Integrates with Bank Account Ledger Entry, Payment Processing, Bank Reconciliation, and Statement Import.
/// Extensibility: OnValidateBankAccount, OnUnlinkStatementProviderEvent events for custom validation logic.
/// </remarks>
table 270 "Bank Account"
{
    Caption = 'Bank Account';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Bank Account List";
    LookupPageID = "Bank Account List";
    Permissions = TableData "Bank Account Ledger Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the bank account.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GLSetup.Get();
                    NoSeries.TestManual(GLSetup."Bank Account Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        /// <summary>
        /// Primary name of the bank account for display and reporting purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
                    "Search Name" := Name;
            end;
        }
        /// <summary>
        /// Search name used for quick lookup and filtering of bank accounts.
        /// </summary>
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        /// <summary>
        /// Secondary name line for extended bank account identification.
        /// </summary>
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        /// <summary>
        /// Primary address line of the bank account.
        /// </summary>
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        /// <summary>
        /// Secondary address line for extended address information.
        /// </summary>
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        /// <summary>
        /// City name with postal code integration and country-specific validation.
        /// </summary>
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        /// <summary>
        /// Primary contact person for the bank account.
        /// </summary>
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Phone number for bank account inquiries.
        /// </summary>
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Telex number for legacy communication methods.
        /// </summary>
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        /// <summary>
        /// Bank account number as provided by the financial institution.
        /// </summary>
        field(13; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Account No.');
            end;
        }
        /// <summary>
        /// Transit routing number for check processing and electronic transfers.
        /// </summary>
        field(14; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        /// <summary>
        /// Sales territory code for reporting and analysis purposes.
        /// </summary>
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        /// <summary>
        /// Primary global dimension code for financial analysis and reporting.
        /// </summary>
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Secondary global dimension code for extended financial analysis.
        /// </summary>
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Chain name for bank branch identification.
        /// </summary>
        field(18; "Chain Name"; Code[10])
        {
            Caption = 'Chain Name';
        }
        /// <summary>
        /// Minimum balance threshold for account monitoring and alerts.
        /// </summary>
        field(20; "Min. Balance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Min. Balance';
        }
        /// <summary>
        /// Posting group that determines G/L account assignments for bank transactions.
        /// </summary>
        field(21; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        /// <summary>
        /// Currency code for multi-currency bank account support.
        /// </summary>
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                GeneralLedgerSetup: Record "General Ledger Setup";
                BankAccount: Record "Bank Account";
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;
                GeneralLedgerSetup.Get();
                if (("Currency Code" in ['', GeneralLedgerSetup."LCY Code"]) and (xRec."Currency Code" in ['', GeneralLedgerSetup."LCY Code"])) then
                    exit;

                BankAccount := Rec;
                BankAccount.CalcFields(Balance, "Balance (LCY)");
                OnValidateCurrencyCodeOnBeforeTestBalanceFields(BankAccount);
                BankAccount.TestField(Balance, 0);
                BankAccount.TestField("Balance (LCY)", 0);

                if not BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open) then
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.");
                BankAccLedgEntry.SetRange("Bank Account No.", "No.");
                BankAccLedgEntry.SetRange(Open, true);
                if BankAccLedgEntry.FindLast() then
                    Error(
                      Text000,
                      FieldCaption("Currency Code"));
            end;
        }
        /// <summary>
        /// Language code for bank account communication and document formatting.
        /// </summary>
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Regional format settings for number and date formatting in bank communications.
        /// </summary>
        field(25; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Statistical grouping code for bank account reporting and analysis.
        /// </summary>
        field(26; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
        }
        field(29; "Our Contact Code"; Code[20])
        {
            Caption = 'Our Contact Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        /// <summary>
        /// Working amount field for temporary calculations and processing.
        /// </summary>
        field(37; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Indicates whether comment lines exist for this bank account record.
        /// </summary>
        field(38; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("Bank Account"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether the bank account is blocked from being used in transactions.
        /// </summary>
        field(39; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Statement number of the last processed bank statement for reconciliation.
        /// </summary>
        field(41; "Last Statement No."; Code[20])
        {
            Caption = 'Last Statement No.';
        }
        /// <summary>
        /// Statement number of the last processed payment reconciliation statement.
        /// </summary>
        field(42; "Last Payment Statement No."; Code[20])
        {
            Caption = 'Last Payment Statement No.';

            trigger OnValidate()
            begin
                if IncStr("Last Payment Statement No.") = '' then
                    Error(UnincrementableStringErr, FieldCaption("Last Payment Statement No."));
            end;
        }
        /// <summary>
        /// Number series used for payment reconciliation document numbering.
        /// </summary>
        field(43; "Pmt. Rec. No. Series"; Code[20])
        {
            Caption = 'Payment Reconciliation No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                BankAccReconciliation: Record "Bank Acc. Reconciliation";
            begin
                if "Pmt. Rec. No. Series" = '' then begin
                    BankAccReconciliation.SetRange("Bank Account No.", "No.");
                    BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Payment Application");
                    if BankAccReconciliation.FindLast() then
                        "Last Payment Statement No." := BankAccReconciliation."Statement No.";
                end;
            end;
        }
        /// <summary>
        /// Date when the bank account record was last modified.
        /// </summary>
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        /// <summary>
        /// Date filter used for calculating balance and transaction amounts in FlowFields.
        /// </summary>
        field(55; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter field for Global Dimension 1 used in balance and transaction calculations.
        /// </summary>
        field(56; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Filter field for Global Dimension 2 used in balance and transaction calculations.
        /// </summary>
        field(57; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Current balance of the bank account calculated from ledger entries.
        /// </summary>
        field(58; Balance; Decimal)
        {
            AccessByPermission = TableData "Bank Account Ledger Entry" = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Current balance in local currency calculated from ledger entries.
        /// </summary>
        field(59; "Balance (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Bank Account Ledger Entry" = R;
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Net Change"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Net change amount in local currency for the filtered period.
        /// </summary>
        field(61; "Net Change (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Posting Date" = field("Date Filter")));
            Caption = 'Net Change (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total amount of checks posted but not yet cleared through bank reconciliation.
        /// </summary>
        field(62; "Total on Checks"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Check Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                 "Entry Status" = filter(Posted),
                                                                 "Statement Status" = filter(<> Closed)));
            Caption = 'Total on Checks';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether this bank account should be used as the default for its currency.
        /// </summary>
        field(70; "Use as Default for Currency"; Boolean)
        {
            Caption = 'Use as Default for Currency';
            trigger OnValidate()
            begin
                if "Use as Default for Currency" = true then
                    EnsureUniqueForCurrency();
            end;
        }
        /// <summary>
        /// Fax number for bank account communications.
        /// </summary>
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        /// <summary>
        /// Telex answer back code for legacy communication systems.
        /// </summary>
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        /// <summary>
        /// Postal code with country-specific validation and city integration.
        /// </summary>
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        /// <summary>
        /// County or state information with country-specific caption formatting.
        /// </summary>
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        /// <summary>
        /// Number of the last check issued from this bank account.
        /// </summary>
        field(93; "Last Check No."; Code[20])
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Last Check No.';
        }
        /// <summary>
        /// Ending balance from the last bank statement used for reconciliation.
        /// </summary>
        field(94; "Balance Last Statement"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Balance Last Statement';
        }
        /// <summary>
        /// Balance as of the date specified in the Date Filter field.
        /// </summary>
        field(95; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Balance in local currency as of the date specified in the Date Filter field.
        /// </summary>
        field(96; "Balance at Date (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total debit amounts for the filtered period in account currency.
        /// </summary>
        field(97; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Debit Amount" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total credit amounts for the filtered period in account currency.
        /// </summary>
        field(98; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Credit Amount" where("Bank Account No." = field("No."),
                                                                                 "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                 "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total debit amounts for the filtered period in local currency.
        /// </summary>
        field(99; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Debit Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                      "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                      "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                      "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total credit amounts for the filtered period in local currency.
        /// </summary>
        field(100; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Credit Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Bank branch number or sort code for routing transactions.
        /// </summary>
        field(101; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Branch No.');
            end;
        }
        /// <summary>
        /// Email address for electronic communications and notifications.
        /// </summary>
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        /// <summary>
        /// Website URL for the bank or financial institution.
        /// </summary>
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(103; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        /// <summary>
        /// Number series assigned to this bank account for automatic numbering.
        /// </summary>
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Report ID for the check printing report associated with this bank account.
        /// </summary>
        field(108; "Check Report ID"; Integer)
        {
            Caption = 'Check Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        /// <summary>
        /// Name of the check printing report retrieved from the Check Report ID.
        /// </summary>
        field(109; "Check Report Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Report),
                                                                        "Object ID" = field("Check Report ID")));
            Caption = 'Check Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// International Bank Account Number for electronic transactions and SEPA payments.
        /// </summary>
        field(110; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIBAN(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        /// <summary>
        /// SWIFT code (BIC) for international wire transfers and banking communications.
        /// </summary>
        field(111; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Data exchange format used for importing bank statements from external sources.
        /// </summary>
        field(113; "Bank Statement Import Format"; Code[20])
        {
            Caption = 'Bank Statement Import Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Import));
        }
        /// <summary>
        /// Number series for credit transfer message numbering in electronic payments.
        /// </summary>
        field(115; "Credit Transfer Msg. Nos."; Code[20])
        {
            Caption = 'Credit Transfer Msg. Nos.';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Number series for direct debit message numbering in automated debit processing.
        /// </summary>
        field(116; "Direct Debit Msg. Nos."; Code[20])
        {
            Caption = 'Direct Debit Msg. Nos.';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Export format for SEPA direct debit file generation and transmission.
        /// </summary>
        field(117; "SEPA Direct Debit Exp. Format"; Code[20])
        {
            Caption = 'SEPA Direct Debit Exp. Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Export));
        }
        /// <summary>
        /// Record ID linking to the online bank statement service provider configuration.
        /// </summary>
        field(121; "Bank Stmt. Service Record ID"; RecordID)
        {
            Caption = 'Bank Stmt. Service Record ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Handled: Boolean;
            begin
                if Format("Bank Stmt. Service Record ID") = '' then
                    OnUnlinkStatementProviderEvent(Rec, Handled);
            end;
        }
        /// <summary>
        /// Number of days for automatic transaction import from online banking services.
        /// </summary>
        field(123; "Transaction Import Timespan"; Integer)
        {
            Caption = 'Transaction Import Timespan';
        }
        /// <summary>
        /// Enables automatic import of bank statements from connected online banking services.
        /// </summary>
        field(124; "Automatic Stmt. Import Enabled"; Boolean)
        {
            Caption = 'Automatic Stmt. Import Enabled';

            trigger OnValidate()
            begin
                if "Automatic Stmt. Import Enabled" then begin
                    if not IsAutoLogonPossible() then
                        Error(MFANotSupportedErr);

                    if not ("Transaction Import Timespan" in [0 .. 9999]) then
                        Error(TransactionImportTimespanMustBePositiveErr);
                    ScheduleBankStatementDownload()
                end else
                    UnscheduleBankStatementDownload();
            end;
        }
        /// <summary>
        /// Enables the bank account for intercompany transactions and processing.
        /// </summary>
        field(130; IntercompanyEnable; Boolean)
        {
            Caption = 'Enable for Intercompany transactions';
        }
        /// <summary>
        /// Image or logo associated with the bank account for visual identification.
        /// </summary>
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        /// <summary>
        /// Creditor identification number for SEPA direct debit transactions.
        /// </summary>
        field(170; "Creditor No."; Code[35])
        {
            Caption = 'Creditor No.';
        }
        /// <summary>
        /// Export format configuration for electronic payment file generation.
        /// </summary>
        field(1210; "Payment Export Format"; Code[20])
        {
            Caption = 'Payment Export Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Export));
        }
        /// <summary>
        /// Bank clearing code for routing and processing electronic transactions.
        /// </summary>
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
        }
        /// <summary>
        /// Standard format specification for bank clearing code interpretation.
        /// </summary>
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
        }
        /// <summary>
        /// Type of matching tolerance used for automatic payment matching (Percentage or Amount).
        /// </summary>
        field(1250; "Match Tolerance Type"; Option)
        {
            Caption = 'Match Tolerance Type';
            OptionCaption = 'Percentage,Amount';
            OptionMembers = Percentage,Amount;

            trigger OnValidate()
            begin
                if "Match Tolerance Type" <> xRec."Match Tolerance Type" then
                    "Match Tolerance Value" := 0;
            end;
        }
        /// <summary>
        /// Tolerance value for automatic payment matching based on the specified tolerance type.
        /// </summary>
        field(1251; "Match Tolerance Value"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Match Tolerance Value';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Match Tolerance Value" < 0 then
                    Error(InvalidValueErr);

                if "Match Tolerance Type" = "Match Tolerance Type"::Percentage then
                    if "Match Tolerance Value" > 99 then
                        Error(InvalidPercentageValueErr, FieldCaption("Match Tolerance Type"),
                          Format("Match Tolerance Type"::Percentage));
            end;
        }
        /// <summary>
        /// Disables automatic payment matching for this bank account during reconciliation.
        /// </summary>
        field(1252; "Disable Automatic Pmt Matching"; Boolean)
        {
            Caption = 'Disable Automatic Payment Matching';
        }
        /// <summary>
        /// Disables performance optimization for bank reconciliation to improve matching precision.
        /// </summary>
        field(1253; "Disable Bank Rec. Optimization"; Boolean)
        {
            Caption = 'Disable Bank Reconciliation Optimization';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not "Disable Bank Rec. Optimization" then
                    exit;
                if not GuiAllowed() then
                    exit;
                if not Confirm(DisablingMakesBankRecAutomatchSlowerWarnMsg) then
                    Error('');
            end;
        }
        /// <summary>
        /// Export configuration code for positive pay file generation and fraud prevention.
        /// </summary>
        field(1260; "Positive Pay Export Code"; Code[20])
        {
            Caption = 'Positive Pay Export Code';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const("Export-Positive Pay"));
        }
        /// <summary>
        /// Requires check transmission verification before posting payment journal entries.
        /// </summary>
        field(1280; "Check Transmitted"; Boolean)
        {
            Caption = 'Check Transmitted';
            ToolTip = 'Specifies to check transmitted before posting the Payment Journal';
        }
        /// <summary>
        /// Mobile phone number for SMS notifications and two-factor authentication.
        /// </summary>
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Mobile Phone No.") do
                    if Char.IsLetter("Mobile Phone No."[i]) then
                        FieldError("Mobile Phone No.", PhoneNoCannotContainLettersErr);
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Bank Acc. Posting Group")
        {
        }
        key(Key4; "Currency Code")
        {
        }
        key(Key5; "Country/Region Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Bank Account No.", "Currency Code")
        {
        }
        fieldgroup(Brick; "No.", Name, "Bank Account No.", "Currency Code", Image)
        {
        }
    }

    trigger OnDelete()
    begin
        CheckDeleteBalancingBankAccount();

        MoveEntries.MoveBankAccEntries(Rec);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Bank Account");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        UpdateContFromBank.OnDelete(Rec);

        DimMgt.DeleteDefaultDim(DATABASE::"Bank Account", "No.");
    end;

    trigger OnInsert()
    var
        BankAccount: Record "Bank Account";
    begin
        if "No." = '' then begin
            GLSetup.Get();
            GLSetup.TestField("Bank Account Nos.");
            if NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := GLSetup."Bank Account Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
            BankAccount.ReadIsolation(IsolationLevel::ReadUncommitted);
            BankAccount.SetLoadFields("No.");
            while BankAccount.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;

        if not InsertFromContact then
            UpdateContFromBank.OnInsert(Rec);

        DimMgt.UpdateDefaultDim(
          DATABASE::"Bank Account", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        if IsContactUpdateNeeded() then begin
            Modify();
            UpdateContFromBank.OnModify(Rec);
            if not Find() then begin
                Reset();
                if Find() then;
            end;
        end;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Bank Account", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Bank Account", xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CommentLine: Record "Comment Line";
        PostCode: Record "Post Code";
        NoSeries: Codeunit "No. Series";
        MoveEntries: Codeunit MoveEntries;
        UpdateContFromBank: Codeunit "BankCont-Update";
        DimMgt: Codeunit DimensionManagement;
        InsertFromContact: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot change %1 because there are one or more open ledger entries for this bank account.';
        Text003: Label 'Do you wish to create a contact for %1 %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a %1 or an %2.';
#pragma warning restore AA0470
        InvalidPercentageValueErr: Label 'If %1 is %2, then the value must be between 0 and 99.', Comment = '%1 is "field caption and %2 is "Percentage"';
        InvalidValueErr: Label 'The value must be positive.';
        DataExchNotSetErr: Label 'The Data Exchange Code field must be filled.';
        BankStmtScheduledDownloadDescTxt: Label '%1 Bank Statement Import', Comment = '%1 - Bank Account name';
        JobQEntriesCreatedQst: Label 'A job queue entry for import of bank statements has been created.\\Do you want to open the Job Queue Entry window?';
        TransactionImportTimespanMustBePositiveErr: Label 'The value in the Number of Days Included field must be a positive number not greater than 9999.';
        MFANotSupportedErr: Label 'Cannot setup automatic bank statement import because the selected bank requires multi-factor authentication.';
        BankAccNotLinkedErr: Label 'This bank account is not linked to an online bank account.';
        AutoLogonNotPossibleErr: Label 'Automatic logon is not possible for this bank account.';
        CancelTxt: Label 'Cancel';
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';
        OnlineFeedStatementStatus: Option "Not Linked",Linked,"Linked and Auto. Bank Statement Enabled";
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = caption of field (Last Payment Statement No.)';
        CannotDeleteBalancingBankAccountErr: Label 'You cannot delete bank account that is used as balancing account in the Payment Registration Setup.', Locked = true;
        ConfirmDeleteBalancingBankAccountQst: Label 'This bank account is used as balancing account on the Payment Registration Setup page.\\Are you sure you want to delete it?';
        DisablingMakesBankRecAutomatchSlowerWarnMsg: Label 'Disabling the optimization will make automatic bank matching slower, but it will be more precise. It is useful to disable the optimization if you have several open bank ledger entries with the same amount and posting date that you need to automatch. Do you want to turn off the optimization?';

    /// <summary>
    /// Provides interactive number series selection for bank account creation.
    /// </summary>
    /// <param name="OldBankAcc">Previous bank account record for comparison</param>
    /// <returns>True if number was successfully assigned</returns>
    procedure AssistEdit(OldBankAcc: Record "Bank Account"): Boolean
    var
        DefaultSelectedNoSeries: Code[20];
    begin
        GLSetup.Get();
        GLSetup.TestField("Bank Account Nos.");
        if "No. Series" <> '' then
            DefaultSelectedNoSeries := "No. Series"
        else
            DefaultSelectedNoSeries := OldBankAcc."No. Series";

        if NoSeries.LookupRelatedNoSeries(GLSetup."Bank Account Nos.", DefaultSelectedNoSeries, "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    /// <summary>
    /// Validates and updates shortcut dimension codes with proper dimension validation.
    /// </summary>
    /// <param name="FieldNumber">Dimension field number (1 or 2)</param>
    /// <param name="ShortcutDimCode">Dimension code to validate</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Bank Account", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowContact()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
    begin
        if "No." = '' then
            exit;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
        ContBusRel.SetRange("No.", "No.");
        if not ContBusRel.FindFirst() then begin
            if not Confirm(Text003, false, TableCaption(), "No.") then
                exit;
            UpdateContFromBank.InsertNewContact(Rec, false);
            ContBusRel.FindFirst();
        end;
        Commit();

        Cont.FilterGroup(2);
        Cont.SetCurrentKey("Company Name", "Company No.", Type, Name);
        Cont.SetRange("Company No.", ContBusRel."Contact No.");
        RunContactListPage(Cont);
    end;

    /// <summary>
    /// Sets flag indicating if bank account was created from contact information.
    /// </summary>
    /// <param name="FromContact">True if created from contact</param>
    procedure SetInsertFromContact(FromContact: Boolean)
    begin
        InsertFromContact := FromContact;
    end;

    /// <summary>
    /// Copies bank-related fields from company information to bank account.
    /// </summary>
    /// <param name="CompanyInformation">Source company information record</param>
    procedure CopyBankFieldsFromCompanyInfo(CompanyInformation: Record "Company Information")
    begin
        "Bank Account No." := CompanyInformation."Bank Account No.";
        "Bank Branch No." := CompanyInformation."Bank Branch No.";
        Name := CompanyInformation."Bank Name";
        IBAN := CompanyInformation.IBAN;
        "SWIFT Code" := CompanyInformation."SWIFT Code";
        OnAfterCopyBankFieldsFromCompanyInfo(Rec, CompanyInformation);
    end;

    /// <summary>
    /// Retrieves the codeunit ID for payment export processing.
    /// </summary>
    /// <returns>Codeunit ID for payment export</returns>
    procedure GetPaymentExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetBankExportImportSetup(BankExportImportSetup);
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    /// <summary>
    /// Retrieves the XMLPort ID for payment export file generation.
    /// </summary>
    /// <returns>XMLPort ID for payment export</returns>
    procedure GetPaymentExportXMLPortID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetBankExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing XMLport ID");
        exit(BankExportImportSetup."Processing XMLport ID");
    end;

    procedure GetDDExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetDDExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing Codeunit ID");
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure GetDDExportXMLPortID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetDDExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing XMLport ID");
        exit(BankExportImportSetup."Processing XMLport ID");
    end;

    procedure GetBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBankExportImportSetup(BankExportImportSetup, IsHandled);
        if IsHandled then
            exit;
        TestField("Payment Export Format");
        BankExportImportSetup.Get("Payment Export Format");
    end;

    procedure GetDDExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
        TestField("SEPA Direct Debit Exp. Format");
        BankExportImportSetup.Get("SEPA Direct Debit Exp. Format");
    end;

    procedure GetCreditTransferMessageNo(): Code[20]
    var
        CreditTransferMsgNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetCreditTransferMessageNo(CreditTransferMsgNo, IsHandled);
        if IsHandled then
            exit(CreditTransferMsgNo);

        TestField("Credit Transfer Msg. Nos.");
        exit(NoSeries.GetNextNo("Credit Transfer Msg. Nos.", Today()));
    end;

    /// <summary>
    /// Generates and returns the next direct debit message number from the number series.
    /// </summary>
    /// <returns>Next direct debit message number</returns>
    procedure GetDirectDebitMessageNo(): Code[20]
    var
        DirectDebitMsgNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetDirectDebitMessageNo(DirectDebitMsgNo, IsHandled);
        if IsHandled then
            exit(DirectDebitMsgNo);

        TestField("Direct Debit Msg. Nos.");
        exit(NoSeries.GetNextNo("Direct Debit Msg. Nos.", Today()));
    end;

    /// <summary>
    /// Finds the default bank account for a specific currency.
    /// </summary>
    /// <param name="CurrencyCode">Currency code to find default bank account for</param>
    /// <returns>Bank account number designated as default for the currency</returns>
    procedure GetDefaultBankAccountNoForCurrency(CurrencyCode: Code[20]) BankAccountNo: Code[20]
    begin
        SetLoadFields("Currency Code", "Use as Default for Currency");
        SetRange("Currency Code", CurrencyCode);
        SetRange("Use as Default for Currency", true);
        if FindFirst() then;
        exit("No.");
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Bank Account", GetPosition());
    end;

    procedure GetDataExchDef(var DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDefCodeResponse: Code[20];
        Handled: Boolean;
    begin
        OnGetDataExchangeDefinitionEvent(DataExchDefCodeResponse, Handled);
        if not Handled then begin
            TestField("Bank Statement Import Format");
            DataExchDefCodeResponse := "Bank Statement Import Format";
        end;

        if DataExchDefCodeResponse = '' then
            Error(DataExchNotSetErr);

        BankExportImportSetup.Get(DataExchDefCodeResponse);
        BankExportImportSetup.TestField("Data Exch. Def. Code");

        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.TestField(Type, DataExchDef.Type::"Bank Statement Import");
    end;

    procedure GetDataExchDefPaymentExport(var DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        TestField("Payment Export Format");
        BankExportImportSetup.Get("Payment Export Format");
        BankExportImportSetup.TestField("Data Exch. Def. Code");
        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.TestField(Type, DataExchDef.Type::"Payment Export");
    end;

    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo();
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr, FieldCaption("Bank Account No."), FieldCaption(IBAN));
    end;

    procedure GetBankAccountNo(): Text
    var
        Handled: Boolean;
        ResultBankAccountNo: Text;
    begin
        OnGetBankAccount(Handled, Rec, ResultBankAccountNo);

        if Handled then exit(ResultBankAccountNo);

        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    procedure IsInLocalCurrency(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInLocalCurrency(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Currency Code" = '' then
            exit(true);

        GeneralLedgerSetup.Get();
        exit("Currency Code" = GeneralLedgerSetup.GetCurrencyCode(''));
    end;

    procedure GetPosPayExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        TestField("Positive Pay Export Code");
        BankExportImportSetup.Get("Positive Pay Export Code");
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure IsLinkedToBankStatementServiceProvider(): Boolean
    var
        IsBankAccountLinked: Boolean;
    begin
        OnCheckLinkedToStatementProviderEvent(Rec, IsBankAccountLinked);
        exit(IsBankAccountLinked);
    end;

    procedure StatementProvidersExist(): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);
        exit(not TempNameValueBuffer.IsEmpty);
    end;

    procedure LinkStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnLinkStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure SimpleLinkStatementProvider(var OnlineBankAccLink: Record "Online Bank Acc. Link")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnSimpleLinkStatementProviderEvent(OnlineBankAccLink, StatementProvider);
    end;

    procedure UnlinkStatementProvider()
    var
        Handled: Boolean;
    begin
        OnUnlinkStatementProviderEvent(Rec, Handled);
    end;

    procedure RefreshStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnRefreshStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure RenewAccessConsentStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnRenewAccessConsentStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure EditAccountStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnEditAccountStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure UpdateBankAccountLinking()
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnUpdateBankAccountLinkingEvent(Rec, StatementProvider);
    end;

    procedure GetUnlinkedBankAccounts(var TempUnlinkedBankAccount: Record "Bank Account" temporary)
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.FindSet() then
            repeat
                if not BankAccount.IsLinkedToBankStatementServiceProvider() then begin
                    TempUnlinkedBankAccount := BankAccount;
                    TempUnlinkedBankAccount.Insert();
                end;
            until BankAccount.Next() = 0;
    end;

    procedure GetLinkedBankAccounts(var TempUnlinkedBankAccount: Record "Bank Account" temporary)
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.FindSet() then
            repeat
                if BankAccount.IsLinkedToBankStatementServiceProvider() then begin
                    TempUnlinkedBankAccount := BankAccount;
                    TempUnlinkedBankAccount.Insert();
                end;
            until BankAccount.Next() = 0;
    end;

    local procedure EnsureUniqueForCurrency()
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetLoadFields("Currency Code", "Use as Default for Currency");
        BankAccount.SetRange("Currency Code", "Currency Code");
        BankAccount.SetFilter("No.", '<>%1', "No.");
        BankAccount.SetRange("Use as Default for Currency", true);
        if BankAccount.FindFirst() then
            BankAccount.TestField("Use as Default for Currency", false);
    end;

    local procedure SelectBankLinkingService(): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        OptionStr: Text;
        OptionNo: Integer;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);

        if TempNameValueBuffer.IsEmpty() then
            exit(''); // Action should not be visible in this case so should not occur

        if (TempNameValueBuffer.Count = 1) or (not GuiAllowed) then
            exit(TempNameValueBuffer.Name);

        TempNameValueBuffer.FindSet();
        repeat
            OptionStr += StrSubstNo('%1,', TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next() = 0;
        OptionStr += CancelTxt;

        OptionNo := StrMenu(OptionStr);
        if (OptionNo = 0) or (OptionNo = TempNameValueBuffer.Count + 1) then
            exit;

        TempNameValueBuffer.SetRange(Value, SelectStr(OptionNo, OptionStr));
        TempNameValueBuffer.FindFirst();

        exit(TempNameValueBuffer.Name);
    end;

    procedure IsAutoLogonPossible(): Boolean
    var
        AutoLogonPossible: Boolean;
    begin
        AutoLogonPossible := true;
        OnCheckAutoLogonPossibleEvent(Rec, AutoLogonPossible);
        exit(AutoLogonPossible)
    end;

    local procedure ScheduleBankStatementDownload()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsLinkedToBankStatementServiceProvider() then
            Error(BankAccNotLinkedErr);
        if not IsAutoLogonPossible() then
            Error(AutoLogonNotPossibleErr);

        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Automatic Import of Bank Stmt.", RecordId);
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(BankStmtScheduledDownloadDescTxt, Name), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Notify On Success" := false;
        JobQueueEntry."No. of Minutes between Runs" := 121;
        JobQueueEntry."Maximum No. of Attempts to Run" := 4;
        JobQueueEntry."Rerun Delay (sec.)" := 25 * 60;
        JobQueueEntry.Modify();
        if Confirm(JobQEntriesCreatedQst) then
            ShowBankStatementDownloadJobQueueEntry();
    end;

    local procedure UnscheduleBankStatementDownload()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetAutomaticImportJobQueueEntryFilters(JobQueueEntry);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll();
    end;

    procedure CreateNewAccount(OnlineBankAccLink: Record "Online Bank Acc. Link")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        GeneralLedgerSetup.Get();
        Init();
        Validate("Bank Account No.", OnlineBankAccLink."Bank Account No.");
        Validate(Name, OnlineBankAccLink.Name);
        if OnlineBankAccLink."Currency Code" <> '' then
            CurrencyCode := GeneralLedgerSetup.GetCurrencyCode(OnlineBankAccLink."Currency Code");
        Validate("Currency Code", CurrencyCode);
        Validate(Contact, OnlineBankAccLink.Contact);
    end;

    local procedure ShowBankStatementDownloadJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetAutomaticImportJobQueueEntryFilters(JobQueueEntry);
        if JobQueueEntry.FindFirst() then
            PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
    end;

    local procedure SetAutomaticImportJobQueueEntryFilters(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Automatic Import of Bank Stmt.");
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
    end;

    local procedure CheckDeleteBalancingBankAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.SetRange("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        PaymentRegistrationSetup.SetRange("Bal. Account No.", "No.");
        if PaymentRegistrationSetup.IsEmpty() then
            exit;

        if not GuiAllowed then
            Error(CannotDeleteBalancingBankAccountErr);

        if not Confirm(ConfirmDeleteBalancingBankAccountQst) then
            Error('');
    end;

    procedure GetOnlineFeedStatementStatus(var OnlineFeedStatus: Option; var Linked: Boolean)
    begin
        Linked := false;
        OnlineFeedStatus := OnlineFeedStatementStatus::"Not Linked";
        if IsLinkedToBankStatementServiceProvider() then begin
            Linked := true;
            OnlineFeedStatus := OnlineFeedStatementStatus::Linked;
            if IsScheduledBankStatement() then
                OnlineFeedStatus := OnlineFeedStatementStatus::"Linked and Auto. Bank Statement Enabled";
        end;
    end;

    local procedure IsScheduledBankStatement(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        exit(JobQueueEntry.FindFirst());
    end;

    procedure DisableStatementProviders()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);
        if TempNameValueBuffer.FindSet() then
            repeat
                OnDisableStatementProviderEvent(TempNameValueBuffer.Name);
            until TempNameValueBuffer.Next() = 0;
    end;

    local procedure IsContactUpdateNeeded(): Boolean
    var
        BankContUpdate: Codeunit "BankCont-Update";
        UpdateNeeded: Boolean;
    begin
        UpdateNeeded :=
          (Name <> xRec.Name) or
          ("Search Name" <> xRec."Search Name") or
          ("Name 2" <> xRec."Name 2") or
          (Address <> xRec.Address) or
          ("Address 2" <> xRec."Address 2") or
          (City <> xRec.City) or
          ("Phone No." <> xRec."Phone No.") or
          ("Mobile Phone No." <> xRec."Mobile Phone No.") or
          ("Telex No." <> xRec."Telex No.") or
          ("Territory Code" <> xRec."Territory Code") or
          ("Currency Code" <> xRec."Currency Code") or
          ("Language Code" <> xRec."Language Code") or
          ("Format Region" <> xRec."Format Region") or
          ("Our Contact Code" <> xRec."Our Contact Code") or
          ("Country/Region Code" <> xRec."Country/Region Code") or
          ("Fax No." <> xRec."Fax No.") or
          ("Telex Answer Back" <> xRec."Telex Answer Back") or
          ("Post Code" <> xRec."Post Code") or
          (County <> xRec.County) or
          ("E-Mail" <> xRec."E-Mail") or
          ("Home Page" <> xRec."Home Page");

        if not UpdateNeeded and not IsTemporary then
            UpdateNeeded := BankContUpdate.ContactNameIsBlank("No.");

        OnAfterIsUpdateNeeded(xRec, Rec, UpdateNeeded);
        exit(UpdateNeeded);
    end;

    local procedure RunContactListPage(var Contact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunContactListPage(Contact, IsHandled);
        if IsHandled then
            exit;

        Page.Run(Page::"Contact List", Contact);
    end;

    /// <summary>
    /// Integration event raised after determining if bank account update is needed.
    /// Enables custom logic for evaluating when bank account updates are required.
    /// </summary>
    /// <param name="BankAccount">Current bank account record</param>
    /// <param name="xBankAccount">Previous bank account record state</param>
    /// <param name="UpdateNeeded">Whether update is needed (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised after standard update evaluation logic in bank account validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsUpdateNeeded(BankAccount: Record "Bank Account"; xBankAccount: Record "Bank Account"; var UpdateNeeded: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after copying bank-related fields from company information.
    /// Enables custom field mapping or additional processing during bank account initialization.
    /// </summary>
    /// <param name="BankAccount">Bank account record being updated</param>
    /// <param name="CompanyInformation">Source company information record</param>
    /// <remarks>
    /// Raised from CopyBankFieldsFromCompanyInfo procedure after standard field copying.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBankFieldsFromCompanyInfo(var BankAccount: Record "Bank Account"; CompanyInformation: Record "Company Information")
    begin
    end;

    /// <summary>
    /// Integration event raised after validating a shortcut dimension code for bank account.
    /// Enables custom processing or additional validation after dimension code validation.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated</param>
    /// <param name="xBankAccount">Previous bank account record state</param>
    /// <param name="FieldNumber">Field number of the dimension being validated</param>
    /// <param name="ShortcutDimCode">Dimension code that was validated</param>
    /// <remarks>
    /// Raised from ValidateShortcutDimCode procedure after standard dimension validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before validating IBAN format and check digits.
    /// Enables custom IBAN validation logic or handling of special IBAN formats.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated</param>
    /// <param name="xBankAccount">Previous bank account record state</param>
    /// <param name="IsHandled">Set to true to skip standard IBAN validation</param>
    /// <remarks>
    /// Raised from IBAN validation trigger before standard format checking.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIBAN(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating a shortcut dimension code for bank account.
    /// Enables custom dimension validation logic or preprocessing before standard validation.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated</param>
    /// <param name="xBankAccount">Previous bank account record state</param>
    /// <param name="FieldNumber">Field number of the dimension being validated</param>
    /// <param name="ShortcutDimCode">Dimension code being validated</param>
    /// <remarks>
    /// Raised from ValidateShortcutDimCode procedure before standard dimension validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event for checking if bank account is linked to a statement provider service.
    /// Enables bank statement provider integrations to indicate connection status.
    /// </summary>
    /// <param name="BankAccount">Bank account being checked for provider linkage</param>
    /// <param name="IsLinked">Whether the account is linked to a statement provider (set by subscribers)</param>
    /// <remarks>
    /// Raised when determining bank account integration status with external statement providers.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCheckLinkedToStatementProviderEvent(var BankAccount: Record "Bank Account"; var IsLinked: Boolean)
    begin
        // The subscriber of this event should answer whether the bank account is linked to a bank statement provider service
    end;

    /// <summary>
    /// Integration event for checking if automatic logon is possible for the bank account.
    /// Enables bank statement provider integrations to indicate authentication capabilities.
    /// </summary>
    /// <param name="BankAccount">Bank account being checked for auto-logon capability</param>
    /// <param name="AutoLogonPossible">Whether auto-logon is possible (set by subscribers)</param>
    /// <remarks>
    /// Raised when determining if bank account can authenticate without multi-factor authentication.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCheckAutoLogonPossibleEvent(var BankAccount: Record "Bank Account"; var AutoLogonPossible: Boolean)
    begin
        // The subscriber of this event should answer whether the bank account can be logged on to without multi-factor authentication
    end;

    /// <summary>
    /// Integration event for unlinking bank account from statement provider service.
    /// Enables bank statement provider integrations to handle connection removal.
    /// </summary>
    /// <param name="BankAccount">Bank account being unlinked from statement provider</param>
    /// <param name="Handled">Set to true if the unlinking was handled by subscriber</param>
    /// <remarks>
    /// Raised when disconnecting bank account from external statement provider services.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUnlinkStatementProviderEvent(var BankAccount: Record "Bank Account"; var Handled: Boolean)
    begin
        // The subscriber of this event should unlink the bank account from a bank statement provider service
    end;

    /// <summary>
    /// Integration event for marking bank account as linked to statement provider service.
    /// Enables bank statement provider integrations to update linkage status.
    /// </summary>
    /// <param name="OnlineBankAccLink">Online bank account link record being processed</param>
    /// <param name="BankAccount">Bank account being marked as linked</param>
    /// <remarks>
    /// Raised when establishing connection between bank account and external statement provider.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnMarkAccountLinkedEvent(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var BankAccount: Record "Bank Account")
    begin
        // The subscriber of this event should Mark the account linked to a bank statement provider service
    end;

    /// <summary>
    /// Integration event for simple linking of bank account to statement provider.
    /// Enables streamlined connection setup with basic provider information.
    /// </summary>
    /// <param name="OnlineBankAccLink">Online bank account link record for the connection</param>
    /// <param name="StatementProvider">Name/identifier of the statement provider service</param>
    /// <remarks>
    /// Raised during simplified bank account linking workflow for statement providers.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnSimpleLinkStatementProviderEvent(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var StatementProvider: Text)
    begin
        // The subscriber of this event should link the bank account to a bank statement provider service
    end;

    /// <summary>
    /// Integration event for linking bank account to statement provider service.
    /// Enables bank statement provider integrations to establish account connections.
    /// </summary>
    /// <param name="BankAccount">Bank account being linked to statement provider</param>
    /// <param name="StatementProvider">Name/identifier of the statement provider service</param>
    /// <remarks>
    /// Raised when connecting bank account to external statement provider services.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnLinkStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should link the bank account to a bank statement provider service
    end;

    /// <summary>
    /// Integration event for refreshing bank account connection to statement provider.
    /// Enables renewal of authentication or data synchronization with provider services.
    /// </summary>
    /// <param name="BankAccount">Bank account connection to be refreshed</param>
    /// <param name="StatementProvider">Name/identifier of the statement provider service</param>
    /// <remarks>
    /// Raised when updating or renewing connection between bank account and statement provider.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnRefreshStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should refresh the bank account linked to a bank statement provider service
    end;

    /// <summary>
    /// Integration event for retrieving data exchange definition for online bank feeds.
    /// Enables dynamic configuration of data format for processing bank statement imports.
    /// </summary>
    /// <param name="DataExchDefCodeResponse">Data exchange definition code (set by subscriber)</param>
    /// <param name="Handled">Set to true if definition was provided by subscriber</param>
    /// <remarks>
    /// Raised when determining data format configuration for online bank statement processing.
    /// </remarks>
    [IntegrationEvent(true, false)]
    local procedure OnGetDataExchangeDefinitionEvent(var DataExchDefCodeResponse: Code[20]; var Handled: Boolean)
    begin
        // This event should retrieve the data exchange definition format for processing the online feeds
    end;

    /// <summary>
    /// Integration event for updating bank account linking information.
    /// Enables maintenance of connection details between bank accounts and statement providers.
    /// </summary>
    /// <param name="BankAccount">Bank account with linking information to update</param>
    /// <param name="StatementProvider">Name/identifier of the statement provider service</param>
    /// <remarks>
    /// Raised when updating connection metadata for single or multiple bank account links.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankAccountLinkingEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // This event should handle updating of the single or multiple bank accounts
    end;

    /// <summary>
    /// Integration event for retrieving available statement provider services.
    /// Enables discovery of available bank statement provider integrations.
    /// </summary>
    /// <param name="TempNameValueBuffer">Buffer for provider identifiers and display names (populated by subscribers)</param>
    /// <remarks>
    /// Raised when building list of available statement provider services for user selection.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnGetStatementProvidersEvent(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        // The subscriber of this event should insert a unique identifier (Name) and friendly name of the provider (Value)
    end;

    /// <summary>
    /// Integration event for disabling a statement provider service.
    /// Enables deactivation or removal of statement provider integrations.
    /// </summary>
    /// <param name="ProviderName">Name/identifier of the statement provider to disable</param>
    /// <remarks>
    /// Raised when deactivating statement provider services system-wide.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnDisableStatementProviderEvent(ProviderName: Text)
    begin
        // The subscriber of this event should disable the statement provider with the given name
    end;

    /// <summary>
    /// Integration event for renewing access consent for statement provider.
    /// Enables re-authorization workflow for open banking and similar integrations.
    /// </summary>
    /// <param name="BankAccount">Bank account requiring consent renewal</param>
    /// <param name="StatementProvider">Name/identifier of the statement provider service</param>
    /// <remarks>
    /// Raised when bank account access permissions need to be renewed with external provider.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnRenewAccessConsentStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should provide the UI for renewing access consent to the linked open banking bank account
    end;

    /// <summary>
    /// Integration event for editing online bank account information.
    /// Enables customization of bank account details editing interface.
    /// </summary>
    /// <param name="BankAccount">Bank account information to be edited</param>
    /// <param name="StatementProvider">Name/identifier of the statement provider service</param>
    /// <remarks>
    /// Raised when providing user interface for editing online bank account connection details.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnEditAccountStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should provide the UI for editing the information about the online bank account
    end;

    /// <summary>
    /// Integration event raised before opening the contact list page.
    /// Enables custom contact list handling or alternative contact selection interface.
    /// </summary>
    /// <param name="Contact">Contact record for the contact list display</param>
    /// <param name="IsHandled">Set to true to skip standard contact list page opening</param>
    /// <remarks>
    /// Raised before displaying contact list page for bank account contact selection.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunContactListPage(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event for validating bank account information.
    /// Enables custom validation logic for specific bank account fields or data.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated</param>
    /// <param name="FieldToValidate">Name/identifier of the field being validated</param>
    /// <remarks>
    /// Raised during bank account validation workflows for extensible field validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBankAccount(var BankAccount: Record "Bank Account"; FieldToValidate: Text)
    begin
    end;

    /// <summary>
    /// Integration event for retrieving bank account information.
    /// Enables custom bank account lookup or data retrieval logic.
    /// </summary>
    /// <param name="Handled">Set to true if bank account retrieval was handled by subscriber</param>
    /// <param name="BankAccount">Input bank account record for lookup context</param>
    /// <param name="ResultBankAccountNo">Bank account number result (set by subscriber)</param>
    /// <remarks>
    /// Raised when performing bank account data lookup or retrieval operations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnGetBankAccount(var Handled: Boolean; BankAccount: Record "Bank Account"; var ResultBankAccountNo: Text)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating city field on bank account.
    /// Enables custom city validation logic with postal code integration.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated</param>
    /// <param name="PostCode">Post code record for city validation context</param>
    /// <param name="CurrentFieldNo">Field number triggering the validation</param>
    /// <param name="IsHandled">Set to true to skip standard city validation</param>
    /// <remarks>
    /// Raised from city field validation trigger before standard postal code validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var BankAccount: Record "Bank Account"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before validating postal code field on bank account.
    /// Enables custom postal code validation logic with city integration.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated</param>
    /// <param name="PostCode">Post code record for postal code validation context</param>
    /// <param name="CurrentFieldNo">Field number triggering the validation</param>
    /// <param name="IsHandled">Set to true to skip standard postal code validation</param>
    /// <remarks>
    /// Raised from postal code field validation trigger before standard city validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var BankAccount: Record "Bank Account"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving credit transfer message number.
    /// Enables custom logic for generating or determining credit transfer message identifiers.
    /// </summary>
    /// <param name="CreditTransferMsgNo">Credit transfer message number (can be set by subscriber)</param>
    /// <param name="IsHandled">Set to true if message number was provided by subscriber</param>
    /// <remarks>
    /// Raised when generating unique message identifiers for credit transfer operations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCreditTransferMessageNo(var CreditTransferMsgNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving direct debit message number.
    /// Enables custom logic for generating or determining direct debit message identifiers.
    /// </summary>
    /// <param name="DirectDebitMsgNo">Direct debit message number (can be set by subscriber)</param>
    /// <param name="IsHandled">Set to true if message number was provided by subscriber</param>
    /// <remarks>
    /// Raised when generating unique message identifiers for direct debit operations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectDebitMessageNo(var DirectDebitMsgNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised during currency code validation before testing balance fields.
    /// Enables custom validation logic before standard balance field testing.
    /// </summary>
    /// <param name="BankAccount">Bank account record being validated for currency change</param>
    /// <remarks>
    /// Raised from currency code validation trigger before checking balance-related field consistency.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyCodeOnBeforeTestBalanceFields(var BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeGetBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; var IsHandled: Boolean)
    begin
    end;


    /// <summary>
    /// Integration event raised before determining if bank account is in local currency.
    /// Enables custom logic for determining local currency status.
    /// </summary>
    /// <param name="Rec">Bank account record being checked</param>
    /// <param name="Result">Result value to return (if handled)</param>
    /// <param name="IsHandled">Set to true if event is handled by subscriber</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInLocalCurrency(var Rec: Record "Bank Account"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}