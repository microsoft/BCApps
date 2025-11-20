// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using System.IO;

page 17 "G/L Account Card"
{
    Caption = 'G/L Account Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "G/L Account";
    AdditionalSearchTerms = 'Financial Account, Ledger, Balance Sheet Account, G/L, Accounting, Financial Chart, Ledger Chart, Account Chart, CoA';

    AboutTitle = 'About G/L account details';
    AboutText = 'Choose the settings appropriate for the transactions that are posted to this *general ledger* account.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    AboutTitle = 'Accounts are ordered by No.';
                    AboutText = 'The account number (No.) determines where this account will appear in the chart of accounts.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the general ledger account.';

                    trigger OnValidate()
                    var
                        FinancialReportMgt: Codeunit "Financial Report Mgt.";
                    begin
                        if (Rec.Name <> xRec.Name) and (xRec.Name <> '') then
                            FinancialReportMgt.NotifyUpdateRowDefinition(Rec);
                    end;
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Category"; Rec."Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the G/L account.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        UpdateAccountSubcategoryDescription();
                    end;
                }
                field(SubCategoryDescription; SubCategoryDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Subcategory';
                    ToolTip = 'Specifies the subcategory of the account category of the G/L account.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupAccountSubCategory();
                        UpdateAccountSubcategoryDescription();
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateAccountSubCategory(SubCategoryDescription);
                        UpdateAccountSubcategoryDescription();
                    end;
                }
                field("Debit/Credit"; Rec."Debit/Credit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entries that will normally be posted to this general ledger account.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccountList: Page "G/L Account List";
                        OldText: Text;
                    begin
                        OldText := Text;
                        GLAccountList.LookupMode(true);
                        if not (GLAccountList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := OldText + GLAccountList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("No. of Blank Lines"; Rec."No. of Blank Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of blank lines that you want inserted before this account in the chart of accounts.';
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether you want a new page to start immediately after this general ledger account when you print the chart of accounts. Select this field to start a new page after this general ledger account.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the balance on this account.';
                }
                field("Reconciliation Account"; Rec."Reconciliation Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this general ledger account will be included in the Reconciliation window in the general journal. To have the G/L account included in the window, place a check mark in the check box. You can find the Reconciliation window by clicking Actions, Posting in the General Journal window.';
                }
                field("Automatic Ext. Texts"; Rec."Automatic Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that an extended text will be added automatically to the account.';
                }
                field("Direct Posting"; Rec."Direct Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you can post directly to this general ledger account. If the field is not selected, then users must use sales documents, for example, and not post directly to the general ledger.';
                    AboutTitle = 'Is direct posting allowed?';
                    AboutText = 'If you have control accounts for receivables and payables, then keep *Direct Posting* turned off as all transactions should be posted through customers and vendors.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the G/L account was last modified.';
                }
                field("Omit Default Descr. in Jnl."; Rec."Omit Default Descr. in Jnl.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the default description is automatically inserted in the Description field on journal lines created for this general ledger account.';
                }
                field("No. 2"; Rec."No. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternative account number which can be used internally in the company.';
                    Visible = false;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type to use when posting to this account.';
                    ValuesAllowed = " ", Purchase, Sale;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                }
                field("Default IC Partner G/L Acc. No"; Rec."Default IC Partner G/L Acc. No")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies accounts that you often enter in the Bal. Account No. field on intercompany journal or document lines.';
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    ToolTip = 'Specifies the default deferral template that governs how to defer revenues and expenses to the periods when they occurred.';
                }
            }
            group(Revaluation)
            {
                Caption = 'Revaluation';
#if not CLEAN25
                Visible = SourceCurrencyVisible;
#endif
                field("Source Currency Posting"; Rec."Source Currency Posting")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Currency Posting';
                    ToolTip = 'Specifies how the system will validate posting of entries containing currencies. Blank will allow all currencies to be posted to the account. Same Code will only allow the currency specified in Source Currency Code. Multiple currencies will allow only posting of currencies selected in Source currency code. Local currency only allow posting without a Currency code.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
                field("Source Currency Code"; Rec."Source Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Currency Code';
                    ToolTip = 'Specifies the source currency code which can be posted to this account, if Source Currency Posting is set as Same Code.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
                field("Source Currency Revaluation"; Rec."Source Currency Revaluation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Currency Revaluation';
                    ToolTip = 'Specifies if source currency revaluation should be done for this account.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
                field("Unrealized Revaluation"; Rec."Unrealized Revaluation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unrealized Revaluation';
                    ToolTip = 'Specifies if revaluation should be posted to currency realized or unrealized gains and losses accounts.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
            }
            group(Consolidation)
            {
                Caption = 'Consolidation';
                field("Consol. Debit Acc."; Rec."Consol. Debit Acc.")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the account in a consolidated company to which to transfer debit balances on this account.';
                }
                field("Consol. Credit Acc."; Rec."Consol. Credit Acc.")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the account in a consolidated company to which to transfer credit balances on this account.';
                }
                field("Consol. Translation Method"; Rec."Consol. Translation Method")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account''s consolidation translation method, which identifies the currency translation rate to be applied to the account.';
                }
                field("Exclude From Consolidation"; Rec."Exclude From Consolidation")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the account is excluded from consolidation.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Exchange Rate Adjustment"; Rec."Exchange Rate Adjustment")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how general ledger accounts will be adjusted for exchange rate fluctuations between LCY and the additional reporting currency.';
                }
            }
            group("Cost Accounting")
            {
                Caption = 'Cost Accounting';
                field("Cost Type No."; Rec."Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies a cost type number to establish which cost type a general ledger account belongs to.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Dimensions;
                SubPageLink = "Table ID" = const(15),
                              "No." = field("No.");
                Visible = false;
            }
            part(Control1905532108; "G/L Account Currency FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "G/L Account No." = field("No."),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                              "Date Filter" = field("Date Filter");
#if not CLEAN25
                Visible = SourceCurrencyVisible;
#endif
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("No.");
                    RunPageView = sorting("G/L Account No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(15),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action(SourceCurrencies)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Currencies';
                    Image = Currency;
                    RunObject = Page "G/L Account Source Currencies";
                    RunPageLink = "G/L Account No." = field("No.");
                    ToolTip = 'View or edit source currencies posting setup.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View additional information about a general ledger account, this supplements the Description field.';
                }
                action("Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    Caption = 'Receivables-Payables';
                    Image = ReceivablesPayables;
                    RunObject = Page "Receivables-Payables";
                    ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
                }
                action("Where-Used List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Where-Used List';
                    Image = Track;
                    ToolTip = 'View setup tables where a general ledger account is used.';

                    trigger OnAction()
                    var
                        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
                    begin
                        CalcGLAccWhereUsed.CheckGLAcc(Rec."No.");
                    end;
                }
            }
            group("&Balance")
            {
                Caption = '&Balance';
                Image = Balance;
                action("G/L &Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L &Account Balance';
                    Image = GLAccountBalance;
                    RunObject = Page "G/L Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ToolTip = 'View a summary of the debit and credit balances for different time periods, for the account that you select in the chart of accounts.';
                }
                action("G/L &Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L &Balance';
                    Image = GLBalance;
                    RunObject = Page "G/L Balance";
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the debit and credit balances for all the accounts in the chart of accounts, for the time period that you select.';
                }
                action("G/L Balance by &Dimension")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'G/L Balance by &Dimension';
                    Image = GLBalanceDimension;
                    RunObject = Page "G/L Balance by Dimension";
                    ToolTip = 'View a summary of the debit and credit balances by dimensions for the current account.';
                }
            }
            action("General Posting Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Posting Setup';
                Image = GeneralPostingSetup;
                RunObject = Page "General Posting Setup";
                ToolTip = 'View or edit how you want to set up combinations of general business and general product posting groups.';
            }
            action("VAT Posting Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Posting Setup';
                Image = VATPostingSetup;
                RunObject = Page "VAT Posting Setup";
                ToolTip = 'View or edit combinations of Tax business posting groups and Tax product posting groups.';
            }
            action("G/L Register")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Register';
                Image = GLRegisters;
                RunObject = Page "G/L Registers";
                ToolTip = 'View posted G/L entries.';
            }
            action(DocsWithoutIC)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Documents without Incoming Document';
                Image = Documents;
                ToolTip = 'Show a list of posted purchase and sales documents under the G/L account that do not have related incoming document records.';

                trigger OnAction()
                var
                    PostedDocsWithNoIncBuf: Record "Posted Docs. With No Inc. Buf.";
                begin
                    if Rec."Account Type" = Rec."Account Type"::Posting then
                        PostedDocsWithNoIncBuf.SetRange("G/L Account No. Filter", Rec."No.")
                    else
                        if Rec.Totaling <> '' then
                            PostedDocsWithNoIncBuf.SetFilter("G/L Account No. Filter", Rec.Totaling)
                        else
                            exit;
                    PAGE.Run(PAGE::"Posted Docs. With No Inc. Doc.", PostedDocsWithNoIncBuf);
                end;
            }
        }
        area(reporting)
        {
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Detail Trial Balance";
                ToolTip = 'View detail general ledger account balances and activities for all the selected accounts, one transaction per line.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View general ledger account balances and activities for all the selected accounts, one transaction per line.';
            }
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View general ledger account balances and activities for all the selected accounts, one transaction per line for a selected period.';
            }
            action(Action1900210206)
            {
                ApplicationArea = Suite;
                Caption = 'G/L Register';
                Image = GLRegisters;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "G/L Register";
                ToolTip = 'View posted G/L entries.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Apply Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    ToolTip = 'Select a configuration template to quickly create a general ledger account.';

                    trigger OnAction()
                    var
                        ConfigTemplateMgt: Codeunit "Config. Template Management";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        ConfigTemplateMgt.UpdateFromTemplateSelection(RecRef);
                    end;
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                Image = JobPrice;
                action(SalesPriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or edit sales prices for the account.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Any);
                    end;
                }
                action(PurchPriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Prices';
                    Image = Costs;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or edit purchase prices for the account.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Any);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(DocsWithoutIC_Promoted; DocsWithoutIC)
                {
                }
                actionref("Apply Template_Promoted"; "Apply Template")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Account', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Where-Used List_Promoted"; "Where-Used List")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref("E&xtended Texts_Promoted"; "E&xtended Texts")
                {
                }
                actionref("Receivables-Payables_Promoted"; "Receivables-Payables")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Balance', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("G/L &Account Balance_Promoted"; "G/L &Account Balance")
                {
                }
                actionref("G/L &Balance_Promoted"; "G/L &Balance")
                {
                }
                actionref("G/L Balance by &Dimension_Promoted"; "G/L Balance by &Dimension")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Prices & Discounts', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(SalesPriceLists_Promoted; SalesPriceLists)
                {
                }
                actionref(PurchPriceLists_Promoted; PurchPriceLists)
                {
                }
            }
            group(Category_Navigate)
            {
                Caption = 'Navigate';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateAccountSubcategoryDescription();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewGLAcc(xRec, BelowxRec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.NotifyUpdateFinancialReport(Rec);
    end;

    var
        ExtendedPriceEnabled: Boolean;
#if not CLEAN25
        SourceCurrencyVisible: Boolean;
#endif
        SubCategoryDescription: Text[80];

    local procedure UpdateAccountSubcategoryDescription()
    begin
        Rec.CalcFields("Account Subcategory Descript.");
        SubCategoryDescription := Rec."Account Subcategory Descript.";
    end;

    local procedure SetControlVisibility()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
#if not CLEAN25
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
#endif
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
#if not CLEAN25
        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, ClientType::Api]
then
            SourceCurrencyVisible := false
        else
            SourceCurrencyVisible := FeatureKeyManagement.IsGLCurrencyRevaluationEnabled();
#endif
    end;
}

