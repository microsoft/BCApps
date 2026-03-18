// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Environment;
using System.IO;
using System.Security.User;
using System.Telemetry;
using System.Threading;

/// <summary>
/// Core financial system configuration table controlling posting permissions, currency settings, VAT handling, and dimension management.
/// Manages global financial parameters including rounding precision, job queue integration, and additional reporting currency setup.
/// </summary>
/// <remarks>
/// Singleton table providing system-wide GL configuration. Key integrations: Currency, VAT, Dimensions, Job Queue.
/// Extensibility: OnAfterAdjustAddReportingCurrency, OnAfterValidateShortcutDimCode events available.
/// Critical setup affecting all financial transactions and reporting throughout Business Central.
/// </remarks>
table 98 "General Ledger Setup"
{
    Caption = 'General Ledger Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for the singleton General Ledger Setup record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Earliest date allowed for posting transactions to the general ledger.
        /// </summary>
        field(2; "Allow Posting From"; Date)
        {
            Caption = 'Allow Posting From';
            ToolTip = 'Specifies the earliest date on which posting to the company books is allowed.';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);

                if xRec."Allow Posting From" <> Rec."Allow Posting From" then begin
                    if Rec."Allow Posting From" <> 0D then
                        Evaluate(Rec."Allow Posting From DateFormula", '');

                    CheckDateRange();
                end;
            end;
        }
        /// <summary>
        /// Latest date allowed for posting transactions to the general ledger.
        /// </summary>
        field(3; "Allow Posting To"; Date)
        {
            Caption = 'Allow Posting To';
            ToolTip = 'Specifies the last date on which posting to the company books is allowed.';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);

                if xRec."Allow Posting To" <> Rec."Allow Posting To" then begin
                    if Rec."Allow Posting To" <> 0D then
                        Evaluate(Rec."Allow Posting To DateFormula", '');

                    CheckDateRange();
                end;
            end;
        }
        /// <summary>
        /// Records posting time in addition to posting date for audit trail and transaction tracking.
        /// </summary>
        field(4; "Register Time"; Boolean)
        {
            Caption = 'Register Time';
            ToolTip = 'Specifies whether to register users'' time usage defined as the time spent from when a user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded. This setting can be overruled per user by filling in the Register Time field in the User Setup window.';
        }
        /// <summary>
        /// Earliest date allowed for posting deferral transactions to the general ledger.
        /// </summary>
        field(5; "Allow Deferral Posting From"; Date)
        {
            Caption = 'Allow Deferral Posting From';
            ToolTip = 'Specifies the earliest date on which deferral posting to the company books is allowed.';

            trigger OnValidate()
            begin
                CheckAllowedDeferralPostingDates(0);
            end;
        }
        /// <summary>
        /// Latest date allowed for posting deferral transactions to the general ledger.
        /// </summary>
        field(6; "Allow Deferral Posting To"; Date)
        {
            Caption = 'Allow Deferral Posting To';
            ToolTip = 'Specifies the last date on which deferral posting to the company books is allowed.';

            trigger OnValidate()
            begin
                CheckAllowedDeferralPostingDates(0);
            end;
        }
        /// <summary>
        /// Default VAT reporting date calculation method used when posting transactions with VAT.
        /// </summary>
        field(7; "VAT Reporting Date"; Enum "VAT Reporting Date")
        {
            Caption = 'Default VAT Date';
            ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on this setting.';
        }
        /// <summary>
        /// Controls whether VAT reporting date is enabled, disabled, or controlled by posting date.
        /// </summary>
        field(8; "VAT Reporting Date Usage"; Enum "VAT Reporting Date Usage")
        {
            Caption = 'VAT Date Usage';
            ToolTip = 'Specifies the usage of VAT date.';

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUsage('0000J2U', VATDateFeatureTok, VATDateFeatureUsageMsg);
            end;
        }
        /// <summary>
        /// Calculates payment discounts excluding VAT amounts to reduce VAT-related rounding differences.
        /// </summary>
        field(28; "Pmt. Disc. Excl. VAT"; Boolean)
        {
            Caption = 'Pmt. Disc. Excl. VAT';
            ToolTip = 'Specifies if the payment discount is calculated based on amounts including or excluding VAT.';

            trigger OnValidate()
            begin
                if "Pmt. Disc. Excl. VAT" then
                    TestField("Adjust for Payment Disc.", false)
                else
                    TestField("VAT Tolerance %", 0);
            end;
        }
        /// <summary>
        /// Flow filter field for date-based filtering in related tables and reports.
        /// </summary>
        field(41; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Flow filter field for filtering by the first global dimension.
        /// </summary>
        field(42; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Global Dimension 1 Code"));
        }
        /// <summary>
        /// Flow filter field for filtering by the second global dimension.
        /// </summary>
        field(43; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Global Dimension 2 Code"));
        }
        /// <summary>
        /// Flow field calculating total customer balances due filtered by dimensions and date.
        /// </summary>
        field(44; "Cust. Balances Due"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                 "Initial Entry Due Date" = field("Date Filter")));
            Caption = 'Cust. Balances Due';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Flow field calculating total vendor balances due filtered by dimensions and date.
        /// </summary>
        field(45; "Vendor Balances Due"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Initial Entry Due Date" = field("Date Filter")));
            Caption = 'Vendor Balances Due';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Enables unrealized VAT functionality for accounting systems using cash-based VAT reporting.
        /// </summary>
        field(48; "Unrealized VAT"; Boolean)
        {
            Caption = 'Unrealized VAT';
            ToolTip = 'Specifies whether to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';

            trigger OnValidate()
            begin
                if not "Unrealized VAT" then begin
                    VATPostingSetup.SetFilter(
                      "Unrealized VAT Type", '>=%1', VATPostingSetup."Unrealized VAT Type"::Percentage);
                    if VATPostingSetup.FindFirst() then
                        Error(
                          Text000, VATPostingSetup.TableCaption(),
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Unrealized VAT Type"), VATPostingSetup."Unrealized VAT Type");
                    TaxJurisdiction.SetFilter(
                      "Unrealized VAT Type", '>=%1', TaxJurisdiction."Unrealized VAT Type"::Percentage);
                    if TaxJurisdiction.FindFirst() then
                        Error(
                          Text001, TaxJurisdiction.TableCaption(),
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Unrealized VAT Type"),
                          TaxJurisdiction."Unrealized VAT Type");
                end;
                if "Unrealized VAT" then
                    "Prepayment Unrealized VAT" := true
                else
                    "Prepayment Unrealized VAT" := false;
            end;
        }
        /// <summary>
        /// Automatically adjusts VAT amounts when payment discounts are applied to maintain accurate VAT calculations.
        /// </summary>
        field(49; "Adjust for Payment Disc."; Boolean)
        {
            Caption = 'Adjust for Payment Disc.';
            ToolTip = 'Specifies whether to recalculate tax amounts when you post payments that trigger payment discounts.';

            trigger OnValidate()
            begin
                if "Adjust for Payment Disc." then begin
                    TestField("Pmt. Disc. Excl. VAT", false);
                    TestField("VAT Tolerance %", 0);
                end else begin
                    VATPostingSetup.SetRange("Adjust for Payment Discount", true);
                    if VATPostingSetup.FindFirst() then
                        Error(
                          Text002, VATPostingSetup.TableCaption(),
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Adjust for Payment Discount"));
                    TaxJurisdiction.SetRange("Adjust for Payment Discount", true);
                    if TaxJurisdiction.FindFirst() then
                        Error(
                          Text003, TaxJurisdiction.TableCaption(),
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Adjust for Payment Discount"));
                end;
            end;
        }
        /// <summary>
        /// Enables background posting of documents using the job queue system for improved user experience.
        /// </summary>
        field(50; "Post with Job Queue"; Boolean)
        {
            Caption = 'Post with Job Queue';
            ToolTip = 'Specifies if you use job queues to post general ledger documents in the background.';

            trigger OnValidate()
            begin
                if not "Post with Job Queue" then
                    "Post & Print with Job Queue" := false;
            end;
        }
        /// <summary>
        /// Job queue category code used for organizing posting-related job queue entries.
        /// </summary>
        field(51; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
            TableRelation = "Job Queue Category";
        }
        /// <summary>
        /// Priority level for posting job queue entries to control processing order.
        /// </summary>
        field(52; "Job Queue Priority for Post"; Integer)
        {
            Caption = 'Job Queue Priority for Post';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001);
            end;
        }
        /// <summary>
        /// Enables background posting and printing of documents using the job queue system.
        /// </summary>
        field(53; "Post & Print with Job Queue"; Boolean)
        {
            Caption = 'Post & Print with Job Queue';
            ToolTip = 'Specifies if you use job queues to post and print general ledger documents in the background.';

            trigger OnValidate()
            begin
                if "Post & Print with Job Queue" then
                    "Post with Job Queue" := true;
            end;
        }
        /// <summary>
        /// Priority level for post and print job queue entries to control processing order.
        /// </summary>
        field(54; "Job Q. Prio. for Post & Print"; Integer)
        {
            Caption = 'Job Q. Prio. for Post & Print';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001);
            end;
        }
        /// <summary>
        /// Shows notification messages when background posting operations complete successfully.
        /// </summary>
        field(55; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
            ToolTip = 'Specifies if a notification is sent when posting and printing is successfully completed.';
        }
        /// <summary>
        /// Marks credit memos as corrections for proper VAT and financial reporting compliance.
        /// </summary>
        field(56; "Mark Cr. Memos as Corrections"; Boolean)
        {
            Caption = 'Mark Cr. Memos as Corrections';
            ToolTip = 'Specifies whether to automatically mark a new credit memo as a corrective entry. Correction flag does not affect how inventory reconciled with general ledger.';
        }
        /// <summary>
        /// Format used for displaying local addresses on documents and reports.
        /// </summary>
        field(57; "Local Address Format"; Option)
        {
            Caption = 'Local Address Format';
            ToolTip = 'Specifies the format in which addresses must appear on printouts.';
            OptionCaption = 'Post Code+City,City+Post Code,City+County+Post Code,Blank Line+Post Code+City';
            OptionMembers = "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City";
        }
        /// <summary>
        /// Precision used for invoice rounding calculations in local currency.
        /// </summary>
        field(58; "Inv. Rounding Precision (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Inv. Rounding Precision (LCY)';

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then
                    if "Inv. Rounding Precision (LCY)" <> Round("Inv. Rounding Precision (LCY)", "Amount Rounding Precision") then
                        Error(
                          Text004,
                          FieldCaption("Inv. Rounding Precision (LCY)"), "Amount Rounding Precision");
            end;
        }
        /// <summary>
        /// Method used for invoice rounding calculations in local currency.
        /// </summary>
        field(59; "Inv. Rounding Type (LCY)"; Option)
        {
            Caption = 'Inv. Rounding Type (LCY)';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        /// <summary>
        /// Position of contact address information on documents and communications.
        /// </summary>
        field(60; "Local Cont. Addr. Format"; Option)
        {
            Caption = 'Local Cont. Addr. Format';
            ToolTip = 'Specifies where you want the contact name to appear in mailing addresses.';
            InitValue = "After Company Name";
            OptionCaption = 'First,After Company Name,Last';
            OptionMembers = First,"After Company Name",Last;
        }
        /// <summary>
        /// Default output type for generated reports and documents.
        /// </summary>
        field(61; "Report Output Type"; Enum "Setup Report Output Type")
        {
            Caption = 'Report Output Type';
            ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS() then
                        TestField("Report Output Type", "Report Output Type"::PDF);
            end;
        }
        /// <summary>
        /// Number series used for assigning bank account numbers during bank account creation.
        /// </summary>
        field(63; "Bank Account Nos."; Code[20])
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Account Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bank accounts.';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Combines G/L entries with identical account, posting date, and dimensions into summary entries.
        /// </summary>
        field(65; "Summarize G/L Entries"; Boolean)
        {
            Caption = 'Summarize G/L Entries';
        }
        /// <summary>
        /// Decimal places specification for amount fields display and input formatting.
        /// </summary>
        field(66; "Amount Decimal Places"; Text[5])
        {
            Caption = 'Amount Decimal Places';
            ToolTip = 'Specifies the number of decimal places that are shown for amounts in LCY. This covers amounts created with all types of transactions and is useful to avoid inconsistencies when viewing or summing different amounts. The default setting, 2:2, specifies that all amounts in LCY are shown with a minimum of 2 decimal places and a maximum of 2 decimal places. You can also enter a fixed number, such as 2, which also means that amounts are shown with two decimals. On the Currencies page, you specify how many decimal places to show for amounts in foreign currencies.';
            InitValue = '2:2';

            trigger OnValidate()
            begin
                CheckDecimalPlacesFormat("Amount Decimal Places");
            end;
        }
        /// <summary>
        /// Decimal places specification for unit amount fields display and input formatting.
        /// </summary>
        field(67; "Unit-Amount Decimal Places"; Text[5])
        {
            Caption = 'Unit-Amount Decimal Places';
            ToolTip = 'Specifies the number of decimal places that are shown for unit amounts, item or resource prices per unit, in LCY. The default setting, 2:5, specifies that unit amounts will be shown with a minimum of two decimal places and a maximum of five decimal places. You can also enter a fixed number, such as 2, to specify that all unit amounts are shown with two decimal places. On the Currencies page, you specify how many decimal places to show for unit amounts in foreign currencies.';
            InitValue = '2:5';

            trigger OnValidate()
            begin
                CheckDecimalPlacesFormat("Unit-Amount Decimal Places");
            end;
        }
        /// <summary>
        /// Currency code for additional reporting currency used for parallel accounting and reporting.
        /// </summary>
        field(68; "Additional Reporting Currency"; Code[10])
        {
            Caption = 'Additional Reporting Currency';
            ToolTip = 'Specifies the currency that will be used as an additional reporting currency.';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   ("Additional Reporting Currency" <> '')
                then begin
                    AdjAddReportingCurr.SetAddCurr("Additional Reporting Currency");
                    AdjAddReportingCurr.RunModal();
                    if not AdjAddReportingCurr.IsExecuted() then
                        "Additional Reporting Currency" := xRec."Additional Reporting Currency";
                end;
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   ("Additional Reporting Currency" <> '') and
                   AdjAddReportingCurr.IsExecuted()
                then
                    DeleteAnalysisView();
            end;
        }
        /// <summary>
        /// Tolerance percentage for VAT amount differences to allow minor variances in VAT calculations.
        /// </summary>
        field(69; "VAT Tolerance %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Tolerance %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "VAT Tolerance %" <> 0 then begin
                    TestField("Adjust for Payment Disc.", false);
                    TestField("Pmt. Disc. Excl. VAT", true);
                end;
            end;
        }
        /// <summary>
        /// Indicates whether the local currency participates in European Monetary Union currency system.
        /// </summary>
        field(70; "EMU Currency"; Boolean)
        {
            Caption = 'EMU Currency';
            ToolTip = 'Specifies if LCY is an EMU (Economic and Monetary Union) currency.';
        }
        /// <summary>
        /// Local Currency Code identifying the company's functional currency for accounting and reporting.
        /// </summary>
        field(71; "LCY Code"; Code[10])
        {
            Caption = 'LCY Code';
            ToolTip = 'Specifies the ISO 3 letter currency code for the local currency.';

            trigger OnValidate()
            var
                Currency: Record Currency;
                GLEntry: Record "G/L Entry";
            begin
                if (Rec."LCY Code" <> xRec."LCY Code") and (xRec."LCY Code" <> '') then
                    if not GLEntry.IsEmpty() then
                        Error(CannotUpdateLCYCodeErr);

                if "Local Currency Symbol" = '' then
                    "Local Currency Symbol" := Currency.ResolveCurrencySymbol("LCY Code");

                if "Local Currency Description" = '' then
                    "Local Currency Description" := CopyStr(Currency.ResolveCurrencyDescription("LCY Code"), 1, MaxStrLen("Local Currency Description"));
            end;
        }
        /// <summary>
        /// Method for adjusting VAT amounts during currency exchange rate adjustments.
        /// </summary>
        field(72; "VAT Exchange Rate Adjustment"; Enum "Exch. Rate Adjustment Type")
        {
            Caption = 'VAT Exchange Rate Adjustment';
            ToolTip = 'Specifies how the accounts set up for VAT posting in the VAT Posting Setup window will be adjusted for exchange rate fluctuations.';
        }
        /// <summary>
        /// Precision used for rounding monetary amounts in local currency calculations.
        /// </summary>
        field(73; "Amount Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount Rounding Precision';
            ToolTip = 'Specifies the size of the interval to be used when rounding amounts in LCY. This covers amounts created with all types of transactions and is useful to avoid inconsistencies when viewing or summing different amounts. Amounts will be rounded to the nearest digit. Example: To have amounts rounded to whole numbers, enter 1.00 in this field. In this case, amounts less than 0.5 will be rounded down and amounts greater than or equal to 0.5 will be rounded up. On the Currencies page, you specify how amounts in foreign currencies are rounded.';
            DecimalPlaces = 0 : 5;
            InitValue = 0.01;

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then
                    "Inv. Rounding Precision (LCY)" := Round("Inv. Rounding Precision (LCY)", "Amount Rounding Precision");

                CheckRoundingError(FieldCaption("Amount Rounding Precision"));

                if HideDialog() then
                    Message(Text021);
            end;
        }
        /// <summary>
        /// Precision used for rounding unit amounts in calculations and display.
        /// </summary>
        field(74; "Unit-Amount Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit-Amount Rounding Precision';
            ToolTip = 'Specifies the size of the interval to be used when rounding unit amounts, item or resource prices per unit, in LCY. Amounts will be rounded to the nearest digit. Example: To have unit amounts rounded to whole numbers, enter 1.00 in this field. In this case, amounts less than 0.5 will be rounded down and amounts greater than or equal to 0.5 will be rounded up. On the Currencies page, you specify how unit amounts in foreign currencies are rounded.';
            DecimalPlaces = 0 : 9;
            InitValue = 0.00001;

            trigger OnValidate()
            begin
                if HideDialog() then
                    Message(Text022);
            end;
        }
        /// <summary>
        /// Rounding precision used for payment applications to prevent minor differences from blocking applications.
        /// </summary>
        field(75; "Appln. Rounding Precision"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 0;
            Caption = 'Appln. Rounding Precision';
            ToolTip = 'Specifies the rounding difference that will be allowed when you apply entries in LCY to entries in a different currency.';
            MinValue = 0;
        }
        /// <summary>
        /// Primary global dimension code used throughout the system for analysis and reporting.
        /// </summary>
        field(79; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for a global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            Editable = false;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                "Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            end;
        }
        /// <summary>
        /// Secondary global dimension code used throughout the system for analysis and reporting.
        /// </summary>
        field(80; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for a global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            Editable = false;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                "Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            end;
        }
        /// <summary>
        /// First shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(81; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            Editable = false;
            TableRelation = Dimension;
        }
        /// <summary>
        /// Second shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(82; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            TableRelation = Dimension;
        }
        /// <summary>
        /// Third shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(83; "Shortcut Dimension 3 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 3 Code", "Shortcut Dimension 3 Code", 3);
            end;
        }
        /// <summary>
        /// Fourth shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(84; "Shortcut Dimension 4 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 4 Code", "Shortcut Dimension 4 Code", 4);
            end;
        }
        /// <summary>
        /// Fifth shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(85; "Shortcut Dimension 5 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 5 Code", "Shortcut Dimension 5 Code", 5);
            end;
        }
        /// <summary>
        /// Sixth shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(86; "Shortcut Dimension 6 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 6 Code", "Shortcut Dimension 6 Code", 6);
            end;
        }
        /// <summary>
        /// Seventh shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(87; "Shortcut Dimension 7 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 7 Code", "Shortcut Dimension 7 Code", 7);
            end;
        }
        /// <summary>
        /// Eighth shortcut dimension code for quick access to dimension values in data entry forms.
        /// </summary>
        field(88; "Shortcut Dimension 8 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, whose dimension values you can then enter directly on journals and sales or purchase lines.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 8 Code", "Shortcut Dimension 8 Code", 8);
            end;
        }
        /// <summary>
        /// Maximum allowed VAT difference amount in local currency for VAT entries and adjustments.
        /// </summary>
        field(89; "Max. VAT Difference Allowed"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Max. VAT Difference Allowed';
            ToolTip = 'Specifies the maximum VAT correction amount allowed for the local currency. For example, if you enter 5 in this field for British Pounds, then you can correct VAT amounts by up to five pounds.';

            trigger OnValidate()
            begin
                if "Max. VAT Difference Allowed" <> Round("Max. VAT Difference Allowed") then
                    Error(
                      Text004,
                      FieldCaption("Max. VAT Difference Allowed"), "Amount Rounding Precision");

                "Max. VAT Difference Allowed" := Abs("Max. VAT Difference Allowed");
            end;
        }
        /// <summary>
        /// Rounding method applied to VAT amounts during calculation and posting.
        /// </summary>
        field(90; "VAT Rounding Type"; Option)
        {
            Caption = 'VAT Rounding Type';
            ToolTip = 'Specifies how the program will round VAT when calculated for the local currency. When you enter an Amount Including VAT in a document, the system first calculates and rounds the Amount Excluding VAT, and then calculates by subtraction the VAT Amount because the total amount has to match the Amount Including VAT entered manually. In that case, the VAT Rounding Type does not apply as the Amount Excluding VAT is already rounded using the Amount Rounding Precision.';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        /// <summary>
        /// Specifies which accounts to use when posting payment discount tolerance amounts.
        /// </summary>
        field(92; "Pmt. Disc. Tolerance Posting"; Option)
        {
            Caption = 'Pmt. Disc. Tolerance Posting';
            ToolTip = 'Specifies the posting method that is used when posting a payment tolerance. Payment Tolerance Accounts: The payment discount tolerance is posted to a special general ledger account set up for payment tolerance. Payment Discount Amount: The payment discount tolerance is posted as a payment discount.';
            OptionCaption = 'Payment Tolerance Accounts,Payment Discount Accounts';
            OptionMembers = "Payment Tolerance Accounts","Payment Discount Accounts";
        }
        /// <summary>
        /// Grace period allowed after payment discount due date for payment discount eligibility.
        /// </summary>
        field(93; "Payment Discount Grace Period"; DateFormula)
        {
            Caption = 'Payment Discount Grace Period';
            ToolTip = 'Specifies the number of days that a payment or refund can pass the payment discount due date and still receive payment discount.';
        }
        /// <summary>
        /// Payment tolerance percentage allowed for customer and vendor payment applications.
        /// </summary>
        field(94; "Payment Tolerance %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Tolerance %';
            ToolTip = 'Specifies the percentage that a payment or refund is allowed to be less than the amount on the related invoice or credit memo.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Maximum payment tolerance amount allowed for customer and vendor payment applications.
        /// </summary>
        field(95; "Max. Payment Tolerance Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance Amount';
            ToolTip = 'Specifies the maximum allowed amount that a payment or refund can differ from the amount on the related invoice or credit memo.';
            Editable = false;
            MinValue = 0;
        }
        /// <summary>
        /// Date before which G/L account deletion checks are performed to prevent accidental deletion.
        /// </summary>
        field(97; "Allow G/L Acc. Deletion Before"; Date)
        {
            Caption = 'Check G/L Acc. Deletion After';
            ToolTip = 'Specifies if and when general ledger accounts can be deleted. If you enter a date, G/L accounts with entries on or after this date can be deleted only after confirmation by the user. This setting is only valid when "Block Deletion of G/L accounts" is set to No';
        }
        /// <summary>
        /// Enables checking G/L account usage before allowing deletion to prevent loss of transaction history.
        /// </summary>
        field(98; "Check G/L Account Usage"; Boolean)
        {
            Caption = 'Check G/L Account Usage';
            ToolTip = 'Specifies that you want the program to protect G/L accounts that are used in setup tables from being deleted.';
        }
        /// <summary>
        /// Specifies how payment tolerance amounts are posted to the general ledger when payment tolerances are applied.
        /// </summary>
        field(99; "Payment Tolerance Posting"; Option)
        {
            Caption = 'Payment Tolerance Posting';
            ToolTip = 'Specifies the posting method that is used when posting a payment tolerance. Payment Tolerance Accounts: Posts the payment tolerance to a special general ledger account set up for payment tolerance. Payment Discount Amount: Posts the payment tolerance as a payment discount.';
            OptionCaption = 'Payment Tolerance Accounts,Payment Discount Accounts';
            OptionMembers = "Payment Tolerance Accounts","Payment Discount Accounts";
        }
        /// <summary>
        /// Controls whether warning messages are displayed when payment discount tolerance limits are exceeded during payment processing.
        /// </summary>
        field(100; "Pmt. Disc. Tolerance Warning"; Boolean)
        {
            Caption = 'Pmt. Disc. Tolerance Warning';
            ToolTip = 'Specifies if a warning will appear every time an application occurs between the dates specified in the Payment Discount Date field and the Pmt. Disc. Tolerance Date field in the General Ledger Setup window.';
        }
        /// <summary>
        /// Controls whether warning messages are displayed when payment tolerance limits are exceeded during payment processing.
        /// </summary>
        field(101; "Payment Tolerance Warning"; Boolean)
        {
            Caption = 'Payment Tolerance Warning';
            ToolTip = 'Specifies whether to display a message when a payment differs from the invoice amount within the specified tolerance, so you can choose how to process it. If you do not enable the message, and a tolerance level is specified, invoices with amounts that are within tolerance will be automatically closed and you cannot choose to leave the remaining amount. Default tolerance levels are specified in the Payment Tolerance % and Max. Payment Tolerance fields, but can also be specified for each customer ledger entry.';
        }
        /// <summary>
        /// Tracks the last transaction number used for intercompany transactions to ensure unique numbering.
        /// </summary>
        field(102; "Last IC Transaction No."; Integer)
        {
            Caption = 'Last IC Transaction No.';
        }
        /// <summary>
        /// Specifies whether VAT calculation is based on bill-to/sell-to customer address or ship-to address for determining tax jurisdiction.
        /// </summary>
        field(103; "Bill-to/Sell-to VAT Calc."; Enum "G/L Setup VAT Calculation")
        {
            Caption = 'Bill-to/Sell-to VAT Calc.';
            ToolTip = 'Specifies where the VAT Bus. Posting Group code on an order or invoice is copied from. Bill-to/Pay-to No.: The VAT Bus. Posting Group code on sales invoices and orders is copied from the Bill-to Customer field. The VAT Bus. Posting Group code on purchase invoices and orders is copied from the Pay-to Vendor field. Sell-to/Buy-from No. : The VAT Bus. Posting Group code on sales invoices and orders is copied from the Sell-to Customer field. The VAT Bus. Posting Group code on purchase invoices and orders is copied from the Buy-from Vendor field.';
        }
        /// <summary>
        /// Prevents deletion of G/L accounts that are referenced in setup tables or have transaction history when enabled.
        /// </summary>
        field(104; "Block Deletion of G/L Accounts"; Boolean)
        {
            Caption = 'Block Deletion of G/L Accounts';
            ToolTip = 'Specifies whether to prevent users from deleting G/L accounts with ledger entries that are after the date in the Check G/L Acc. Deletion After field. For example, blocking deletion helps you avoid losing financial data that your business should keep due to country regional requirements.';
            InitValue = true;
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// Obsolete: Account schedule name for balance sheet financial reporting.
        /// </summary>
        field(110; "Acc. Sched. for Balance Sheet"; Code[10])
        {
            Caption = 'Account Schedule for Balance Sheet';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';

            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        /// <summary>
        /// Obsolete: Account schedule name for income statement financial reporting.
        /// </summary>
        field(111; "Acc. Sched. for Income Stmt."; Code[10])
        {
            Caption = 'Account Schedule for Income Stmt.';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';

            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        /// <summary>
        /// Obsolete: Account schedule name for cash flow statement financial reporting.
        /// </summary>
        field(112; "Acc. Sched. for Cash Flow Stmt"; Code[10])
        {
            Caption = 'Account Schedule for Cash Flow Stmt';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';

            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        /// <summary>
        /// Obsolete: Account schedule name for retained earnings financial reporting.
        /// </summary>
        field(113; "Acc. Sched. for Retained Earn."; Code[10])
        {
            Caption = 'Account Schedule for Retained Earn.';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';

            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
#endif
        /// <summary>
        /// Default financial report used for generating balance sheet statements and analysis.
        /// </summary>
        field(114; "Fin. Rep. for Balance Sheet"; Code[10])
        {
            Caption = 'Financial Report for Balance Sheet';
            TableRelation = "Financial Report";
            ToolTip = 'Specifies which financial report is used to generate the Balance Sheet report.';
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Default financial report used for generating income statement reports and profit/loss analysis.
        /// </summary>
        field(115; "Fin. Rep. for Income Stmt."; Code[10])
        {
            Caption = 'Financial Report for Income Stmt.';
            TableRelation = "Financial Report";
            ToolTip = 'Specifies which financial report is used to generate the Income Statement report.';
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Default financial report used for generating cash flow statement reports and liquidity analysis.
        /// </summary>
        field(116; "Fin. Rep. for Cash Flow Stmt"; Code[10])
        {
            Caption = 'Financial Report for Cash Flow Stmt.';
            TableRelation = "Financial Report";
            ToolTip = 'Specifies which financial report is used to generate the Cash Flow Statement report.';
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Default financial report used for generating retained earnings statements and equity analysis.
        /// </summary>
        field(117; "Fin. Rep. for Retained Earn."; Code[10])
        {
            Caption = 'Financial Report for Retained Earn.';
            TableRelation = "Financial Report";
            ToolTip = 'Specifies which financial report is used to generate the Retained Earnings report.';
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Threshold amount for tax invoice renaming in local currency when processing tax-related transactions.
        /// </summary>
        field(120; "Tax Invoice Renaming Threshold"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Tax Invoice Renaming Threshold';
            ToolTip = 'Specifies that if the amount on a sales invoice or a service invoice exceeds the threshold, then the name of the document is changed to include the words "Tax Invoice", as required by the tax authorities.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Requires country/region code to be specified in customer and vendor addresses for regulatory compliance.
        /// </summary>
        field(130; "Req.Country/Reg. Code in Addr."; Boolean)
        {
            Caption = 'Require Country/Region Code in Address';
            ToolTip = 'Specifies whether to clear the Post Code, City, and County fields when the value in the Country/Region Code field is changed.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether VAT amounts are printed in local currency on reports and documents when foreign currency transactions are involved.
        /// </summary>
        field(150; "Print VAT specification in LCY"; Boolean)
        {
            Caption = 'Print VAT specification in LCY';
            ToolTip = 'Specifies that an extra VAT specification in local currency will be included on documents in a foreign currency. This can be used to make tax audits easier when reconciling VAT payables to invoices.';
        }
        /// <summary>
        /// Enables unrealized VAT processing for prepayment transactions when prepayments are subject to VAT.
        /// </summary>
        field(151; "Prepayment Unrealized VAT"; Boolean)
        {
            Caption = 'Prepayment Unrealized VAT';
            ToolTip = 'Specifies whether to handle unrealized VAT on prepayments.';

            trigger OnValidate()
            begin
                if "Unrealized VAT" and xRec."Prepayment Unrealized VAT" then
                    Error(DependentFieldActivatedErr, FieldCaption("Prepayment Unrealized VAT"), FieldCaption("Unrealized VAT"));

                if not "Prepayment Unrealized VAT" then begin
                    VATPostingSetup.SetFilter(
                      "Unrealized VAT Type", '>=%1', VATPostingSetup."Unrealized VAT Type"::Percentage);
                    if VATPostingSetup.FindFirst() then
                        Error(
                          Text000, VATPostingSetup.TableCaption(),
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Unrealized VAT Type"), VATPostingSetup."Unrealized VAT Type");
                    TaxJurisdiction.SetFilter(
                      "Unrealized VAT Type", '>=%1', TaxJurisdiction."Unrealized VAT Type"::Percentage);
                    if TaxJurisdiction.FindFirst() then
                        Error(
                          Text001, TaxJurisdiction.TableCaption(),
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Unrealized VAT Type"),
                          TaxJurisdiction."Unrealized VAT Type");
                end;
            end;
        }
        /// <summary>
        /// Data exchange definition used for importing payroll transaction data from external payroll systems.
        /// </summary>
        field(160; "Payroll Trans. Import Format"; Code[20])
        {
            Caption = 'Payroll Trans. Import Format';
            ToolTip = 'Specifies the format of the payroll transaction file that can be imported into the General Journal window.';
            TableRelation = "Data Exch. Def" where(Type = const("Payroll Import"));

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUptake('0004H8X', 'DK payroll service', Enum::"Feature Uptake Status"::Discovered);
            end;
        }
        /// <summary>
        /// Symbol used to represent the local currency in reports and user interface displays.
        /// </summary>
        field(162; "Local Currency Symbol"; Text[10])
        {
            Caption = 'Local Currency Symbol';
            ToolTip = 'Specifies the symbol for the local currency that you want to appear on checks and charts, such as $ for USD.';
        }
        /// <summary>
        /// Descriptive name for the local currency used in reports and system displays.
        /// </summary>
        field(163; "Local Currency Description"; Text[60])
        {
            Caption = 'Local Currency Description';
            ToolTip = 'Specifies the description of the local currency.';
        }
        /// <summary>
        /// Controls how amounts are displayed in G/L entries and reports: amount only, debit/credit only, or all amounts.
        /// </summary>
        field(164; "Show Amounts"; Option)
        {
            Caption = 'Show Amounts';
            ToolTip = 'Specifies which type of amounts are shown in journals and in ledger entries windows. Amount Only: The Amount and Amount (LCY) fields are shown. Debit/Credit Only: The Debit Amount, Debit Amount (LCY), Credit Amount, and Credit Amount (LCY) fields are shown. All Amounts: All amount fields are shown.';
            OptionCaption = 'Amount Only,Debit/Credit Only,All Amounts';
            OptionMembers = "Amount Only","Debit/Credit Only","All Amounts";
        }
        /// <summary>
        /// Determines the type of posting preview shown to users before finalizing transactions.
        /// </summary>
        field(169; "Posting Preview Type"; Enum "Posting Preview Type")
        {
            Caption = 'Posting Preview Type';
            ToolTip = 'Specifies the amount of detail to include in the posting preview. Standard gives an overview of entries grouped by type, and you can choose the type of entry to view details. Extended displays the details for G/L entries and VAT entries.';
        }
        /// <summary>
        /// Allows SEPA payment export for currencies other than Euro when enabled.
        /// </summary>
        field(170; "SEPA Non-Euro Export"; Boolean)
        {
            Caption = 'SEPA Non-Euro Export';
            ToolTip = 'Specifies whether to use SEPA export for journal lines with currencies different from Euro.';
        }
        /// <summary>
        /// Enables SEPA payment export without requiring complete bank account data when enabled.
        /// </summary>
        field(171; "SEPA Export w/o Bank Acc. Data"; Boolean)
        {
            Caption = 'SEPA Export w/o Bank Acc. Data';
            ToolTip = 'Specifies if it is possible to use SEPA direct debit export by filling in the Bank Branch No. and Bank Account No. fields instead of the IBAN and SWIFT No. fields on the bank account and customer bank account cards.';
        }
        /// <summary>
        /// Requires journal template name to be specified when creating general journal lines for better control and validation.
        /// </summary>
        field(175; "Journal Templ. Name Mandatory"; Boolean)
        {
            Caption = 'Journal Templ. Name Mandatory';
            ToolTip = 'Specifies if a journal template and batch names are required when posting general ledger transactions. If you want to have template name in posted documents and entries, you must set this field as TRUE.';
        }
        /// <summary>
        /// Hides payment method code field in journals and documents when enabled for simplified data entry.
        /// </summary>
        field(176; "Hide Payment Method Code"; Boolean)
        {
            Caption = 'Hide Payment Method Code';
            ToolTip = 'Specifies if payment method code is shown in sales and purchase documents.';
        }
        /// <summary>
        /// Enables additional data validation checks during posting to ensure data integrity and compliance.
        /// </summary>
        field(177; "Enable Data Check"; Boolean)
        {
            Caption = 'Enable Data Check';
            ToolTip = 'Specifies whether Business Central validates the data you enter in documents and journals while you type. For documents, you can turn on the check and messages will be shown in the Document Check FactBox. For journals, messages are always shown in the Journal Check FactBox.';
        }
        /// <summary>
        /// Default retention period applied to financial documents for automatic cleanup and compliance management.
        /// </summary>
        field(178; "Document Retention Period"; Enum "Docs - Retention Period Def.")
        {
            Caption = 'Documents Retention Period';
            DataClassification = SystemMetadata;
            InitValue = 0;
        }
        /// <summary>
        /// Default general journal template used for customer and vendor payment application processes.
        /// </summary>
        field(180; "Apply Jnl. Template Name"; Code[10])
        {
            Caption = 'Apply Jnl. Template Name';
            ToolTip = 'Specifies the name of the journal template you want to use for applying customer or vendor ledger entries.';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Default general journal batch used for customer and vendor payment application processes.
        /// </summary>
        field(181; "Apply Jnl. Batch Name"; Code[10])
        {
            Caption = 'Apply Jnl. Batch Name';
            ToolTip = 'Specifies the name of the journal batch you want to use for applying customer or vendor ledger entries.';
            TableRelation = if ("Apply Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Apply Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Apply Jnl. Template Name");
            end;
        }
        /// <summary>
        /// Default general journal template used for posting job work-in-process entries during job completion processes.
        /// </summary>
        field(182; "Job WIP Jnl. Template Name"; Code[10])
        {
            Caption = 'Project WIP Jnl. Template Name';
            ToolTip = 'Specifies the name of the journal template you want to use for posting project WIP to G/L.';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Default general journal batch used for posting job work-in-process entries during job completion processes.
        /// </summary>
        field(183; "Job WIP Jnl. Batch Name"; Code[10])
        {
            Caption = 'Project WIP Jnl. Batch Name';
            ToolTip = 'Specifies the name of the journal batch you want to use for posting project WIP to G/L.';
            TableRelation = if ("Job WIP Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Job WIP Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Job WIP Jnl. Template Name");
            end;
        }
        /// <summary>
        /// Default general journal template used for additional reporting currency adjustments during currency rate changes.
        /// </summary>
        field(184; "Adjust ARC Jnl. Template Name"; Code[10])
        {
            Caption = 'Adjust Add. Rep. Currency Jnl. Template Name';
            ToolTip = 'Specifies the name of the journal template you want to use for posting adjustment of additional reporting currency.';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Default general journal batch used for additional reporting currency adjustments during currency rate changes.
        /// </summary>
        field(185; "Adjust ARC Jnl. Batch Name"; Code[10])
        {
            Caption = 'Adjust Add. Rep. Currency Jnl. Batch Name';
            ToolTip = 'Specifies the name of the journal batch you want to use for posting adjustment of additional reporting currency.';
            TableRelation = if ("Adjust ARC Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Adjust ARC Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Adjust ARC Jnl. Template Name");
            end;
        }
        /// <summary>
        /// Default general journal template used for bank account reconciliation adjustment entries.
        /// </summary>
        field(186; "Bank Acc. Recon. Template Name"; Code[10])
        {
            Caption = 'Bank Acc. Recon. Template Name';
            ToolTip = 'Specifies the name of the journal batch you want to use for posting bank account reconciliation.';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Default general journal batch used for bank account reconciliation adjustment entries.
        /// </summary>
        field(187; "Bank Acc. Recon. Batch Name"; Code[10])
        {
            Caption = 'Bank Acc. Recon. Batch Name';
            ToolTip = 'Specifies the name of the journal batch you want to use for posting bank account reconciliation.';
            TableRelation = if ("Bank Acc. Recon. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Bank Acc. Recon. Template Name"));
        }
        /// <summary>
        /// Controls VAT period validation and posting restrictions to ensure compliance with tax reporting periods.
        /// </summary>
        field(188; "Control VAT Period"; Enum "VAT Period Control")
        {
            Caption = 'Control VAT Period';
            ToolTip = 'Specifies a way of using VAT Date against VAT Return Periods. If you choose â€˜Block posting within closed and warn for released periodâ€™, system will not allow postings in closed VAT Return Period, but if the period is not closed, but VAT returns are released or submitted, user will be warned what try to post an entry with VAT Date in this period. If you choose â€˜Block posting within closed periodâ€™, system will still not allow postings in closed VAT Return Period, but there will be no warnings for release or submitted VAT returns. If you choose â€˜Warn when posting in closed periodâ€™, system will not block posting entry with VAT Date in the closed VAT return period, but it will show warning message before posting. And if you choose â€˜Disabledâ€™ options, system will allow you to post without any control regardless of VAT return or period status.';

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUsage('0000JWC', VATDateFeatureTok, VATPeriodControlUsageMsg);
            end;
        }
        /// <summary>
        /// Enables this company to be queried from consolidation processes when used as a subsidiary company.
        /// </summary>
        field(189; "Allow Query From Consolid."; Boolean)
        {
            Caption = 'Enable company as subsidiary';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ImportConsolidationFromApi: Codeunit "Import Consolidation From API";
            begin
                if not Rec."Allow Query From Consolid." then
                    exit;
                if not GuiAllowed() then
                    Error(PrivacyStatementAckErr);
                if not ImportConsolidationFromApi.GetPrivacyConsentChoice() then
                    Error('');
            end;

        }
        /// <summary>
        /// G/L account category used for classifying accounts receivable accounts in financial reporting.
        /// </summary>
        field(190; "Acc. Receivables Category"; Integer)
        {
            TableRelation = "G/L Account Category";
            Caption = 'Account Receivables G/L Account Category';
        }
        /// <summary>
        /// Controls which dimension information is posted during exchange rate adjustment processes.
        /// </summary>
        field(191; "App. Dimension Posting"; Enum "Exch. Rate Adjmt. Dimensions")
        {
            Caption = 'Dimension Posting';
            ToolTip = 'Specifies dimension source for Realized Gain/Loss application entries.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Hides company bank account information in certain displays and reports for security purposes.
        /// </summary>
        field(192; "Hide Company Bank Account"; Boolean)
        {
            Caption = 'Hide Company Bank Account';
            ToolTip = 'Specifies whether or not the Company Bank Account can be updated on posted documents.';
        }
        field(193; "Check Source Curr. Consistency"; Boolean)
        {
            Caption = 'Check Source Curr. Consistency';
            ToolTip = 'Specifies whether Business Central validates the total of general ledger entries source currency amount during posting.';
        }
        field(194; "Acc. Payables Category"; Integer)
        {
            TableRelation = "G/L Account Category";
            Caption = 'Account Payables G/L Account Category';
        }
        field(195; "Fin. Rep. Period Type"; Enum "Analysis Period Type")
        {
            Caption = 'Financial Report Period Type';
            ToolTip = 'Specifies by which period amounts are displayed on financial report by default.';
        }
        field(196; "Fin. Rep. Neg. Amount Format"; Enum "Analysis Negative Format")
        {
            Caption = 'Financial Report Default Negative Amt. Format';
            ToolTip = 'Specifies how negative amounts are displayed on the financial report by default.';
        }
        field(197; "Fin. Rep. Company Logo Pos."; Enum "Fin. Report Logo Position")
        {
            Caption = 'Financial Report Company Logo Position';
            ToolTip = 'Specifies how your company logo is displayed on the financial report by default.';
        }
        field(198; "Fin. Rep. Bal. Sheet Row"; Code[10])
        {
            Caption = 'Financial Report Row Definition for Balance Sheet';
            TableRelation = "Acc. Schedule Name";
            ToolTip = 'Specifies the name of the Balance Sheet row on Financial Reports.';
            ValidateTableRelation = false;
        }
        field(199; "Fin. Rep. Income Stmt. Row"; Code[10])
        {
            Caption = 'Financial Report Row Definition for Income Stmt.';
            TableRelation = "Acc. Schedule Name";
            ToolTip = 'Specifies the name of the Income Statement row on Financial Reports.';
            ValidateTableRelation = false;
        }
        field(200; "Fin. Rep. Cash Flow Stmt. Row"; Code[10])
        {
            Caption = 'Financial Report Row Definition for Cash Flow Stmt.';
            TableRelation = "Acc. Schedule Name";
            ToolTip = 'Specifies the name of the Cash Flow Statement row on Financial Reports.';
            ValidateTableRelation = false;
        }
        field(201; "Fin. Rep. Retained Earn. Row"; Code[10])
        {
            Caption = 'Financial Report Row Definition for Retained Earn.';
            TableRelation = "Acc. Schedule Name";
            ToolTip = 'Specifies the name of the Retained Earnings row on Financial Reports.';
            ValidateTableRelation = false;
        }
        field(202; "Fin. Rep. Bal. Sheet Column"; Code[10])
        {
            Caption = 'Financial Report Column Definition for Balance Sheet';
            TableRelation = "Column Layout Name";
            ToolTip = 'Specifies the name of the Balance Sheet column on Financial Reports.';
            ValidateTableRelation = false;
        }
        field(203; "Fin. Rep. Net Change Column"; Code[10])
        {
            Caption = 'Financial Report Column Definition for Net Change';
            TableRelation = "Column Layout Name";
            ToolTip = 'Specifies the name of the Net Change column on Financial Reports.';
            ValidateTableRelation = false;
        }
        field(204; DefaultFinancialReportStatus; Code[10])
        {
            Caption = 'Default Financial Report Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the Default Financial Report Status on Financial Reports.';
            TableRelation = "Financial Report Status";
        }
        field(205; "Allow Posting From DateFormula"; DateFormula)
        {
            Caption = 'Allow Posting From DateFormula';

            trigger OnValidate()
            begin
                if xRec."Allow Posting From DateFormula" <> Rec."Allow Posting From DateFormula" then begin
                    if Format(Rec."Allow Posting From DateFormula") <> '' then
                        Rec.Validate("Allow Posting From", 0D);

                    CheckDateRange();
                end;
            end;
        }
        field(206; "Allow Posting To DateFormula"; DateFormula)
        {
            Caption = 'Allow Posting To DateFormula';

            trigger OnValidate()
            begin
                if xRec."Allow Posting To DateFormula" <> Rec."Allow Posting To DateFormula" then begin
                    if Format(Rec."Allow Posting To DateFormula") <> '' then
                        Rec.Validate("Allow Posting To", 0D);

                    CheckDateRange();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Dim: Record Dimension;
        GLEntry: Record "G/L Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        AdjAddReportingCurr: Report "Adjust Add. Reporting Currency";
        UserSetupManagement: Codeunit "User Setup Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ErrorMessage: Boolean;
        RecordHasBeenRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 %3 have %4 to %5.';
        Text001: Label '%1 %2 have %3 to %4.';
        Text002: Label '%1 %2 %3 use %4.';
        Text003: Label '%1 %2 use %3.';
        Text004: Label '%1 must be rounded to the nearest %2.';
#pragma warning restore AA0470
        Text016: Label 'Enter one number or two numbers separated by a colon. ';
        Text017: Label 'The online Help for this field describes how you can fill in the field.';
#pragma warning disable AA0470
        Text018: Label 'You cannot change the contents of the %1 field because there are posted ledger entries.';
#pragma warning restore AA0470
        Text021: Label 'You must close the program and start again in order to activate the amount-rounding feature.';
        Text022: Label 'You must close the program and start again in order to activate the unit-amount rounding feature.';
#pragma warning disable AA0470
        Text023: Label '%1\You cannot use the same dimension twice in the same setup.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        DependentFieldActivatedErr: Label 'You cannot change %1 because %2 is selected.';
#pragma warning restore AA0470
        AccSchedObsoleteErr: Label 'This field is obsolete and it has been replaced by Table 88 Financial Report';
        VATDateFeatureTok: Label 'VAT Date', Locked = true;
        VATPeriodControlUsageMsg: Label 'Control VAT Period is changed', Locked = true;
        VATDateFeatureUsageMsg: Label 'VAT Reporting Date Usage is changed', Locked = true;
        PrivacyStatementAckErr: Label 'Enabling requires privacy statement acknowledgement.';
        CannotUpdateLCYCodeErr: Label 'You cannot update the local currency code because there are posted general ledger entries.';

    /// <summary>
    /// Validates and corrects the format of decimal places configuration for currency and amount display.
    /// </summary>
    /// <param name="DecimalPlaces">Decimal places format string to validate and potentially correct</param>
    procedure CheckDecimalPlacesFormat(var DecimalPlaces: Text[5])
    var
        OK: Boolean;
        ColonPlace: Integer;
        DecimalPlacesPart1: Integer;
        DecimalPlacesPart2: Integer;
        Check: Text[5];
    begin
        OK := true;
        ColonPlace := StrPos(DecimalPlaces, ':');

        if ColonPlace = 0 then begin
            if not Evaluate(DecimalPlacesPart1, DecimalPlaces) then
                OK := false;
            if (DecimalPlacesPart1 < 0) or (DecimalPlacesPart1 > 9) then
                OK := false;
        end else begin
            Check := CopyStr(DecimalPlaces, 1, ColonPlace - 1);
            if Check = '' then
                OK := false;
            if not Evaluate(DecimalPlacesPart1, Check) then
                OK := false;
            Check := CopyStr(DecimalPlaces, ColonPlace + 1, StrLen(DecimalPlaces));
            if Check = '' then
                OK := false;
            if not Evaluate(DecimalPlacesPart2, Check) then
                OK := false;
            if DecimalPlacesPart1 > DecimalPlacesPart2 then
                OK := false;
            if (DecimalPlacesPart1 < 0) or (DecimalPlacesPart1 > 9) then
                OK := false;
            if (DecimalPlacesPart2 < 0) or (DecimalPlacesPart2 > 9) then
                OK := false;
        end;

        if not OK then
            Error(
              Text016 +
              Text017);

        if ColonPlace = 0 then
            DecimalPlaces := Format(DecimalPlacesPart1)
        else
            DecimalPlaces := StrSubstNo('%1:%2', DecimalPlacesPart1, DecimalPlacesPart2);
    end;

    /// <summary>
    /// Returns the appropriate currency code for display, converting between LCY code and empty string as needed.
    /// </summary>
    /// <param name="CurrencyCode">Input currency code to convert</param>
    /// <returns>Converted currency code: LCY code becomes empty, empty becomes LCY code, others remain unchanged</returns>
    procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        case CurrencyCode of
            '':
                exit("LCY Code");
            "LCY Code":
                exit('');
            else
                exit(CurrencyCode);
        end;
    end;

    /// <summary>
    /// Retrieves the local currency symbol for display in user interface and reports.
    /// </summary>
    /// <returns>Local currency symbol or LCY code if symbol is not defined</returns>
    procedure GetCurrencySymbol(): Text[10]
    begin
        if "Local Currency Symbol" <> '' then
            exit("Local Currency Symbol");

        exit("LCY Code");
    end;

    /// <summary>
    /// Ensures the General Ledger Setup record is read from the database only once per session for performance optimization.
    /// </summary>
    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    /// <summary>
    /// Updates VAT date based on VAT reporting date configuration and the specified date type.
    /// </summary>
    /// <param name="NewDate">New date value to potentially assign</param>
    /// <param name="VATDateType">Type of VAT reporting date being processed</param>
    /// <param name="VATDate">VAT date variable to update if date type matches configuration</param>
    procedure UpdateVATDate(NewDate: Date; VATDateType: Enum "VAT Reporting Date"; var VATDate: Date)
    begin
        if ("VAT Reporting Date" = VATDateType) then
            VatDate := NewDate;
    end;

    /// <summary>
    /// Determines the appropriate VAT date based on posting date, document date, and VAT reporting date configuration.
    /// </summary>
    /// <param name="PostingDate">Transaction posting date</param>
    /// <param name="DocumentDate">Document date from source document</param>
    /// <returns>VAT date based on configuration: posting date, document date, or posting date if document date is zero</returns>
    procedure GetVATDate(PostingDate: Date; DocumentDate: Date): Date
    begin
        Get();
        case "VAT Reporting Date" of
            Enum::"VAT Reporting Date"::"Posting Date":
                exit(PostingDate);
            Enum::"VAT Reporting Date"::"Document Date":
                exit(DocumentDate);
        end;
        exit(PostingDate);
    end;

    /// <summary>
    /// Validates that rounding precision changes are allowed by checking for existing ledger entries across all modules.
    /// </summary>
    /// <param name="NameOfField">Name of the field being validated for rounding precision changes</param>
    procedure CheckRoundingError(NameOfField: Text[100])
    begin
        ErrorMessage := false;
        if GLEntry.FindFirst() then
            ErrorMessage := true;
        if ItemLedgerEntry.FindFirst() then
            ErrorMessage := true;
        if JobLedgEntry.FindFirst() then
            ErrorMessage := true;
        if ResLedgEntry.FindFirst() then
            ErrorMessage := true;
        if FALedgerEntry.FindFirst() then
            ErrorMessage := true;
        if MaintenanceLedgerEntry.FindFirst() then
            ErrorMessage := true;
        if InsCoverageLedgerEntry.FindFirst() then
            ErrorMessage := true;
        OnBeforeCheckRoundingError(ErrorMessage);
        if ErrorMessage then
            Error(Text018, NameOfField);
    end;

    local procedure DeleteAnalysisView()
    begin
        if AnalysisView.Find('-') then
            repeat
                if AnalysisView.Blocked = false then begin
                    AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    AnalysisViewEntry.DeleteAll();
                    AnalysisViewBudgetEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    AnalysisViewBudgetEntry.DeleteAll();
                    AnalysisView."Last Entry No." := 0;
                    AnalysisView."Last Budget Entry No." := 0;
                    AnalysisView."Last Date Updated" := 0D;
                    AnalysisView.Modify();
                end else begin
                    AnalysisView."Refresh When Unblocked" := true;
                    AnalysisView.Modify();
                end;
            until AnalysisView.Next() = 0;
    end;

    /// <summary>
    /// Determines whether posting is allowed for the specified date based on setup configuration and extensibility events.
    /// </summary>
    /// <param name="PostingDate">Date to validate for posting allowance</param>
    /// <returns>True if posting is allowed for the specified date, false otherwise</returns>
    procedure IsPostingAllowed(PostingDate: Date) Result: Boolean
    begin
        Result := PostingDate >= "Allow Posting From";
        OnAfterIsPostingAllowed(Rec, PostingDate, Result);
    end;

    /// <summary>
    /// Checks whether background job queue processing is currently active for the general ledger setup.
    /// </summary>
    /// <returns>True if job queue is active, false otherwise</returns>
    procedure JobQueueActive(): Boolean
    begin
        Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

    /// <summary>
    /// Determines the earliest date allowed for posting based on setup configuration and inventory periods.
    /// </summary>
    /// <returns>First allowed posting date considering setup and inventory period restrictions</returns>
    procedure FirstAllowedPostingDate() AllowedPostingDate: Date
    var
        InvtPeriod: Record "Inventory Period";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFirstAllowedPostingDate(Rec, AllowedPostingDate, IsHandled);
        if IsHandled then
            exit;

        AllowedPostingDate := "Allow Posting From";
        if not InvtPeriod.IsValidDate(AllowedPostingDate) then
            AllowedPostingDate := CalcDate('<+1D>', AllowedPostingDate);
    end;

    /// <summary>
    /// Updates global dimension number assignments for dimension values when changing global dimension configuration.
    /// </summary>
    /// <param name="xDimCode">Previous dimension code being replaced</param>
    /// <param name="DimCode">New dimension code being assigned</param>
    /// <param name="ShortcutDimNo">Global dimension number (1-8) being updated</param>
    procedure UpdateDimValueGlobalDimNo(xDimCode: Code[20]; DimCode: Code[20]; ShortcutDimNo: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if Dim.CheckIfDimUsed(DimCode, Enum::"Dim Type Checked".FromInteger(ShortcutDimNo), '', '', 0) then
            Error(Text023, Dim.GetCheckDimErr());
        if xDimCode <> '' then begin
            DimensionValue.SetRange("Dimension Code", xDimCode);
            DimensionValue.ModifyAll("Global Dimension No.", 0);

            DimensionSetEntry.UpdateGlobalDimensionNo(xDimCode, 0);
        end;
        if DimCode <> '' then begin
            DimensionValue.SetRange("Dimension Code", DimCode);
            DimensionValue.ModifyAll("Global Dimension No.", ShortcutDimNo);

            DimensionSetEntry.UpdateGlobalDimensionNo(DimCode, ShortcutDimNo);
        end;
        OnAfterUpdateDimValueGlobalDimNo(ShortcutDimNo, xDimCode, DimCode);
        Modify();
    end;

    local procedure HideDialog(): Boolean
    begin
        exit((CurrFieldNo = 0) or not GuiAllowed);
    end;

    local procedure CheckDateRange()
    var
        AllowedFrom: Date;
        AllowedTo: Date;
    begin
        if (Format(Rec."Allow Posting From DateFormula") = '') and (Format(Rec."Allow Posting To DateFormula") = '') then
            exit;

        AllowedFrom := Rec."Allow Posting From";
        AllowedTo := Rec."Allow Posting To";
        UserSetupManagement.GetDateRange(
            AllowedFrom, AllowedTo,
            Rec."Allow Posting From DateFormula", Rec."Allow Posting To DateFormula",
            Rec.RecordId());
    end;

    /// <summary>
    /// Determines if VAT is enabled in the system based on current VAT posting setup configuration.
    /// </summary>
    /// <returns>True if VAT posting setup exists and VAT is active, false otherwise</returns>
    procedure UseVat(): Boolean
    var
        GeneralLedgerSetupRecordRef: RecordRef;
        UseVATFieldRef: FieldRef;
        UseVATFieldNo: Integer;
    begin
        GeneralLedgerSetupRecordRef.Open(DATABASE::"General Ledger Setup", false);

        UseVATFieldNo := 10001;

        if not GeneralLedgerSetupRecordRef.FieldExist(UseVATFieldNo) then
            exit(true);

        if not GeneralLedgerSetupRecordRef.FindFirst() then
            exit(false);

        UseVATFieldRef := GeneralLedgerSetupRecordRef.Field(UseVATFieldNo);
        exit(UseVATFieldRef.Value);
    end;

    /// <summary>
    /// Validates that posting dates fall within allowed posting periods defined in general ledger setup.
    /// </summary>
    /// <param name="NotificationType">Type of notification to show (Error or Notification) when validation fails</param>
    procedure CheckAllowedPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange("Allow Posting From",
          "Allow Posting To", NotificationType, DATABASE::"General Ledger Setup");
    end;

    /// <summary>
    /// Validates that deferral posting dates fall within allowed deferral posting periods.
    /// </summary>
    /// <param name="NotificationType">Type of notification to show (Error or Notification) when validation fails</param>
    procedure CheckAllowedDeferralPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange(
          "Allow Deferral Posting From", "Allow Deferral Posting To", NotificationType, DATABASE::"User Setup",
          FieldCaption("Allow Deferral Posting From"), FieldCaption("Allow Deferral Posting To"));
    end;

    /// <summary>
    /// Determines if payment tolerance fields should be visible in the user interface.
    /// </summary>
    /// <returns>True if payment tolerance percentage or maximum amount is configured</returns>
    procedure GetPmtToleranceVisible(): Boolean
    begin
        exit(("Payment Tolerance %" > 0) or ("Max. Payment Tolerance Amount" <> 0));
    end;

    /// <summary>
    /// Integration event raised before validating rounding error configuration.
    /// Enables custom error message handling and validation logic for rounding tolerances.
    /// </summary>
    /// <param name="ErrorMessage">Set to true to suppress standard error message display</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRoundingError(var ErrorMessage: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after determining if posting is allowed for a given date.
    /// Enables custom posting date validation logic and period override capabilities.
    /// </summary>
    /// <param name="GeneralLedgerSetup">General Ledger Setup record with posting date configuration</param>
    /// <param name="PostingDate">Date being validated for posting allowance</param>
    /// <param name="Result">Validation result indicating if posting is allowed for the date</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterIsPostingAllowed(GeneralLedgerSetup: Record "General Ledger Setup"; PostingDate: Date; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating the first allowed posting date.
    /// Enables custom logic for determining earliest allowable posting date based on setup and user permissions.
    /// </summary>
    /// <param name="GeneralLedgerSetup">General Ledger Setup record with posting period configuration</param>
    /// <param name="AllowedPostingDate">Calculated first allowed posting date, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard calculation logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFirstAllowedPostingDate(GeneralLedgerSetup: Record "General Ledger Setup"; var AllowedPostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after updating global dimension assignments for dimension values.
    /// Enables custom processing and validation when global dimensions are reconfigured.
    /// </summary>
    /// <param name="ShortCutDimNo">Global dimension number (1-8) that was updated</param>
    /// <param name="OldDimensionCode">Previous dimension code that was replaced</param>
    /// <param name="NewDimensionCode">New dimension code that was assigned</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimValueGlobalDimNo(ShortCutDimNo: Integer; OldDimensionCode: Code[20]; NewDimensionCode: Code[20])
    begin
    end;
}
