// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Bank.BankAccount;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

table 15 "G/L Account"
{
    Caption = 'G/L Account';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Chart of Accounts";
    LookupPageID = "G/L Account List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            OptimizeForTextSearch = true;
            NotBlank = true;
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the name of the general ledger account.';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
                    "Search Name" := Name;

                UpdateMyAccount(FieldNo(Name));
            end;
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
            OptimizeForTextSearch = true;
        }
        field(4; "Account Type"; Enum "G/L Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';

            trigger OnValidate()
            var
                GLEntry: Record "G/L Entry";
                GLBudgetEntry: Record "G/L Budget Entry";
            begin
                case "Account Type" of
                    "Account Type"::Posting:
                        "API Account Type" := "API Account Type"::Posting;
                    "Account Type"::Heading:
                        "API Account Type" := "API Account Type"::Heading;
                    "Account Type"::Total:
                        "API Account Type" := "API Account Type"::Total;
                    "Account Type"::"Begin-Total":
                        "API Account Type" := "API Account Type"::"Begin-Total";
                    "Account Type"::"End-Total":
                        "API Account Type" := "API Account Type"::"End-Total";
                end;

                if ("Account Type" <> "Account Type"::Posting) and
                   (xRec."Account Type" = xRec."Account Type"::Posting)
                then begin
                    GLEntry.SetRange("G/L Account No.", "No.");
                    if not GLEntry.IsEmpty() then
                        Error(
                          Text000,
                          FieldCaption("Account Type"));
                    GLBudgetEntry.SetRange("G/L Account No.", "No.");
                    if not GLBudgetEntry.IsEmpty() then
                        Error(
                          Text001,
                          FieldCaption("Account Type"));
                end;
                Totaling := '';
                UpdateMyAccount(FieldNo(Totaling));
                if "Account Type" = "Account Type"::Posting then begin
                    if "Account Type" <> xRec."Account Type" then
                        "Direct Posting" := true;
                end else
                    "Direct Posting" := false;
            end;
        }
        field(6; "Global Dimension 1 Code"; Code[20])
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
        field(7; "Global Dimension 2 Code"; Code[20])
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
        field(8; "Account Category"; Enum "G/L Account Category")
        {
            BlankZero = true;
            Caption = 'Account Category';
            ToolTip = 'Specifies the category of the G/L account.';

            trigger OnValidate()
            begin
                if "Account Category" = "Account Category"::" " then
                    exit;

                if "Account Category" in ["Account Category"::Income, "Account Category"::"Cost of Goods Sold", "Account Category"::Expense] then
                    "Income/Balance" := "Income/Balance"::"Income Statement"
                else
                    "Income/Balance" := "Income/Balance"::"Balance Sheet";
                if "Account Category" <> xRec."Account Category" then
                    "Account Subcategory Entry No." := 0;

                UpdateAccountCategoryOfSubAccounts();
            end;
        }
        field(9; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
            ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';

            trigger OnValidate()
            var
                CostType: Record "Cost Type";
            begin
                if ("Income/Balance" = "Income/Balance"::"Balance Sheet") and ("Cost Type No." <> '') then begin
                    if CostType.Get("No.") then begin
                        CostType."G/L Account Range" := '';
                        CostType.Modify();
                    end;
                    "Cost Type No." := '';
                end;
            end;
        }
        field(10; "Debit/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionCaption = 'Both,Debit,Credit';
            OptionMembers = Both,Debit,Credit;
        }
        field(11; "No. 2"; Code[20])
        {
            Caption = 'No. 2';
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("G/L Account"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            ToolTip = 'Specifies whether you will be able to post directly or only indirectly to this general ledger account. To allow Direct Posting to the G/L account, place a check mark in the check box.';
            InitValue = true;
        }
        field(16; "Reconciliation Account"; Boolean)
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Reconciliation Account';
            ToolTip = 'Specifies whether this general ledger account will be included in the Reconciliation window in the general journal. To have the G/L account included in the window, place a check mark in the check box. You can find the Reconciliation window by clicking Actions, Posting in the General Journal window.';
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(18; "No. of Blank Lines"; Integer)
        {
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        field(19; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;

            trigger OnValidate()
            begin
                if Indentation < 0 then
                    Indentation := 0;
            end;
        }
        field(20; "Source Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                GLAccountSourceCurrency: Record "G/L Account Source Currency";
            begin
                if "Source Currency Code" <> '' then
                    TestField("Source Currency Posting", "Source Currency Posting"::"Same Currency");

                if ("Source Currency Code" <> '') and
                   (("Account Type" <> "Account Type"::Posting) or ("Income/Balance" <> "Income/Balance"::"Balance Sheet"))
                then
                    Error(CurrencyCodeErr);

                if ("Source Currency Code" <> xRec."Source Currency Code") and (xRec."Source Currency Code" <> '') then begin
                    GLAccountSourceCurrency."G/L Account No." := "No.";
                    GLAccountSourceCurrency."Currency Code" := xRec."Source Currency Code";
                    GLAccountSourceCurrency.CalcFields("Balance at Date", "Source Curr. Balance at Date");
                    if (GLAccountSourceCurrency."Balance at Date" <> 0) or (GLAccountSourceCurrency."Source Curr. Balance at Date" <> 0) then
                        Error(BalanceMustBeZeroErr);
                end;

                if "Source Currency Code" <> xRec."Source Currency Code" then
                    GLAccountSourceCurrency.InsertRecord("No.", "Source Currency Code");
            end;
        }
        field(21; "Source Currency Posting"; Enum "G/L Source Currency Posting")
        {
            Caption = 'Source Currency Posting';
        }
        field(22; "Source Currency Revaluation"; Boolean)
        {
            Caption = 'Source Currency Revaluation';
        }
        field(23; "Unrealized Revaluation"; Boolean)
        {
            Caption = 'Unrealized Revaluation';
        }
        field(25; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(26; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(28; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Balance at Date"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("No."),
                                                        "G/L Account No." = field(filter(Totaling)),
                                                        "Business Unit Code" = field("Business Unit Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Posting Date" = field(upperlimit("Date Filter")),
                                                        "VAT Reporting Date" = field(upperlimit("VAT Reporting Date Filter")),
                                                        "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Net Change"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("No."),
                                                        "G/L Account No." = field(filter(Totaling)),
                                                        "Business Unit Code" = field("Business Unit Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Posting Date" = field("Date Filter"),
                                                        "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                        "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Budget Entry".Amount where("G/L Account No." = field("No."),
                                                               "G/L Account No." = field(filter(Totaling)),
                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                               "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                               "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                               Date = field("Date Filter"),
                                                               "Budget Name" = field("Budget Filter"),
                                                               "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Budgeted Amount';
            FieldClass = FlowField;
        }
        field(34; Totaling; Text[250])
        {
            Caption = 'Totaling';

            trigger OnValidate()
            begin
                if not IsTotaling() then
                    FieldError("Account Type");
                CalcFields(Balance);

                UpdateMyAccount(FieldNo(Totaling));
            end;
        }
        field(35; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        field(36; Balance; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("No."),
                                                        "G/L Account No." = field(filter(Totaling)),
                                                        "Business Unit Code" = field("Business Unit Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Budget at Date"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Budget Entry".Amount where("G/L Account No." = field("No."),
                                                               "G/L Account No." = field(filter(Totaling)),
                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                               "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                               "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                               Date = field(upperlimit("Date Filter")),
                                                               "Budget Name" = field("Budget Filter"),
                                                               "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Budget at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; "Consol. Translation Method"; Option)
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Translation Method';
            OptionCaption = 'Average Rate (Manual),Closing Rate,Historical Rate,Composite Rate,Equity Rate';
            OptionMembers = "Average Rate (Manual)","Closing Rate","Historical Rate","Composite Rate","Equity Rate";

            trigger OnValidate()
            var
                ConflictGLAcc: Record "G/L Account";
            begin
                if TranslationMethodConflict(ConflictGLAcc) then
                    if ConflictGLAcc.GetFilter("Consol. Debit Acc.") <> '' then
                        Message(
                          Text002, ConflictGLAcc.TableCaption(), ConflictGLAcc."No.", ConflictGLAcc.FieldCaption("Consol. Debit Acc."),
                          ConflictGLAcc.FieldCaption("Consol. Translation Method"), ConflictGLAcc."Consol. Translation Method")
                    else
                        Message(
                          Text002, ConflictGLAcc.TableCaption(), ConflictGLAcc."No.", ConflictGLAcc.FieldCaption("Consol. Credit Acc."),
                          ConflictGLAcc.FieldCaption("Consol. Translation Method"), ConflictGLAcc."Consol. Translation Method");
            end;
        }
        field(40; "Consol. Debit Acc."; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Debit Acc.';

            trigger OnValidate()
            var
                ConflictGLAcc: Record "G/L Account";
            begin
                if TranslationMethodConflict(ConflictGLAcc) then
                    Message(
                      Text002, ConflictGLAcc.TableCaption(), ConflictGLAcc."No.", ConflictGLAcc.FieldCaption("Consol. Debit Acc."),
                      ConflictGLAcc.FieldCaption("Consol. Translation Method"), ConflictGLAcc."Consol. Translation Method");
            end;
        }
        field(41; "Consol. Credit Acc."; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Credit Acc.';

            trigger OnValidate()
            var
                ConflictGLAcc: Record "G/L Account";
            begin
                if TranslationMethodConflict(ConflictGLAcc) then
                    Message(
                      Text002, ConflictGLAcc.TableCaption(), ConflictGLAcc."No.", ConflictGLAcc.FieldCaption("Consol. Credit Acc."),
                      ConflictGLAcc.FieldCaption("Consol. Translation Method"), ConflictGLAcc."Consol. Translation Method");
            end;
        }
        field(42; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(43; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            ToolTip = 'Specifies the general posting type to use when posting to this account.';
        }
        field(44; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(45; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                CheckOrdersPrepmtToDeduct(FieldCaption("Gen. Prod. Posting Group"));
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(46; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
        }
        field(47; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("G/L Entry"."Debit Amount" where("G/L Account No." = field("No."),
                                                                "G/L Account No." = field(filter(Totaling)),
                                                                "Business Unit Code" = field("Business Unit Filter"),
                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                "Posting Date" = field("Date Filter"),
                                                                "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                                "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("G/L Entry"."Credit Amount" where("G/L Account No." = field("No."),
                                                                 "G/L Account No." = field(filter(Totaling)),
                                                                 "Business Unit Code" = field("Business Unit Filter"),
                                                                 "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                 "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                 "Posting Date" = field("Date Filter"),
                                                                 "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                                 "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(52; "Budgeted Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankNumbers = BlankNegAndZero;
            CalcFormula = sum("G/L Budget Entry".Amount where("G/L Account No." = field("No."),
                                                               "G/L Account No." = field(filter(Totaling)),
                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                               "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                               "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                               Date = field("Date Filter"),
                                                               "Budget Name" = field("Budget Filter"),
                                                               "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Budgeted Debit Amount';
            FieldClass = FlowField;
        }
        field(53; "Budgeted Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankNumbers = BlankNegAndZero;
            CalcFormula = - sum("G/L Budget Entry".Amount where("G/L Account No." = field("No."),
                                                                "G/L Account No." = field(filter(Totaling)),
                                                                "Business Unit Code" = field("Business Unit Filter"),
                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                Date = field("Date Filter"),
                                                                "Budget Name" = field("Budget Filter"),
                                                                "Dimension Set ID" = field("Dimension Set ID Filter")));
            Caption = 'Budgeted Credit Amount';
            FieldClass = FlowField;
        }
        field(54; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(55; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(56; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(57; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
        }
        field(58; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';

            trigger OnValidate()
            begin
                CheckOrdersPrepmtToDeduct(FieldCaption("VAT Prod. Posting Group"));
            end;
        }
        field(59; "VAT Amt."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry"."VAT Amount" where("G/L Account No." = field("No."),
                                                              "G/L Account No." = field(filter(Totaling)),
                                                              "Business Unit Code" = field("Business Unit Filter"),
                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                              "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                              "Posting Date" = field("Date Filter")));
            Caption = 'VAT Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Additional-Currency Net Change"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Additional-Currency Amount" where("G/L Account No." = field("No."),
                                                                              "G/L Account No." = field(filter(Totaling)),
                                                                              "Business Unit Code" = field("Business Unit Filter"),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                                              "Posting Date" = field("Date Filter")));
            Caption = 'Additional-Currency Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Add.-Currency Balance at Date"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Additional-Currency Amount" where("G/L Account No." = field("No."),
                                                                              "G/L Account No." = field(filter(Totaling)),
                                                                              "Business Unit Code" = field("Business Unit Filter"),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "VAT Reporting Date" = field(upperlimit("VAT Reporting Date Filter")),
                                                                              "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Add.-Currency Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Additional-Currency Balance"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Additional-Currency Amount" where("G/L Account No." = field("No."),
                                                                              "G/L Account No." = field(filter(Totaling)),
                                                                              "Business Unit Code" = field("Business Unit Filter"),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Additional-Currency Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Exchange Rate Adjustment"; Enum "Exch. Rate Adjustment Type")
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Exchange Rate Adjustment';
        }
        field(64; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Add.-Currency Debit Amount" where("G/L Account No." = field("No."),
                                                                              "G/L Account No." = field(filter(Totaling)),
                                                                              "Business Unit Code" = field("Business Unit Filter"),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                                              "Posting Date" = field("Date Filter")));
            Caption = 'Add.-Currency Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Add.-Currency Credit Amount" where("G/L Account No." = field("No."),
                                                                               "G/L Account No." = field(filter(Totaling)),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                                               "Posting Date" = field("Date Filter")));
            Caption = 'Add.-Currency Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Default IC Partner G/L Acc. No"; Code[20])
        {
            Caption = 'Default IC Partner G/L Acc. No';
            TableRelation = "IC G/L Account"."No.";
        }
        field(70; "Omit Default Descr. in Jnl."; Boolean)
        {
            Caption = 'Omit Default Descr. in Jnl.';
        }
        field(75; "Source Currency Net Change"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Source Currency Amount" where("G/L Account No." = field("No."),
                                                                          "G/L Account No." = field(filter(Totaling)),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "VAT Reporting Date" = field("VAT Reporting Date Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Source Currency Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76; "Source Curr. Balance at Date"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Source Currency Amount" where("G/L Account No." = field("No."),
                                                                          "G/L Account No." = field(filter(Totaling)),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "VAT Reporting Date" = field(upperlimit("VAT Reporting Date Filter")),
                                                                          "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Source Curr. Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Source Currency Balance"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Source Currency Amount" where("G/L Account No." = field("No."),
                                                                          "G/L Account No." = field(filter(Totaling)),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Source Currency Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "Account Subcategory Entry No."; Integer)
        {
            Caption = 'Account Subcategory Entry No.';
            TableRelation = "G/L Account Category";

            trigger OnValidate()
            var
                GLAccountCategory: Record "G/L Account Category";
            begin
                if "Account Subcategory Entry No." = 0 then
                    exit;
                GLAccountCategory.Get("Account Subcategory Entry No.");
                TestField("Income/Balance", GLAccountCategory."Income/Balance");
                "Account Category" := Enum::"G/L Account Category".FromInteger(GLAccountCategory."Account Category");
            end;
        }
        field(81; "Account Subcategory Descript."; Text[80])
        {
            CalcFormula = lookup("G/L Account Category".Description where("Entry No." = field("Account Subcategory Entry No.")));
            Caption = 'Account Subcategory Descript.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(82; "VAT Reporting Date Filter"; Date)
        {
            Caption = 'VAT Reporting Date Filter';
            FieldClass = FlowFilter;
        }
        field(83; "Exclude From Consolidation"; Boolean)
        {
            Caption = 'Exclude from Consolidation';
            DataClassification = CustomerContent;
        }
        field(400; "Dimension Set ID Filter"; Integer)
        {
            Caption = 'Dimension Set ID Filter';
            FieldClass = FlowFilter;
        }
        field(1100; "Cost Type No."; Code[20])
        {
            Caption = 'Cost Type No.';
            Editable = false;
            TableRelation = "Cost Type";
            ValidateTableRelation = false;
        }
        field(1700; "Default Deferral Template Code"; Code[10])
        {
            Caption = 'Default Deferral Template Code';
            ToolTip = 'Specifies the default deferral template that governs how to defer revenues and expenses to the periods when they occurred.';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(9000; "API Account Type"; Enum "G/L Account Type")
        {
            Caption = 'API Account Type';
            Editable = false;
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
        key(Key3; "Reconciliation Account")
        {
        }
        key(Key4; "Gen. Bus. Posting Group")
        {
        }
        key(Key5; "Gen. Prod. Posting Group")
        {
        }
        key(Key6; "Consol. Debit Acc.", "Consol. Translation Method")
        {
            Enabled = false;
        }
        key(Key7; "Consol. Credit Acc.", "Consol. Translation Method")
        {
            Enabled = false;
        }
        key(Key8; Name)
        {
        }
        key(Key9; "Account Type")
        {
        }
        key(Key10; "Account Category")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Income/Balance", Blocked, "Direct Posting")
        {
        }
        fieldgroup(Brick; "No.", Name, "Income/Balance", Balance, Blocked)
        {
        }
    }

    trigger OnDelete()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        ExtTextHeader: Record "Extended Text Header";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        MyAccount: Record "My Account";
        ICGLAccount: Record "IC G/L Account";
        MoveEntries: Codeunit MoveEntries;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        MoveEntries.MoveGLEntries(Rec);

        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.");
        GLBudgetEntry.SetRange("G/L Account No.", "No.");
        GLBudgetEntry.DeleteAll(true);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"G/L Account");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.DeleteAll(true);

        AnalysisViewEntry.SetRange("Account No.", "No.");
        AnalysisViewEntry.DeleteAll();

        AnalysisViewBudgetEntry.SetRange("G/L Account No.", "No.");
        AnalysisViewBudgetEntry.DeleteAll();

        MyAccount.SetRange("Account No.", "No.");
        MyAccount.DeleteAll();

        ICGLAccount.SetRange("Map-to G/L Acc. No.", Rec."No.");
        if not ICGLAccount.IsEmpty() then
            ICGLAccount.ModifyAll("Map-to G/L Acc. No.", '');

        DimMgt.DeleteDefaultDim(DATABASE::"G/L Account", "No.");
    end;

    trigger OnInsert()
    begin
        DimMgt.UpdateDefaultDim(DATABASE::"G/L Account", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        SetLastModifiedDateTime();

        if CostAccSetup.Get() then
            CostAccMgt.UpdateCostTypeFromGLAcc(Rec, xRec, 0);

        if Indentation < 0 then
            Indentation := 0;
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();

        if CostAccSetup.Get() then
            if CurrFieldNo <> 0 then
                CostAccMgt.UpdateCostTypeFromGLAcc(Rec, xRec, 1)
            else
                CostAccMgt.UpdateCostTypeFromGLAcc(Rec, xRec, 0);

        if Indentation < 0 then
            Indentation := 0;
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::"G/L Account", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::"G/L Account", xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::"G/L Account", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"G/L Account", xRec."No.", "No.");
        JobPlanningLine.RenameNo(JobPlanningLine.Type::"G/L Account", xRec."No.", "No.");

        SetLastModifiedDateTime();

        if CostAccSetup.ReadPermission then
            CostAccMgt.UpdateCostTypeFromGLAcc(Rec, xRec, 3);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CostAccSetup: Record "Cost Accounting Setup";
        CommentLine: Record "Comment Line";
        DimMgt: Codeunit DimensionManagement;
        CostAccMgt: Codeunit "Cost Account Mgt";
        GLSetupRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot change %1 because there are one or more ledger entries associated with this account.';
        Text001: Label 'You cannot change %1 because this account is part of one or more budgets.';
        Text002: Label 'There is another %1: %2; which refers to the same %3, but with a different %4: %5.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NoAccountCategoryMatchErr: Label 'There is no subcategory description for %1 that matches ''%2''.', Comment = '%1=account category value, %2=the user input.';
        GenProdPostingGroupErr: Label '%1 is not set for the %2 G/L account with no. %3.', Comment = '%1 - caption Gen. Prod. Posting Group; %2 - G/L Account Description; %3 - G/L Account No.';
        CannotChangeSetupOnPrepmtAccErr: Label 'You cannot change %2 on account %3 while %1 is pending prepayment.', Comment = '%2 - field caption, %3 - account number, %1 - recordId - "Sales Header: Order, 1001".';
        CurrencyCodeErr: Label 'Currency codes are only allowed for assets and liabilities and posting account.';
        BalanceMustBeZeroErr: Label 'In order to change the currency code, the balance of the account must be zero.';

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::"G/L Account";
        PriceAsset."Asset No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;

    procedure SetupNewGLAcc(OldGLAcc: Record "G/L Account"; BelowOldGLAcc: Boolean)
    var
        OldGLAcc2: Record "G/L Account";
    begin
        if not BelowOldGLAcc then begin
            OldGLAcc2 := OldGLAcc;
            OldGLAcc.Copy(Rec);
            OldGLAcc := OldGLAcc2;
            if not OldGLAcc.Find('<') then
                OldGLAcc.Init();
        end;
        "Income/Balance" := OldGLAcc."Income/Balance";

        OnAfterSetupNewGLAcc(Rec);
    end;

    procedure CheckGLAcc()
    begin
        TestField("Account Type", "Account Type"::Posting);
        TestField(Blocked, false);

        OnAfterCheckGLAcc(Rec);
    end;

    procedure ValidateAccountSubCategory(NewValue: Text[80])
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if NewValue = "Account Subcategory Descript." then
            exit;
        if NewValue = '' then
            Validate("Account Subcategory Entry No.", 0)
        else begin
            GLAccountCategory.SetRange("Account Category", "Account Category");
            GLAccountCategory.SetRange(Description, NewValue);
            if not GLAccountCategory.FindFirst() then begin
                GLAccountCategory.SetFilter(Description, '''@*' + NewValue + '*''');
                if not GLAccountCategory.FindFirst() then
                    Error(NoAccountCategoryMatchErr, "Account Category", NewValue);
            end;
            Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        end;
        GLAccountCategory.ShowNotificationAccSchedUpdateNeeded();
    end;

    procedure LookupAccountSubCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: Page "G/L Account Categories";
    begin
        if "Account Subcategory Entry No." <> 0 then
            if GLAccountCategory.Get("Account Subcategory Entry No.") then
                GLAccountCategories.SetRecord(GLAccountCategory);
        GLAccountCategory.SetRange("Income/Balance", "Income/Balance");
        if "Account Category" <> "Account Category"::" " then
            GLAccountCategory.SetRange("Account Category", "Account Category");
        GLAccountCategories.SetTableView(GLAccountCategory);
        GLAccountCategories.LookupMode(true);
        if GLAccountCategories.RunModal() = ACTION::LookupOK then begin
            GLAccountCategories.GetRecord(GLAccountCategory);
            Validate("Account Category", GLAccountCategory."Account Category");
            "Account Subcategory Entry No." := GLAccountCategory."Entry No.";
            GLAccountCategory.ShowNotificationAccSchedUpdateNeeded();
        end;
        CalcFields("Account Subcategory Descript.");
    end;

    local procedure UpdateAccountCategoryOfSubAccounts()
    var
        GLAccountSubAccount: Record "G/L Account";
    begin
        if "Account Type" <> "Account Type"::"Begin-Total" then
            exit;

        GLAccountSubAccount.SetFilter("No.", '>%1', "No.");
        GLAccountSubAccount.SetRange(Indentation, Indentation, Indentation + 1);
        GLAccountSubAccount.SetFilter("Account Category", '%1|%2', "Account Category"::" ", xRec."Account Category");

        if not GLAccountSubAccount.FindSet() then
            exit;

        repeat
            if (GLAccountSubAccount.Indentation = Indentation) and
               (GLAccountSubAccount."Account Type" <> "Account Type"::"End-Total")
            then
                exit;

            GLAccountSubAccount.Validate("Account Category", "Account Category");
            GLAccountSubAccount.Modify();
        until GLAccountSubAccount.Next() = 0;
    end;

    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"G/L Account", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure TranslationMethodConflict(var GLAcc: Record "G/L Account"): Boolean
    begin
        GLAcc.Reset();
        GLAcc.SetFilter("No.", '<>%1', "No.");
        GLAcc.SetFilter("Consol. Translation Method", '<>%1', "Consol. Translation Method");
        if "Consol. Debit Acc." <> '' then begin
            if not GLAcc.SetCurrentKey("Consol. Debit Acc.", "Consol. Translation Method") then
                GLAcc.SetCurrentKey("No.");
            GLAcc.SetRange("Consol. Debit Acc.", "Consol. Debit Acc.");
            if GLAcc.Find('-') then
                exit(true);
            GLAcc.SetRange("Consol. Debit Acc.");
        end;
        if "Consol. Credit Acc." <> '' then begin
            if not GLAcc.SetCurrentKey("Consol. Credit Acc.", "Consol. Translation Method") then
                GLAcc.SetCurrentKey("No.");
            GLAcc.SetRange("Consol. Credit Acc.", "Consol. Credit Acc.");
            if GLAcc.Find('-') then
                exit(true);
            GLAcc.SetRange("Consol. Credit Acc.");
        end;
        exit(false);
    end;

    procedure CheckGenProdPostingGroup()
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenProdPostingGroup(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Gen. Prod. Posting Group" = '' then
            ErrorMessageManagement.LogContextFieldError(
                0,
                StrSubstNo(GenProdPostingGroupErr, FieldCaption("Gen. Prod. Posting Group"), Name, "No."),
                Rec,
                FieldNo("Gen. Prod. Posting Group"),
                ForwardLinkMgt.GetHelpCodeForEmptyPostingSetupAccount());
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        "Last Date Modified" := Today;
    end;

    local procedure CheckOrdersPrepmtToDeduct(FldCaption: Text)
    begin
        CheckPurchaseOrdersPrepmtToDeduct(FldCaption);
        CheckSalesOrdersPrepmtToDeduct(FldCaption);
    end;

    local procedure CheckSalesOrdersPrepmtToDeduct(FldCaption: Text)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesOrdersPrepmtToDeduct(Rec, IsHandled);
        if IsHandled then
            exit;

        GeneralPostingSetup.SetLoadFields("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
        GeneralPostingSetup.SetRange("Sales Prepayments Account", "No.");
        if GeneralPostingSetup.FindSet() then
            repeat
                GeneralPostingSetup.CheckPrepmtSalesLinesToDeduct(
                    StrSubstNo(CannotChangeSetupOnPrepmtAccErr, '%1', FldCaption, "No."));
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure CheckPurchaseOrdersPrepmtToDeduct(FldCaption: Text)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetLoadFields("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
        GeneralPostingSetup.SetRange("Purch. Prepayments Account", "No.");
        if GeneralPostingSetup.FindSet() then
            repeat
                GeneralPostingSetup.CheckPrepmtPurchLinesToDeduct(
                    StrSubstNo(CannotChangeSetupOnPrepmtAccErr, '%1', FldCaption, "No."));
            until GeneralPostingSetup.Next() = 0;
    end;

    procedure IsTotaling(): Boolean
    begin
        exit("Account Type" in ["Account Type"::Total, "Account Type"::"End-Total"]);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"My Account", 'rm')]
    local procedure UpdateMyAccount(CallingFieldNo: Integer)
    var
        MyAccount: Record "My Account";
    begin
        case CallingFieldNo of
            FieldNo(Name):
                begin
                    MyAccount.SetRange("Account No.", "No.");
                    if not MyAccount.IsEmpty() then
                        MyAccount.ModifyAll(Name, Name);
                end;
            FieldNo(Totaling):
                begin
                    MyAccount.SetRange("Account No.", "No.");
                    if not MyAccount.IsEmpty() then
                        MyAccount.ModifyAll(Totaling, Totaling);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewGLAcc(var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GLAccount: Record "G/L Account"; var xGLAccount: Record "G/L Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var GLAccount: Record "G/L Account"; var xGLAccount: Record "G/L Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenProdPostingGroup(var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesOrdersPrepmtToDeduct(var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;
}
