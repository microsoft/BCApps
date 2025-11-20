// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Reports;
using Microsoft.Bank.Setup;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Reports;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Reports;
using Microsoft.CostAccounting.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Reports;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Payables;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Reports;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reports;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Diagnostics;

page 8901 "Finance Manager Role Center"
{
    Caption = 'Finance Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'General Ledger';
                action("Chart of Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart of Accounts';
                    RunObject = page "Chart of Accounts";
                    Tooltip = 'Open the Chart of Accounts page.';
                }
                action("Budgets")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Budgets';
                    RunObject = page "G/L Budget Names";
                    Tooltip = 'Open the G/L Budgets page.';
                }
                action("Account Schedules")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Financial Reporting';
                    RunObject = page "Financial Reports";
                    Tooltip = 'Open the Account Schedules page.';
                }
                action("Analyses by Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis by Dimensions';
                    RunObject = page "Analysis View List";
                    Tooltip = 'Open the Analysis by Dimensions page.';
                }
                group("Group1")
                {
                    Caption = 'VAT';
                    action("VAT Statements")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statements';
                        RunObject = page "VAT Statement";
                        Tooltip = 'Open the VAT Statements page.';
                    }
                    action("VAT Returns")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Returns';
                        RunObject = page "VAT Report List";
                        Tooltip = 'Open the VAT Returns page.';
                    }
                    action("ECSL Report")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'EC Sales List Reports';
                        RunObject = page "EC Sales List Reports";
                        Tooltip = 'Open the EC Sales List Reports page.';
                    }
                    group("Group2")
                    {
                        Caption = 'Reports';
                        action("VAT Exceptions")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Exceptions';
                            RunObject = report "VAT Exceptions";
                            Tooltip = 'Run the VAT Exceptions report.';
                        }
                        action("VAT Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Register';
                            RunObject = report "VAT Register";
                            Tooltip = 'Run the VAT Register report.';
                        }
                        action("VAT Registration No. Check")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Batch VAT Registration No. Check';
                            RunObject = report "VAT Registration No. Check";
                            Tooltip = 'Run the Batch VAT Registration No. Check report.';
                        }
                        action("VAT Statement")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Statement';
                            RunObject = report "VAT Statement";
                            Tooltip = 'Run the VAT Statement report.';
                        }
                        action("VAT- VIES Declaration Tax Auth")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT- VIES Declaration Tax Auth';
                            RunObject = report "VAT- VIES Declaration Tax Auth";
                            Tooltip = 'Run the VAT- VIES Declaration Tax Auth report.';
                        }
                        action("VAT- VIES Declaration Disk")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT- VIES Declaration Disk...';
                            RunObject = report "VAT- VIES Declaration Disk";
                            Tooltip = 'Run the VAT- VIES Declaration Disk report.';
                        }
                        action("Day Book VAT Entry")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Day Book VAT Entry';
                            RunObject = report "Day Book VAT Entry";
                            Tooltip = 'Run the Day Book VAT Entry report.';
                        }
                        action("Day Book Cust. Ledger Entry")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Day Book Cust. Ledger Entry';
                            RunObject = report "Day Book Cust. Ledger Entry";
                            Tooltip = 'Run the Day Book Cust. Ledger Entry report.';
                        }
                        action("Day Book Vendor Ledger Entry")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Day Book Vendor Ledger Entry';
                            RunObject = report "Day Book Vendor Ledger Entry";
                            Tooltip = 'Run the Day Book Vendor Ledger Entry report.';
                        }
                    }
                }
                group("Group3")
                {
                    Caption = 'Intercompany';
                    action("General Journals")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany General Journal';
                        RunObject = page "IC General Journal";
                        Tooltip = 'Open the Intercompany General Journal page.';
                    }
                    action("Inbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Inbox Transactions';
                        RunObject = page "IC Inbox Transactions";
                        Tooltip = 'Open the Intercompany Inbox Transactions page.';
                    }
                    action("Outbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Outbox Transactions';
                        RunObject = page "IC Outbox Transactions";
                        Tooltip = 'Open the Intercompany Outbox Transactions page.';
                    }
                    action("Handled Inbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Handled Intercompany Inbox Transactions';
                        RunObject = page "Handled IC Inbox Transactions";
                        Tooltip = 'Open the Handled Intercompany Inbox Transactions page.';
                    }
                    action("Handled Outbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Handled Intercompany Outbox Transactions';
                        RunObject = page "Handled IC Outbox Transactions";
                        Tooltip = 'Open the Handled Intercompany Outbox Transactions page.';
                    }
                    action("Intercompany Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'IC Transaction';
                        RunObject = report "IC Transactions";
                        Tooltip = 'Run the IC Transaction report.';
                    }
                }
                group("Group4")
                {
                    Caption = 'Consolidation';
                    action("Business Units")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Business Units';
                        RunObject = page "Business Unit List";
                        Tooltip = 'Open the Business Units page.';
                    }
                    action("Export Consolidation")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Export Consolidation...';
                        RunObject = report "Export Consolidation";
                        Tooltip = 'Run the Export Consolidation report.';
                    }
                    action("G/L Consolidation Eliminations")
                    {
                        ApplicationArea = Suite;
                        Caption = 'G/L Consolidation Eliminations';
                        RunObject = report "G/L Consolidation Eliminations";
                        Tooltip = 'Run the G/L Consolidation Eliminations report.';
                    }
                }
                group("Group5")
                {
                    Caption = 'Journals';
                    action("General Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Journals';
                        RunObject = page "General Journal";
                        Tooltip = 'Open the General Journals page.';
                    }
                    action("Recurring Journals")
                    {
                        ApplicationArea = Suite, FixedAssets;
                        Caption = 'Recurring General Journals';
                        RunObject = page "Recurring General Journal";
                        Tooltip = 'Open the Recurring General Journals page.';
                    }
                    action("General Journals2")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany General Journal';
                        RunObject = page "IC General Journal";
                        Tooltip = 'Open the Intercompany General Journal page.';
                    }
                }
                group("Group6")
                {
                    Caption = 'Register/Entries';
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = page "G/L Registers";
                        Tooltip = 'Open the G/L Registers page.';
                    }
                    action("Navigate")
                    {
                        ApplicationArea = Basic, Suite, FixedAssets, CostAccounting;
                        Caption = 'Find entries...';
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                        RunObject = page "Navigate";
                    }
                    action("General Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Ledger Entries';
                        RunObject = page "General Ledger Entries";
                        Tooltip = 'Open the General Ledger Entries page.';
                    }
                    action("G/L Budget Entries")
                    {
                        ApplicationArea = Suite;
                        Caption = 'G/L Budget Entries';
                        RunObject = page "G/L Budget Entries";
                        Tooltip = 'Open the G/L Budget Entries page.';
                    }
                    action("VAT Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Entries';
                        RunObject = page "VAT Entries";
                        Tooltip = 'Open the VAT Entries page.';
                    }
                    action("Analysis View Entries")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis View Entries';
                        RunObject = page "Analysis View Entries";
                        Tooltip = 'Open the Analysis View Entries page.';
                    }
                    action("Analysis View Budget Entries")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis View Budget Entries';
                        RunObject = page "Analysis View Budget Entries";
                        Tooltip = 'Open the Analysis View Budget Entries page.';
                    }
                    action("Item Budget Entries")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Item Budget Entries';
                        RunObject = page "Item Budget Entries";
                        Tooltip = 'Open the Item Budget Entries page.';
                    }
                }
                group("Group7")
                {
                    Caption = 'Reports';
                    group("Group8")
                    {
                        Caption = 'Entries';
                        action("G/L Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Register';
                            RunObject = report "G/L Register";
                            Tooltip = 'Run the G/L Register report.';
                        }
                        action("Detail Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Detail Trial Balance';
                            RunObject = report "Detail Trial Balance";
                            Tooltip = 'Run the Detail Trial Balance report.';
                        }
                        action("Dimensions - Detail")
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimensions - Detail';
                            RunObject = report "Dimensions - Detail";
                            Tooltip = 'Run the Dimensions - Detail report.';
                        }
                        action("Dimensions - Total")
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimensions - Total';
                            RunObject = report "Dimensions - Total";
                            Tooltip = 'Run the Dimensions - Total report.';
                        }
                        action("Check Value Posting")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimension Check Value Posting';
                            RunObject = report "Check Value Posting";
                            Tooltip = 'Run the Dimension Check Value Posting report.';
                        }
                    }
                    group("Group9")
                    {
                        Caption = 'Financial Statement';
                        action("Account Schedule")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Financial Report';
                            RunObject = report "Account Schedule";
                            Tooltip = 'Run the Account Schedule report.';
                        }
                        action("Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance';
                            RunObject = report "Trial Balance";
                            Tooltip = 'Run the Trial Balance report.';
                        }
                        action("Trial Balance/Budget")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance/Budget';
                            RunObject = report "Trial Balance/Budget";
                            Tooltip = 'Run the Trial Balance/Budget report.';
                        }
                        action("Trial Balance/Previous Year")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance/Previous Year';
                            RunObject = report "Trial Balance/Previous Year";
                            Tooltip = 'Run the Trial Balance/Previous Year report.';
                        }
                        action("Closing Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Closing Trial Balance';
                            RunObject = report "Closing Trial Balance";
                            Tooltip = 'Run the Closing Trial Balance report.';
                        }
                        action("Consolidated Trial Balance")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Consolidated Trial Balance';
                            RunObject = report "Consolidated Trial Balance";
                            Tooltip = 'Run the Consolidated Trial Balance report.';
                        }
                        action("Consolidated Trial Balance (4)")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Consolidated Trial Balance (4)';
                            RunObject = report "Consolidated Trial Balance (4)";
                            Tooltip = 'Run the Consolidated Trial Balance (4) report.';
                        }
                        action("Budget")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Budget';
                            RunObject = report "Budget";
                            Tooltip = 'Run the Budget report.';
                        }
                        action("Trial Balance by Period")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance by Period';
                            RunObject = report "Trial Balance by Period";
                            Tooltip = 'Run the Trial Balance by Period report.';
                        }
                        action("Fiscal Year Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Fiscal Year Balance';
                            RunObject = report "Fiscal Year Balance";
                            Tooltip = 'Run the Fiscal Year Balance report.';
                        }
                        action("Balance Comp. - Prev. Year")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Balance Comp. - Prev. Year';
                            RunObject = report "Balance Comp. - Prev. Year";
                            Tooltip = 'Run the Balance Comp. - Prev. Year report.';
                        }
                        action("Balance Sheet")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Balance Sheet';
                            RunObject = codeunit "Run Acc. Sched. Balance Sheet";
                            AccessByPermission = TableData "G/L Account" = R;
                        }
                        action("Income Statement")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Income Statement';
                            RunObject = codeunit "Run Acc. Sched. Income Stmt.";
                            AccessByPermission = TableData "G/L Account" = R;
                        }
                        action("Statement of Cashflows")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Statement';
                            RunObject = codeunit "Run Acc. Sched. CashFlow Stmt.";
                            Tooltip = 'Run the Cash Flow Statement codeunit.';
                            AccessByPermission = TableData "G/L Account" = R;
                        }
                        action("Statement of Retained Earnings")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Retained Earnings Statement';
                            RunObject = codeunit "Run Acc. Sched. Retained Earn.";
                            Tooltip = 'Run the Retained Earnings Statement codeunit.';
                            AccessByPermission = TableData "G/L Account" = R;
                        }
                    }
                    group("Group10")
                    {
                        Caption = 'Miscellaneous';
                        action("Foreign Currency Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Foreign Currency Balance';
                            RunObject = report "Foreign Currency Balance";
                            Tooltip = 'Run the Foreign Currency Balance report.';
                        }
                        action("Reconcile Cust. and Vend. Accs")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Reconcile Cust. and Vend. Accs';
                            RunObject = report "Reconcile Cust. and Vend. Accs";
                            Tooltip = 'Run the Reconcile Cust. and Vend. Accs report.';
                        }
                        action("G/L Deferral Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Deferral Summary';
                            RunObject = report "Deferral Summary - G/L";
                            Tooltip = 'Run the G/L Deferral Summary report.';
                        }
                    }
                    group("Group11")
                    {
                        Caption = 'Setup List';
                        action("Chart of Accounts1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Chart of Accounts';
                            RunObject = report "Chart of Accounts";
                            Tooltip = 'Run the Chart of Accounts report.';
                        }
                        action("Change Log Setup List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Change Log Setup List';
                            RunObject = report "Change Log Setup List";
                            Tooltip = 'Run the Change Log Setup List report.';
                        }
                    }
                }
                group("Group12")
                {
                    Caption = 'Setup';
                    action("General Ledger Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Ledger Setup';
                        RunObject = page "General Ledger Setup";
                        Tooltip = 'Open the General Ledger Setup page.';
                    }
                    action("Deferral Template List")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Deferral Templates';
                        RunObject = page "Deferral Template List";
                        Tooltip = 'Open the Deferral Templates page.';
                    }
                    action("Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Journal Templates';
                        RunObject = page "General Journal Templates";
                        Tooltip = 'Open the General Journal Templates page.';
                    }
                    action("G/L Account Categories")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Account Categories';
                        RunObject = page "G/L Account Categories";
                        Tooltip = 'Open the G/L Account Categories page.';
                        AccessByPermission = TableData "G/L Account Category" = R;
                    }
                    action("VAT Report Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Report Setup';
                        RunObject = page "VAT Report Setup";
                        Tooltip = 'Open the VAT Report Setup page.';
                    }
                }
            }
            group("Group13")
            {
                Caption = 'Cash Management';
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    RunObject = page "Bank Account List";
                    Tooltip = 'Open the Bank Accounts page.';
                }
                action("Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    Caption = 'Receivables-Payables';
                    RunObject = page "Receivables-Payables";
                    Tooltip = 'Open the Receivables-Payables page.';
                }
                action("Payment Registration")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Registration';
                    RunObject = page "Payment Registration";
                    Tooltip = 'Open the Payment Registration page.';
                }
                action("Deposit")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Deposits';
                    RunObject = codeunit "Open Deposits Page";
                }
                action("Posted Bank Deposit")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Bank Deposits';
                    RunObject = codeunit "Open P. Bank Deposits L. Page";
                }
                group("Group14")
                {
                    Caption = 'Cash Flow';
                    action("Cash Flow Forecasts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Forecasts';
                        RunObject = page "Cash Flow Forecast List";
                        Tooltip = 'Open the Cash Flow Forecasts page.';
                    }
                    action("Chart of Cash Flow Accounts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Chart of Cash Flow Accounts';
                        RunObject = page "Chart of Cash Flow Accounts";
                        Tooltip = 'Open the Chart of Cash Flow Accounts page.';
                    }
                    action("Cash Flow Manual Revenues")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Manual Revenues';
                        RunObject = page "Cash Flow Manual Revenues";
                        Tooltip = 'Open the Cash Flow Manual Revenues page.';
                    }
                    action("Cash Flow Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Manual Expenses';
                        RunObject = page "Cash Flow Manual Expenses";
                        Tooltip = 'Open the Cash Flow Manual Expenses page.';
                    }
                    action("Cash Flow Worksheet")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Worksheet';
                        RunObject = page "Cash Flow Worksheet";
                        Tooltip = 'Open the Cash Flow Worksheet page.';
                    }
                }
                group("Group15")
                {
                    Caption = 'Reconciliation';
                    action("Bank Account Reconciliations")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Reconciliations';
                        RunObject = page "Bank Acc. Reconciliation List";
                        Tooltip = 'Open the Bank Account Reconciliations page.';
                    }
                    action("Posted Payment Reconciliations")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Reconciliations';
                        RunObject = page "Posted Payment Reconciliations";
                        Tooltip = 'Open the Posted Payment Reconciliations page.';
                    }
                    action("Payment Reconciliation Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Reconciliation Journals';
                        RunObject = page "Pmt. Reconciliation Journals";
                        Tooltip = 'Open the Payment Reconciliation Journals page.';
                    }
                }
                group("Group16")
                {
                    Caption = 'Journals';
                    action("Cash Receipt Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Receipt Journals';
                        RunObject = page "Cash Receipt Journal";
                        Tooltip = 'Open the Cash Receipt Journals page.';
                    }
                    action("Payment Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Journals';
                        RunObject = page "Payment Journal";
                        Tooltip = 'Open the Payment Journals page.';
                    }
                    action("Payment Reconciliation Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Reconciliation Journals';
                        RunObject = page "Pmt. Reconciliation Journals";
                        Tooltip = 'Open the Payment Reconciliation Journals page.';
                    }
                }
                group("Group17")
                {
                    Caption = 'Ledger Entries';
                    action("Bank Account Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Ledger Entries';
                        RunObject = page "Bank Account Ledger Entries";
                        Tooltip = 'Open the Bank Account Ledger Entries page.';
                    }
                    action("Check Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Ledger Entries';
                        RunObject = page "Check Ledger Entries";
                        Tooltip = 'Open the Check Ledger Entries page.';
                    }
                    action("Cash Flow Ledger Entries1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Ledger Entries';
                        RunObject = page "Cash Flow Forecast Entries";
                        Tooltip = 'Open the Cash Flow Ledger Entries page.';
                    }
                }
                group("Group18")
                {
                    Caption = 'Reports';
                    action("Register")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Register';
                        RunObject = report "Bank Account Register";
                        Tooltip = 'Run the Bank Account Register report.';
                    }
                    action("Check Details")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account - Check Details';
                        RunObject = report "Bank Account - Check Details";
                        Tooltip = 'Run the Bank Account - Check Details report.';
                    }
                    action("Labels")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account - Labels';
                        RunObject = report "Bank Account - Labels";
                        Tooltip = 'Run the Bank Account - Labels report.';
                    }
                    action("List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account - List';
                        RunObject = report "Bank Account - List";
                        Tooltip = 'Run the Bank Account - List report.';
                    }
                    action("Detail Trial Bal.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Acc. - Detail Trial Bal.';
                        RunObject = report "Bank Acc. - Detail Trial Bal.";
                        Tooltip = 'Run the Bank Acc. - Detail Trial Bal. report.';
                    }
                    action("Receivables-Payables1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receivables-Payables';
                        RunObject = report "Receivables-Payables";
                        Tooltip = 'Run the Receivables-Payables report.';
                    }
                    action("Cash Flow Date List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Date List';
                        RunObject = report "Cash Flow Date List";
                        Tooltip = 'Run the Cash Flow Date List report.';
                    }
                    action("Dimensions - Detail1")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Cash Flow Dimensions - Detail';
                        RunObject = report "Cash Flow Dimensions - Detail";
                        Tooltip = 'Run the Cash Flow Dimensions - Detail report.';
                    }
                }
                group("Group19")
                {
                    Caption = 'Setup';
                    action("Payment Application Rules")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Application Rules';
                        RunObject = page "Payment Application Rules";
                        Tooltip = 'Open the Payment Application Rules page.';
                    }
                    action("Cash Flow Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Setup';
                        RunObject = page "Cash Flow Setup";
                        Tooltip = 'Open the Cash Flow Setup page.';
                    }
                    action("Report Selection - Cash Flow")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Report Selections';
                        RunObject = page "Report Selection - Cash Flow";
                        Tooltip = 'Open the Cash Flow Report Selections page.';
                    }
                    action("Report Selection - Bank Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Selections Bank Account';
                        RunObject = page "Report Selection - Bank Acc.";
                        Tooltip = 'Open the Report Selections Bank Account page.';
                    }
                    action("Payment Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Terms';
                        RunObject = page "Payment Terms";
                        Tooltip = 'Open the Payment Terms page.';
                    }
                    action("Payment Methods")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Methods';
                        RunObject = page "Payment Methods";
                        Tooltip = 'Open the Payment Methods page.';
                    }
                    action("Currencies")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currencies';
                        RunObject = page "Currencies";
                        Tooltip = 'Open the Currencies page.';
                    }
                }
            }
            group("Group20")
            {
                Caption = 'Cost Accounting';
                action("Chart of Cost Centers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Chart of Cost Centers';
                    RunObject = page "Chart of Cost Centers";
                    Tooltip = 'Open the Chart of Cost Centers page.';
                }
                action("Chart of Cost Objects")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Chart of Cost Objects';
                    RunObject = page "Chart of Cost Objects";
                    Tooltip = 'Open the Chart of Cost Objects page.';
                }
                action("Chart of Cost Types")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Chart of Cost Types';
                    RunObject = page "Chart of Cost Types";
                    Tooltip = 'Open the Chart of Cost Types page.';
                }
                action("Allocations")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Allocations';
                    RunObject = page "Cost Allocation Sources";
                    Tooltip = 'Open the Cost Allocations page.';
                }
                action("Cost Budgets")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Budgets';
                    RunObject = page "Cost Budget Names";
                    Tooltip = 'Open the Cost Budgets page.';
                }
                action("Cost Journal")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Journals';
                    RunObject = page "Cost Journal";
                    Tooltip = 'Open the Cost Journals page.';
                }
                group("Group21")
                {
                    Caption = 'Registers';
                    action("Registers")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Registers';
                        RunObject = page "Cost Registers";
                        Tooltip = 'Open the Cost Registers page.';
                    }
                    action("Cost Budget Registers")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Budget Registers';
                        RunObject = page "Cost Budget Registers";
                        Tooltip = 'Open the Cost Budget Registers page.';
                    }
                }
                group("Group22")
                {
                    Caption = 'Reports';
                    group("Group23")
                    {
                        Caption = 'Setup Information';
                        action("Allocations1")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Allocations';
                            RunObject = report "Cost Allocations";
                            Tooltip = 'Run the Cost Allocations report.';
                        }
                    }
                    group("Group24")
                    {
                        Caption = 'Entries';
                        action("Cost Journal1")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Journal';
                            RunObject = report "Cost Acctg. Journal";
                            Tooltip = 'Run the Cost Acctg. Journal report.';
                        }
                        action("Account Details")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Types Details';
                            RunObject = report "Cost Types Details";
                            Tooltip = 'Run the Cost Types Details report.';
                        }
                    }
                    group("Group25")
                    {
                        Caption = 'Cost & Revenue';
                        action("P/L Statement")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Statement';
                            RunObject = report "Cost Acctg. Statement";
                            Tooltip = 'Run the Cost Acctg. Statement report.';
                        }
                        action("P/L Statement per Period")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Stmt. per Period';
                            RunObject = report "Cost Acctg. Stmt. per Period";
                            Tooltip = 'Run the Cost Acctg. Stmt. per Period report.';
                        }
                        action("Analysis")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Analysis';
                            RunObject = report "Cost Acctg. Analysis";
                            Tooltip = 'Run the Cost Acctg. Analysis report.';
                        }
                    }
                    group("Group26")
                    {
                        Caption = 'Cost Budget';
                        action("P/L Statement with Budget")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Statement/Budget';
                            RunObject = report "Cost Acctg. Statement/Budget";
                            Tooltip = 'Run the Cost Acctg. Statement/Budget report.';
                        }
                        action("Cost Center")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Balance/Budget';
                            RunObject = report "Cost Acctg. Balance/Budget";
                            Tooltip = 'Run the Cost Acctg. Balance/Budget report.';
                        }
                    }
                }
                group("Group27")
                {
                    Caption = 'Setup';
                    action("Cost Accounting Setup")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Accounting Setup';
                        RunObject = page "Cost Accounting Setup";
                        Tooltip = 'Open the Cost Accounting Setup page.';
                    }
                    action("Cost Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cost Journal Templates';
                        RunObject = page "Cost Journal Templates";
                        Tooltip = 'Open the Cost Journal Templates page.';
                    }
                }
            }
            group("Group28")
            {
                Caption = 'Receivables';
                action("Customers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                    Tooltip = 'Open the Customers page.';
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    RunObject = page "Sales Invoice List";
                    Tooltip = 'Open the Sales Invoices page.';
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memos';
                    RunObject = page "Sales Credit Memos";
                    Tooltip = 'Open the Sales Credit Memos page.';
                }
                action("Direct Debit Collections")
                {
                    ApplicationArea = Suite;
                    Caption = 'Direct Debit Collections';
                    RunObject = page "Direct Debit Collections";
                    Tooltip = 'Open the Direct Debit Collections page.';
                }
                action("Create Recurring Sales Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Recurring Sales Invoices';
                    RunObject = report "Create Recurring Sales Inv.";
                    Tooltip = 'Run the Create Recurring Sales Invoices report.';
                }
                action("Register Customer Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Register Customer Payments';
                    RunObject = page "Payment Registration";
                    Tooltip = 'Open the Register Customer Payments page.';
                }
                group("Group29")
                {
                    Caption = 'Combine';
                    action("Combined Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine Shipments...';
                        RunObject = report "Combine Shipments";
                        Tooltip = 'Run the Combine Shipments report.';
                    }
                    action("Combined Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder, PurchReturnOrder;
                        Caption = 'Combine Return Receipts...';
                        RunObject = report "Combine Return Receipts";
                        Tooltip = 'Run the Combine Return Receipts report.';
                    }
                }
                group("Group30")
                {
                    Caption = 'Reminder/Fin. Charge Memos';
                    action("Reminders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Reminders';
                        RunObject = page "Reminder List";
                        Tooltip = 'Open the Reminders page.';
                    }
                    action("Issued Reminders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Issued Reminders';
                        RunObject = page "Issued Reminder List";
                        Tooltip = 'Open the Issued Reminders page.';
                    }
                    action("Finance Charge Memos")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Finance Charge Memos';
                        RunObject = page "Finance Charge Memo List";
                        Tooltip = 'Open the Finance Charge Memos page.';
                    }
                    action("Issued Finance Charge Memos")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Issued Finance Charge Memos';
                        RunObject = page "Issued Fin. Charge Memo List";
                        Tooltip = 'Open the Issued Finance Charge Memos page.';
                    }
                }
                group("Group31")
                {
                    Caption = 'Journals';
                    action("Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Journals';
                        RunObject = page "Sales Journal";
                        Tooltip = 'Open the Sales Journals page.';
                    }
                    action("Cash Receipt Journal1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Receipt Journals';
                        RunObject = page "Cash Receipt Journal";
                        Tooltip = 'Open the Cash Receipt Journals page.';
                    }
                }
                group("Group32")
                {
                    Caption = 'Posted Documents';
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = page "Posted Sales Invoices";
                        Tooltip = 'Open the Posted Sales Invoices page.';
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = page "Posted Sales Shipments";
                        Tooltip = 'Open the Posted Sales Shipments page.';
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = page "Posted Sales Credit Memos";
                        Tooltip = 'Open the Posted Sales Credit Memos page.';
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = page "Posted Return Receipts";
                        Tooltip = 'Open the Posted Return Receipts page.';
                    }
                }
                group("Group33")
                {
                    Caption = 'Registers/Entries';
                    action("G/L Registers1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = page "G/L Registers";
                        Tooltip = 'Open the G/L Registers page.';
                    }
                    action("Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        RunObject = page "Customer Ledger Entries";
                        Tooltip = 'Open the Customer Ledger Entries page.';
                    }
                    action("Reminder/Fin. Charge Entries")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Reminder/Fin. Charge Entries';
                        RunObject = page "Reminder/Fin. Charge Entries";
                        Tooltip = 'Open the Reminder/Fin. Charge Entries page.';
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Customer Ledger Entries';
                        RunObject = page "Detailed Cust. Ledg. Entries";
                        Tooltip = 'Open the Detailed Customer Ledger Entries page.';
                    }
                }
                group("Group34")
                {
                    Caption = 'Reports';
                    action("Customer Detailed Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Detailed Aging';
                        RunObject = report "Customer Detailed Aging";
                        Tooltip = 'Run the Customer Detailed Aging report.';
                    }
                    action("Customer Statement")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Statement';
                        RunObject = codeunit "Customer Layout - Statement";
                        Tooltip = 'Run the Customer Statement codeunit.';
                    }
                    action("Customer Register")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Register';
                        RunObject = report "Customer Register";
                        Tooltip = 'Run the Customer Register report.';
                    }
                    action("Customer - Balance to Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Balance to Date';
                        RunObject = report "Customer - Balance to Date";
                        Tooltip = 'Run the Customer - Balance to Date report.';
                    }
                    action("Customer - Detail Trial Bal.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Detail Trial Bal.';
                        RunObject = report "Customer - Detail Trial Bal.";
                        Tooltip = 'Run the Customer - Detail Trial Bal. report.';
                    }
                    action("Customer - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - List';
                        RunObject = report "Customer - List";
                        Tooltip = 'Run the Customer - List report.';
                    }
                    action("Customer - Summary Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Summary Aging';
                        RunObject = report "Customer - Summary Aging";
                        Tooltip = 'Run the Customer - Summary Aging report.';
                    }
                    action("Customer - Summary Aging Simp.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Customer - Summary Aging Simp.';
                        RunObject = report "Customer - Summary Aging Simp.";
                        Tooltip = 'Run the Customer - Summary Aging Simp. report.';
                    }
                    action("Customer - Order Summary")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Summary';
                        RunObject = report "Customer - Order Summary";
                        Tooltip = 'Run the Customer - Order Summary report.';
                    }
                    action("Customer - Order Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Detail';
                        RunObject = report "Customer - Order Detail";
                        Tooltip = 'Run the Customer - Order Detail report.';
                    }
                    action("Customer - Labels")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Customer Labels';
                        RunObject = report "Customer - Labels";
                        Tooltip = 'Run the Customer Labels report.';
                    }
                    action("Customer - Top 10 List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Top 10 List';
                        RunObject = report "Customer - Top 10 List";
                        Tooltip = 'Run the Customer Top 10 List report.';
                    }
                    action("Sales Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Statistics';
                        RunObject = report "Sales Statistics";
                        Tooltip = 'Run the Sales Statistics report.';
                    }
                    action("Customer/Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer/Item Sales';
                        RunObject = report "Customer/Item Sales";
                        Tooltip = 'Run the Customer/Item Sales report.';
                    }
                    action("Salesperson - Sales Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Salesperson Sales Statistics';
                        RunObject = report "Salesperson - Sales Statistics";
                        Tooltip = 'Run the Salesperson Sales Statistics report.';
                    }
                    action("Salesperson - Commission")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Salesperson Commission';
                        RunObject = report "Salesperson - Commission";
                        Tooltip = 'Run the Salesperson Commission report.';
                    }
                    action("Customer - Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Sales List';
                        RunObject = report "Customer - Sales List";
                        Tooltip = 'Run the Customer - Sales List report.';
                    }
                    action("Aged Accounts Receivable")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Receivable';
                        RunObject = report "Aged Accounts Receivable";
                        Tooltip = 'Run the Aged Accounts Receivable report.';
                    }
                    action("Customer - Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Trial Balance';
                        RunObject = report "Customer - Trial Balance";
                        Tooltip = 'Run the Customer Trial Balance report.';
                    }
                    action("EC Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EC Sales List';
                        RunObject = report "EC Sales List";
                        Tooltip = 'Run the EC Sales List report.';
                    }
                }
                group("Group35")
                {
                    Caption = 'Setup';
                    action("Sales & Receivables Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales & Receivables Setup';
                        RunObject = page "Sales & Receivables Setup";
                        Tooltip = 'Open the Sales & Receivables Setup page.';
                    }
                    action("Payment Registration Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Registration Setup';
                        RunObject = page "Payment Registration Setup";
                        Tooltip = 'Open the Payment Registration Setup page.';
                    }
                    action("Report Selection Reminder and")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Selections Reminder/Fin. Charge';
                        RunObject = page "Report Selection - Reminder";
                        Tooltip = 'Open the Report Selections Reminder/Fin. Charge page.';
                    }
                    action("Reminder Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reminder Terms';
                        RunObject = page "Reminder Terms";
                        Tooltip = 'Open the Reminder Terms page.';
                    }
                    action("Finance Charge Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Finance Charge Terms';
                        RunObject = page "Finance Charge Terms";
                        Tooltip = 'Open the Finance Charge Terms page.';
                    }
                }
            }
            group("Group36")
            {
                Caption = 'Payables';
                action("Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page "Vendor List";
                    Tooltip = 'Open the Vendors page.';
                }
                action("Invoices1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Invoices';
                    RunObject = page "Purchase Invoices";
                    Tooltip = 'Open the Purchase Invoices page.';
                }
                action("Credit Memos1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Credit Memos';
                    RunObject = page "Purchase Credit Memos";
                    Tooltip = 'Open the Purchase Credit Memos page.';
                }
                action("Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Documents';
                    RunObject = page "Incoming Documents";
                    Tooltip = 'Open the Incoming Documents page.';
                }
                group("Group37")
                {
                    Caption = 'Journals';
                    action("Purchase Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Journals';
                        RunObject = page "Purchase Journal";
                        Tooltip = 'Open the Purchase Journals page.';
                    }
                    action("Payment Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Journals';
                        RunObject = page "Payment Journal";
                        Tooltip = 'Open the Payment Journals page.';
                    }
                }
                group("Group38")
                {
                    Caption = 'Posted Documents';
                    action("Posted Credit Memos1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = page "Posted Purchase Credit Memos";
                        Tooltip = 'Open the Posted Purchase Credit Memos page.';
                    }
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = page "Posted Purchase Invoices";
                        Tooltip = 'Open the Posted Purchase Invoices page.';
                    }
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = page "Posted Purchase Receipts";
                        Tooltip = 'Open the Posted Purchase Receipts page.';
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = page "Posted Return Shipments";
                        Tooltip = 'Open the Posted Purchase Return Shipments page.';
                    }
                }
                group("Group39")
                {
                    Caption = 'Registers/Entries';
                    action("G/L Registers2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = page "G/L Registers";
                        Tooltip = 'Open the G/L Registers page.';
                    }
                    action("Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        RunObject = page "Vendor Ledger Entries";
                        Tooltip = 'Open the Vendor Ledger Entries page.';
                    }
                    action("Detailed Cust. Ledg. Entries1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Vendor Ledger Entries';
                        RunObject = page "Detailed Vendor Ledg. Entries";
                        Tooltip = 'Open the Detailed Vendor Ledger Entries page.';
                    }
                    action("Credit Transfer Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Credit Transfer Registers';
                        RunObject = page "Credit Transfer Registers";
                        Tooltip = 'Open the Credit Transfer Registers page.';
                    }
                    action("Employee Ledger Entries")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Ledger Entries';
                        RunObject = page "Employee Ledger Entries";
                        Tooltip = 'Open the Employee Ledger Entries page.';
                    }
                    action("Detailed Employee Ledger Entries")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Detailed Employee Ledger Entries';
                        RunObject = page "Detailed Empl. Ledger Entries";
                        Tooltip = 'Open the Detailed Employee Ledger Entries page.';
                    }
                }
                group("Group40")
                {
                    Caption = 'Reports';
                    action("Aged Accounts Payable")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Payable';
                        RunObject = report "Aged Accounts Payable";
                        Tooltip = 'Run the Aged Accounts Payable report.';
                    }
                    action("Payments on Hold")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payments on Hold';
                        RunObject = report "Payments on Hold";
                        Tooltip = 'Run the Payments on Hold report.';
                    }
                    action("Purchase Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Statistics';
                        RunObject = report "Purchase Statistics";
                        Tooltip = 'Run the Purchase Statistics report.';
                    }
                    action("Vendor Item Catalog")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Item Catalog';
                        RunObject = report "Vendor Item Catalog";
                        Tooltip = 'Run the Vendor Item Catalog report.';
                    }
                    action("Vendor Register")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Register';
                        RunObject = report "Vendor Register";
                        Tooltip = 'Run the Vendor Register report.';
                    }
                    action("Vendor - Balance to Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Balance to Date';
                        RunObject = report "Vendor - Balance to Date";
                        Tooltip = 'Run the Vendor - Balance to Date report.';
                    }
                    action("Vendor - Detail Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Detail Trial Balance';
                        RunObject = report "Vendor - Detail Trial Balance";
                        Tooltip = 'Run the Vendor - Detail Trial Balance report.';
                    }
                    action("Vendor - Labels")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Vendor - Labels';
                        RunObject = report "Vendor - Labels";
                        Tooltip = 'Run the Vendor - Labels report.';
                    }
                    action("Vendor - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - List';
                        RunObject = report "Vendor - List";
                        Tooltip = 'Run the Vendor - List report.';
                    }
                    action("Vendor - Order Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Order Detail';
                        RunObject = report "Vendor - Order Detail";
                        Tooltip = 'Run the Vendor - Order Detail report.';
                    }
                    action("Vendor - Order Summary")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Order Summary';
                        RunObject = report "Vendor - Order Summary";
                        Tooltip = 'Run the Vendor - Order Summary report.';
                    }
                    action("Vendor - Purchase List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Purchase List';
                        RunObject = report "Vendor - Purchase List";
                        Tooltip = 'Run the Vendor - Purchase List report.';
                    }
                    action("Vendor - Summary Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Summary Aging';
                        RunObject = report "Vendor - Summary Aging";
                        Tooltip = 'Run the Vendor - Summary Aging report.';
                    }
                    action("Vendor - Top 10 List")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Vendor - Top 10 List';
                        RunObject = report "Vendor - Top 10 List";
                        Tooltip = 'Run the Vendor - Top 10 List report.';
                    }
                    action("Vendor - Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Trial Balance';
                        RunObject = report "Vendor - Trial Balance";
                        Tooltip = 'Run the Vendor - Trial Balance report.';
                    }
                    action("Vendor/Item Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor/Item Purchases';
                        RunObject = report "Vendor/Item Purchases";
                        Tooltip = 'Run the Vendor/Item Purchases report.';
                    }
                }
                group("Group41")
                {
                    Caption = 'Setup';
                    action("Purchases & Payables Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases & Payables Setup';
                        RunObject = page "Purchases & Payables Setup";
                        Tooltip = 'Open the Purchases & Payables Setup page.';
                    }
                }
            }
            group("Group42")
            {
                Caption = 'Fixed Assets';
                action("Fixed Assets")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets';
                    RunObject = page "Fixed Asset List";
                    Tooltip = 'Open the Fixed Assets page.';
                }
                action("Insurance")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance';
                    RunObject = page "Insurance List";
                    Tooltip = 'Open the Insurance page.';
                }
                action("Calculate Depreciation...")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Calculate Depreciation...';
                    RunObject = report "Calculate Depreciation";
                    Tooltip = 'Run the Calculate Depreciation report.';
                }
                action("Fixed Assets...")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Index Fixed Assets...';
                    RunObject = report "Index Fixed Assets";
                    Tooltip = 'Run the Index Fixed Assets report.';
                }
                action("Insurance...")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Index Insurance...';
                    RunObject = report "Index Insurance";
                    Tooltip = 'Run the Index Insurance report.';
                }
                group("Group43")
                {
                    Caption = 'Journals';
                    action("G/L Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA G/L Journals';
                        RunObject = page "Fixed Asset G/L Journal";
                        Tooltip = 'Open the FA G/L Journals page.';
                    }
                    action("FA Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Journals';
                        RunObject = page "Fixed Asset Journal";
                        Tooltip = 'Open the FA Journals page.';
                    }
                    action("FA Reclass. Journal")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Reclassification Journals';
                        RunObject = page "FA Reclass. Journal";
                        Tooltip = 'Open the FA Reclassification Journals page.';
                    }
                    action("Insurance Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Journals';
                        RunObject = page "Insurance Journal";
                        Tooltip = 'Open the Insurance Journals page.';
                    }
                    action("Recurring Journals1")
                    {
                        ApplicationArea = Suite, FixedAssets;
                        Caption = 'Recurring General Journals';
                        RunObject = page "Recurring General Journal";
                        Tooltip = 'Open the Recurring General Journals page.';
                    }
                    action("Recurring Fixed Asset Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Recurring Fixed Asset Journals';
                        RunObject = page "Recurring Fixed Asset Journal";
                        Tooltip = 'Open the Recurring Fixed Asset Journals page.';
                    }
                }
                group("Group44")
                {
                    Caption = 'Reports';
                    group("Group45")
                    {
                        Caption = 'Fixed Assets';
                        action("FixedAssetsAnalysis")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Analyze Fixed Assets';
                            Image = NonStockItem;
                            RunObject = Query "Fixed Assets Analysis";
                            ToolTip = 'Analyze (group, summarize, pivot) your Fixed Asset Ledger Entries with related Fixed Asset master data such as Fixed Asset, Asset Class/Subclass, and Posting Date.';
                        }
                        action("Posting Group - Net Change")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Posting Group - Net Change';
                            RunObject = report "FA Posting Group - Net Change";
                            Tooltip = 'Run the FA Posting Group - Net Change report.';
                        }
                        action("Register1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Register';
                            RunObject = report "Fixed Asset Register";
                            Tooltip = 'Run the FA Register report.';
                        }
                        action("Acquisition List")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Acquisition List';
                            RunObject = report "Fixed Asset - Acquisition List";
                            Tooltip = 'Run the FA Acquisition List report.';
                        }
                        action("Analysis1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Analysis';
                            RunObject = report "Fixed Asset - Analysis";
                            Tooltip = 'Run the FA Analysis report.';
                        }
                        action("Book Value 01")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Book Value 01';
                            RunObject = report "Fixed Asset - Book Value 01";
                            Tooltip = 'Run the FA Book Value 01 report.';
                        }
                        action("Book Value 02")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Book Value 02';
                            RunObject = report "Fixed Asset - Book Value 02";
                            Tooltip = 'Run the FA Book Value 02 report.';
                        }
                        action("Details")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Details';
                            RunObject = report "Fixed Asset - Details";
                            Tooltip = 'Run the FA Details report.';
                        }
                        action("G/L Analysis")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA G/L Analysis';
                            RunObject = report "Fixed Asset - G/L Analysis";
                            Tooltip = 'Run the FA G/L Analysis report.';
                        }
                        action("List1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA List';
                            RunObject = report "Fixed Asset - List";
                            Tooltip = 'Run the FA List report.';
                        }
                        action("Projected Value")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Projected Value';
                            RunObject = report "Fixed Asset - Projected Value";
                            Tooltip = 'Run the FA Projected Value report.';
                        }
                    }
                    group("Group46")
                    {
                        Caption = 'Insurance';
                        action("Uninsured FAs")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Uninsured FAs';
                            RunObject = report "Insurance - Uninsured FAs";
                            Tooltip = 'Run the Uninsured FAs report.';
                        }
                        action("Register2")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance Register';
                            RunObject = report "Insurance Register";
                            Tooltip = 'Run the Insurance Register report.';
                        }
                        action("Analysis2")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance Analysis';
                            RunObject = report "Insurance - Analysis";
                            Tooltip = 'Run the Insurance Analysis report.';
                        }
                        action("Coverage Details")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance Coverage Details';
                            RunObject = report "Insurance - Coverage Details";
                            Tooltip = 'Run the Insurance Coverage Details report.';
                        }
                        action("List2")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance List';
                            RunObject = report "Insurance - List";
                            Tooltip = 'Run the Insurance List report.';
                        }
                        action("Tot. Value Insured")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Total Value Insured';
                            RunObject = report "Insurance - Tot. Value Insured";
                            Tooltip = 'Run the FA Total Value Insured report.';
                        }
                    }
                    group("Group47")
                    {
                        Caption = 'Maintenance';
                        action("Register3")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Register';
                            RunObject = report "Maintenance Register";
                            Tooltip = 'Run the Maintenance Register report.';
                        }
                        action("Analysis3")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Analysis';
                            RunObject = report "Maintenance - Analysis";
                            Tooltip = 'Run the Maintenance Analysis report.';
                        }
                        action("Details1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Details';
                            RunObject = report "Maintenance - Details";
                            Tooltip = 'Run the Maintenance Details report.';
                        }
                        action("Next Service")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Next Service';
                            RunObject = report "Maintenance - Next Service";
                            Tooltip = 'Run the Maintenance Next Service report.';
                        }
                    }
                }
                group("Group48")
                {
                    Caption = 'Registers/Entries';
                    action("FA Registers")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Registers';
                        RunObject = page "FA Registers";
                        Tooltip = 'Open the FA Registers page.';
                    }
                    action("Insurance Registers")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Registers';
                        RunObject = page "Insurance Registers";
                        Tooltip = 'Open the Insurance Registers page.';
                    }
                    action("FA Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Ledger Entries';
                        RunObject = page "FA Ledger Entries";
                        Tooltip = 'Open the FA Ledger Entries page.';
                    }
                    action("Maintenance Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance Ledger Entries';
                        RunObject = page "Maintenance Ledger Entries";
                        Tooltip = 'Open the Maintenance Ledger Entries page.';
                    }
                    action("Ins. Coverage Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Coverage Ledger Entries';
                        RunObject = page "Ins. Coverage Ledger Entries";
                        Tooltip = 'Open the Insurance Coverage Ledger Entries page.';
                    }
                }
                group("Group49")
                {
                    Caption = 'Setup';
                    action("FA Setup")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Setup';
                        RunObject = page "Fixed Asset Setup";
                        Tooltip = 'Open the FA Setup page.';
                    }
                    action("FA Classes")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Classes';
                        RunObject = page "FA Classes";
                        Tooltip = 'Open the FA Classes page.';
                    }
                    action("FA Subclasses")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Subclasses';
                        RunObject = page "FA Subclasses";
                        Tooltip = 'Open the FA Subclasses page.';
                    }
                    action("FA Locations")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Locations';
                        RunObject = page "FA Locations";
                        Tooltip = 'Open the FA Locations page.';
                    }
                    action("Insurance Types")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Types';
                        RunObject = page "Insurance Types";
                        Tooltip = 'Open the Insurance Types page.';
                    }
                    action("Maintenance")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance';
                        RunObject = page "Maintenance";
                        Tooltip = 'Open the Maintenance page.';
                    }
                    action("Depreciation Books")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Books';
                        RunObject = page "Depreciation Book List";
                        Tooltip = 'Open the Depreciation Books page.';
                    }
                    action("Depreciation Tables")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Tables';
                        RunObject = page "Depreciation Table List";
                        Tooltip = 'Open the Depreciation Tables page.';
                    }
                    action("FA Journal Templates")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Journal Templates';
                        RunObject = page "FA Journal Templates";
                        Tooltip = 'Open the FA Journal Templates page.';
                    }
                    action("FA Reclass. Journal Templates")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Reclassification Journal Template';
                        RunObject = page "FA Reclass. Journal Templates";
                        Tooltip = 'Open the FA Reclassification Journal Template page.';
                    }
                    action("Insurance Journal Templates")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Journal Templates';
                        RunObject = page "Insurance Journal Templates";
                        Tooltip = 'Open the Insurance Journal Templates page.';
                    }
                }
            }
            group("Group50")
            {
                Caption = 'Inventory';
                action("Inventory Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Periods';
                    RunObject = page "Inventory Periods";
                    Tooltip = 'Open the Inventory Periods page.';
                }
                action("Phys. Invt. Counting Periods")
                {
                    ApplicationArea = Basic, Suite, Warehouse;
                    Caption = 'Physical Inventory Counting Periods';
                    RunObject = page "Phys. Invt. Counting Periods";
                    Tooltip = 'Open the Physical Invtory Counting Periods page.';
                }
                action("Application Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Application Worksheet';
                    RunObject = page "Application Worksheet";
                    Tooltip = 'Open the Application Worksheet page.';
                }
                group("Group51")
                {
                    Caption = 'Costing';
                    action("Adjust Item Costs/Prices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Item Costs/Prices';
                        RunObject = report "Adjust Item Costs/Prices";
                        Tooltip = 'Run the Adjust Item Costs/Prices report.';
                    }
                    action("Adjust Cost - Item Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Cost - Item Entries...';
                        RunObject = report "Adjust Cost - Item Entries";
                        Tooltip = 'Run the Adjust Cost - Item Entries report.';
                    }
                    action("Post Inventory Cost to G/L")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Inventory Cost to G/L';
                        RunObject = report "Post Inventory Cost to G/L";
                        Tooltip = 'Run the Post Inventory Cost to G/L report.';
                    }
                }
                group("Group52")
                {
                    Caption = 'Journals';
                    action("Item Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journals';
                        RunObject = page "Item Journal";
                        Tooltip = 'Open the Item Journals page.';
                    }
                    action("Item Reclass. Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = page "Item Reclass. Journal";
                        Tooltip = 'Open the Item Reclassification Journals page.';
                    }
                    action("Phys. Inventory Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Physical Inventory Journals';
                        RunObject = page "Phys. Inventory Journal";
                        Tooltip = 'Open the Physical Inventory Journals page.';
                    }
                    action("Revaluation Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revaluation Journals';
                        RunObject = page "Revaluation Journal";
                        Tooltip = 'Open the Revaluation Journals page.';
                    }
                }
                group("Group53")
                {
                    Caption = 'Reports';
                    action("Inventory by Location")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Analyze Inventory by Location';
                        RunObject = Query "Inventory by Location";
                        ToolTip = 'Analyze (group, summarize, pivot) your Item Ledger Entries with related Location master data.';
                    }
                    action("Inventory Valuation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation';
                        RunObject = report "Inventory Valuation";
                        Tooltip = 'Run the Inventory Valuation report.';
                    }
                    action("Inventory - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - List';
                        RunObject = report "Inventory - List";
                        Tooltip = 'Run the Inventory - List report.';
                    }
                    action("Invt. Valuation - Cost Spec.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invt. Valuation - Cost Spec.';
                        RunObject = report "Invt. Valuation - Cost Spec.";
                        Tooltip = 'Run the Invt. Valuation - Cost Spec. report.';
                    }
                    action("Item Age Composition - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Value';
                        RunObject = report "Item Age Composition - Value";
                        Tooltip = 'Run the Item Age Composition - Value report.';
                    }
                    action("Item Register - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Value';
                        RunObject = report "Item Register - Value";
                        Tooltip = 'Run the Item Register - Value report.';
                    }
                    action("Physical Inventory List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Physical Inventory List';
                        RunObject = report "Phys. Inventory List";
                        Tooltip = 'Run the Physical Inventory List report.';
                    }
                    action("Status")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Status';
                        RunObject = report "Status";
                        Tooltip = 'Run the Status report.';
                    }
                    action("Item Register - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Quantity';
                        RunObject = report "Item Register - Quantity";
                        Tooltip = 'Run the Item Register - Quantity report.';
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = report "Item Dimensions - Detail";
                        Tooltip = 'Run the Item Dimensions - Detail report.';
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = report "Item Dimensions - Total";
                        Tooltip = 'Run the Item Dimensions - Total report.';
                    }
                    action("Inventory - G/L Reconciliation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - G/L Reconciliation';
                        RunObject = page "Inventory - G/L Reconciliation";
                        Tooltip = 'Open the Inventory - G/L Reconciliation page.';
                    }
                }
                group("Group54")
                {
                    Caption = 'Setup';
                    action("Inventory Posting Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Posting Setup';
                        RunObject = page "Inventory Posting Setup";
                        Tooltip = 'Open the Inventory Posting Setup page.';
                    }
                    action("Inventory Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Setup';
                        RunObject = page "Inventory Setup";
                        Tooltip = 'Open the Inventory Setup page.';
                    }
                    action("Item Charges")
                    {
                        ApplicationArea = ItemCharges;
                        Caption = 'Item Charges';
                        RunObject = page "Item Charges";
                        Tooltip = 'Open the Item Charges page.';
                    }
                    action("Item Categories")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Categories';
                        RunObject = page "Item Categories";
                        Tooltip = 'Open the Item Categories page.';
                    }
                    action("Rounding Methods")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Methods';
                        RunObject = page "Rounding Methods";
                        Tooltip = 'Open the Rounding Methods page.';
                        AccessByPermission = TableData "Resource" = R;
                    }
                    action("Analysis Types")
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Analysis Types';
                        RunObject = page "Analysis Types";
                        Tooltip = 'Open the Analysis Types page.';
                    }
                    action("Inventory Analysis Report")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Inventory Analysis Reports';
                        RunObject = page "Analysis Report Inventory";
                        Tooltip = 'Open the Inventory Analysis Reports page.';
                    }
                    action("Analysis View Card")
                    {
                        ApplicationArea = Dimensions, InventoryAnalysis;
                        Caption = 'Inventory Analysis by Dimensions';
                        RunObject = page "Analysis View List Inventory";
                        Tooltip = 'Open the Inventory Analysis by Dimensions page.';
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Invt. Analysis Column Templates';
                        RunObject = report "Run Invt. Analysis Col. Temp.";
                        Tooltip = 'Run the Invt. Analysis Column Templates report.';
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Invt. Analysis Line Templates';
                        RunObject = report "Run Invt. Analysis Line Temp.";
                        Tooltip = 'Run the Invt. Analysis Line Templates report.';
                    }
                }
            }
            group("Group55")
            {
                Caption = 'Setup';
                action("General Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Posting Setup';
                    RunObject = page "General Posting Setup";
                    Tooltip = 'Open the General Posting Setup page.';
                }
                action("Incoming Documents Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Documents Setup';
                    RunObject = page "Incoming Documents Setup";
                    Tooltip = 'Open the Incoming Documents Setup page.';
                }
                action("Accounting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Periods';
                    RunObject = page "Accounting Periods";
                    Tooltip = 'Open the Accounting Periods page.';
                }
                action("Standard Text Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Standard Text Codes';
                    RunObject = page "Standard Text Codes";
                    Tooltip = 'Open the Standard Text Codes page.';
                }
                action("No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. Series';
                    RunObject = page "No. Series";
                    Tooltip = 'Open the No. Series page.';
                }
                group("Group56")
                {
                    Caption = 'VAT';
                    action("Posting Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Posting Setup';
                        RunObject = page "VAT Posting Setup";
                        Tooltip = 'Open the VAT Posting Setup page.';
                    }
                    action("VAT Clauses")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Clauses';
                        RunObject = page "VAT Clauses";
                        Tooltip = 'Open the VAT Clauses page.';
                    }
                    action("VAT Change Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Rate Change Setup';
                        RunObject = page "VAT Rate Change Setup";
                        Tooltip = 'Open the VAT Rate Change Setup page.';
                    }
                    action("VAT Statement Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Templates';
                        RunObject = page "VAT Statement Templates";
                        Tooltip = 'Open the VAT Statement Templates page.';
                    }
                    action("VAT Reports Configuration")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Reports Configuration';
                        RunObject = page "VAT Reports Configuration";
                        Tooltip = 'Open the VAT Reports Configuration page.';
                    }
                }
                group("Group57")
                {
                    Caption = 'Intrastat';
                    action("Tariff Numbers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tariff Numbers';
                        RunObject = page "Tariff Numbers";
                        Tooltip = 'Open the Tariff Numbers page.';
                    }
                    action("Transaction Types")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Transaction Types';
                        RunObject = page "Transaction Types";
                        Tooltip = 'Open the Transaction Types page.';
                    }
                    action("Transaction Specifications")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Transaction Specifications';
                        RunObject = page "Transaction Specifications";
                        Tooltip = 'Open the Transaction Specifications page.';
                    }
                    action("Transport Methods")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Transport Methods';
                        RunObject = page "Transport Methods";
                        Tooltip = 'Open the Transport Methods page.';
                    }
                    action("Entry/Exit Points")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Entry/Exit Points';
                        RunObject = page "Entry/Exit Points";
                        Tooltip = 'Open the Entry/Exit Points page.';
                    }
                    action("Areas")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Areas';
                        RunObject = page "Areas";
                        Tooltip = 'Open the Areas page.';
                    }
                }
                group("Group58")
                {
                    Caption = 'Intercompany';
                    action("Intercompany Setup")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Setup';
                        RunObject = page "Intercompany Setup";
                        Tooltip = 'Open the Intercompany Setup page.';
                    }
                    action("Partner Code")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Partners';
                        RunObject = page "IC Partner List";
                        Tooltip = 'Open the Intercompany Partners page.';
                    }
                    action("Chart of Accounts2")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Chart of Accounts';
                        RunObject = page "IC Chart of Accounts";
                        Tooltip = 'Open the Intercompany Chart of Accounts page.';
                    }
                    action("Dimensions")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Intercompany Dimensions';
                        RunObject = page "IC Dimensions";
                        Tooltip = 'Open the Intercompany Dimensions page.';
                    }
                }
                group("Group59")
                {
                    Caption = 'Dimensions';
                    action("Dimensions1")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions';
                        RunObject = page "Dimensions";
                        Tooltip = 'Open the Dimensions page.';
                    }
                    action("Analyses by Dimensions1")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis by Dimensions';
                        RunObject = page "Analysis View List";
                        Tooltip = 'Open the Analysis by Dimensions page.';
                    }
                    action("Dimension Combinations")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimension Combinations';
                        RunObject = page "Dimension Combinations";
                        Tooltip = 'Open the Dimension Combinations page.';
                    }
                    action("Default Dimension Priorities")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Default Dimension Priorities';
                        RunObject = page "Default Dimension Priorities";
                        Tooltip = 'Open the Default Dimension Priorities page.';
                    }
                }
                group("Group60")
                {
                    Caption = 'Trail Codes';
                    action("Source Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Codes';
                        RunObject = page "Source Codes";
                        Tooltip = 'Open the Source Codes page.';
                    }
                    action("Reason Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reason Codes';
                        RunObject = page "Reason Codes";
                        Tooltip = 'Open the Reason Codes page.';
                    }
                    action("Source Code Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Code Setup';
                        RunObject = page "Source Code Setup";
                        Tooltip = 'Open the Source Code Setup page.';
                    }
                }
                group("Group61")
                {
                    Caption = 'Posting Groups';
                    action("General Business")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Business Posting Groups';
                        RunObject = page "Gen. Business Posting Groups";
                        Tooltip = 'Open the Gen. Business Posting Groups page.';
                    }
                    action("Gen. Product Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Product Posting Groups';
                        RunObject = page "Gen. Product Posting Groups";
                        Tooltip = 'Open the General Product Posting Groups page.';
                    }
                    action("Customer Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Posting Groups';
                        RunObject = page "Customer Posting Groups";
                        Tooltip = 'Open the Customer Posting Groups page.';
                    }
                    action("Vendor Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Posting Groups';
                        RunObject = page "Vendor Posting Groups";
                        Tooltip = 'Open the Vendor Posting Groups page.';
                    }
                    action("Bank Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Posting Groups';
                        RunObject = page "Bank Account Posting Groups";
                        Tooltip = 'Open the Bank Account Posting Groups page.';
                    }
                    action("Inventory Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Posting Groups';
                        RunObject = page "Inventory Posting Groups";
                        Tooltip = 'Open the Inventory Posting Groups page.';
                    }
                    action("FA Posting Groups")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Posting Groups';
                        RunObject = page "FA Posting Groups";
                        Tooltip = 'Open the FA Posting Groups page.';
                    }
                    action("Business Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Business Posting Groups';
                        RunObject = page "VAT Business Posting Groups";
                        Tooltip = 'Open the VAT Business Posting Groups page.';
                    }
                    action("Product Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Posting Groups';
                        RunObject = page "VAT Product Posting Groups";
                        Tooltip = 'Open the VAT Product Posting Groups page.';
                    }
                }
            }
        }
    }
}
