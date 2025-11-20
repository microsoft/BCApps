// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;

page 16 "Chart of Accounts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Chart of Accounts';
    CardPageID = "G/L Account Card";
    PageType = List;
    QueryCategory = 'Chart of Accounts';
    RefreshOnActivate = true;
    SourceTable = "G/L Account";
    UsageCategory = Lists;
    AdditionalSearchTerms = 'Account List, Financial Accounts, Ledger Overview, Balance Sheet Accounts, G/L Overview, Accounting Chart, Financial Chart, Ledger Chart, G/L List, Account Chart, CoA';

    AboutTitle = 'About the chart of accounts';
    AboutText = 'The chart of accounts is the core of the financials. It''s used to group income and expenses in the income statement and balance sheet. Define indentation levels for a structured overview of your financials. The chart of accounts should reflect how the business is organized.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NoEmphasize;
                    ToolTip = 'Specifies the account number in the chart of accounts. Accounts numbers are typically numbered according to their place in the income statement or balance sheet.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the general ledger account.';
                    Width = 60;

                    trigger OnValidate()
                    var
                        FinancialReportMgt: Codeunit "Financial Report Mgt.";
                    begin
                        if (Rec.Name <> xRec.Name) and (xRec.Name <> '') then
                            FinancialReportMgt.NotifyUpdateRowDefinition(Rec);
                    end;
                }
                field("Net Change"; Rec."Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                    AboutTitle = 'What is behind the numbers';
                    AboutText = 'Tap or click on amounts to drill down and see the underlying entries to learn what is behind the numbers for insight and troubleshooting.';
                    Visible = AmountVisible;
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account.';
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Category"; Rec."Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the G/L account.';
                }
                field("Account Subcategory Descript."; Rec."Account Subcategory Descript.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Subcategory';
                    DrillDown = false;
                    ToolTip = 'Specifies the subcategory of the account category of the G/L account.';
                    AboutTitle = 'Structure the chart of accounts';
                    AboutText = 'Group your accounts into categories and subcategories to provide structure to the financial overview.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field("Direct Posting"; Rec."Direct Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you will be able to post directly or only indirectly to this general ledger account.';
                    Visible = false;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLaccList: Page "G/L Account List";
                    begin
                        GLaccList.LookupMode(true);
                        if not (GLaccList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := GLaccList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type to use when posting to this account.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = DebitCreditVisible;
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field("Additional-Currency Net Change"; Rec."Additional-Currency Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance.';
                    Visible = false;
                }
                field("Add.-Currency Balance at Date"; Rec."Add.-Currency Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance, in the additional reporting currency, on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field("Additional-Currency Balance"; Rec."Additional-Currency Balance")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account, in the additional reporting currency.';
                    Visible = false;
                }
                field("Consol. Debit Acc."; Rec."Consol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number in a consolidated company to transfer credit balances.';
                    Visible = false;
                }
                field("Consol. Credit Acc."; Rec."Consol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts without any payment tolerance amount from the customer and vendor ledger entries are used.';
                    Visible = false;
                }
                field("Source Currency Posting"; Rec."Source Currency Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how amounts in foreign currencies should be posted to this account.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
                field("Source Currency Code"; Rec."Source Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the allowed source currency code if Source Currency Posting value is Same Currency.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
                field("Source Currency Balance"; Rec."Source Currency Balance")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the foreign currency balance on the G/L account.';
                    Visible = false;
                }
                field("Source Curr. Balance at Date"; Rec."Source Curr. Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account foreign currency balance on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field("Cost Type No."; Rec."Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a cost type number to establish which cost type a general ledger account belongs to.';
                }
                field("Consol. Translation Method"; Rec."Consol. Translation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the consolidation translation method that will be used for the account.';
                    Visible = false;
                }
                field("Default IC Partner G/L Acc. No"; Rec."Default IC Partner G/L Acc. No")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies accounts that you often enter in the Bal. Account No. field on intercompany journal or document lines.';
                    Visible = false;
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    ToolTip = 'Specifies the default deferral template that governs how to defer revenues and expenses to the periods when they occurred.';
                }
                field("No. 2"; Rec."No. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternative account number which can be used internally in the company.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
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
                    RunPageView = sorting("G/L Account No.");
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
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(15),
                                      "No." = field("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            GLAcc: Record "G/L Account";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(GLAcc);
                            DefaultDimMultiple.SetMultiRecord(GLAcc, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                    action(SetDimensionFilter)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Set Dimension Filter';
                        Ellipsis = true;
                        Image = "Filter";
                        ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                        trigger OnAction()
                        begin
                            Rec.SetFilter("Dimension Set ID Filter", DimensionSetIDFilter.LookupFilter());
                        end;
                    }
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
                    ToolTip = 'View additional information that has been added to the description for the current account.';
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
                    ToolTip = 'Show setup tables where the current account is used.';

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
                    RunPageLink = "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
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
                action("G/L Account Balance/Bud&get")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Balance/Bud&get';
                    Image = Period;
                    RunObject = Page "G/L Account Balance/Budget";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter"),
                                  "Budget Filter" = field("Budget Filter");
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';
                }
                action("G/L Balance/B&udget")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Balance/B&udget';
                    Image = ChartOfAccounts;
                    RunObject = Page "G/L Balance/Budget";
                    RunPageLink = "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter"),
                                  "Budget Filter" = field("Budget Filter");
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';
                }
                action("Chart of Accounts &Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart of Accounts &Overview';
                    Image = Accounts;
                    RunObject = Page "Chart of Accounts Overview";
                    ToolTip = 'View the chart of accounts with different levels of detail where you can expand or collapse a section of the chart of accounts.';
                }
            }
            action("G/L Register")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Register';
                Image = GLRegisters;
                RunObject = Page "G/L Registers";
                ToolTip = 'View posted G/L entries.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(IndentChartOfAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Indent Chart of Accounts';
                    Image = IndentChartOfAccounts;
                    RunObject = Codeunit "G/L Account-Indent";
                    ToolTip = 'Indent accounts between a Begin-Total and the matching End-Total one level to make the chart of accounts easier to read.';
                }
            }
            group("Periodic Activities")
            {
                Caption = 'Periodic Activities';
                action("General Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal';
                    Image = Journal;
                    RunObject = Page "General Journal";
                    ToolTip = 'Open the general journal, for example, to record or post a payment that has no related document.';
                }
                action("G/L Currency Revaluation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Currency Revaluation';
                    Image = CurrencyExchangeRates;
                    RunObject = Report "G/L Currency Revaluation";
                    ToolTip = 'Create general journal lines with currency revaluation for G/L accounts with posting in source currency.';
#if not CLEAN25
                    Visible = SourceCurrencyVisible;
#endif
                }
                action("Close Income Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close Income Statement';
                    Image = CloseYear;
                    RunObject = Report "Close Income Statement";
                    ToolTip = 'Start the transfer of the year''s result to an account in the balance sheet and close the income statement accounts.';
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
        }
        area(reporting)
        {
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Detail Trial Balance";
                ToolTip = 'View a detail trial balance for the general ledger accounts that you specify.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View the chart of accounts that have balances and net changes.';
                AboutTitle = 'Get the financial overview';
                AboutText = 'With the **Trial Balance** reports you get the balance sheet, income statement, or the full trial balance.';
            }
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
            }
            action(Action1900210206)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Register';
                Image = "Report";
                RunObject = Report "G/L Register";
                ToolTip = 'View posted G/L entries.';
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
                actionref(IndentChartOfAccounts_Promoted; IndentChartOfAccounts)
                {
                }
                actionref("G/L Currency Revaluation_Promoted"; "G/L Currency Revaluation")
                {
                }
                actionref("Close Income Statement_Promoted"; "Close Income Statement")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Periodic Activities', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Account', Comment = 'Generated from the PromotedActionCategories property index 4.';

                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                    {
                    }
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(SetDimensionFilter_Promoted; SetDimensionFilter)
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
            group(Category_Category6)
            {
                Caption = 'Balance', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("G/L &Account Balance_Promoted"; "G/L &Account Balance")
                {
                }
                actionref("G/L &Balance_Promoted"; "G/L &Balance")
                {
                }
                actionref("G/L Balance by &Dimension_Promoted"; "G/L Balance by &Dimension")
                {
                }
                actionref("G/L Account Balance/Bud&get_Promoted"; "G/L Account Balance/Bud&get")
                {
                }
                actionref("G/L Balance/B&udget_Promoted"; "G/L Balance/B&udget")
                {
                }
                actionref("Chart of Accounts &Overview_Promoted"; "Chart of Accounts &Overview")
                {
                }
            }
            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref("G/L Register_Promoted"; "G/L Register")
                {
                }
                actionref("General Journal_Promoted"; "General Journal")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Trial Balance by Period_Promoted"; "Trial Balance by Period")
                {
                }
                actionref("Detail Trial Balance_Promoted"; "Detail Trial Balance")
                {
                }
                actionref("Trial Balance_Promoted"; "Trial Balance")
                {
                }
                actionref(Action1900210206_Promoted; Action1900210206)
                {
                }
            }
        }
    }
    views
    {
        view(OnlyPostingAccounts)
        {
            Caption = 'Show only posting accounts';
            Filters = where("Account Type" = const(Posting));
        }
        view(Unblocked)
        {
            Caption = 'Hide blocked accounts';
            Filters = where(Blocked = const(false));
        }
    }

    trigger OnAfterGetRecord()
    begin
        NoEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
        NameIndent := Rec.Indentation;
        NameEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewGLAcc(xRec, BelowxRec);
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.NotifyUpdateFinancialReport(Rec);
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        NoEmphasize: Boolean;
        NameEmphasize: Boolean;
        NameIndent: Integer;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;
#if not CLEAN25
        SourceCurrencyVisible: Boolean;
#endif

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
#if not CLEAN25
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
#endif
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
#if not CLEAN25
        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, ClientType::Api]
        then
            SourceCurrencyVisible := false
        else
            SourceCurrencyVisible := FeatureKeyManagement.IsGLCurrencyRevaluationEnabled();
#endif
    end;
}

