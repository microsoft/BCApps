// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using System.Threading;
using System.Environment.Configuration;

page 9035 "Data Administration"
{
    PageType = List;
    Caption = 'Data Administration';
    AdditionalSearchTerms = 'Clean, Cleanup Log, Logs, Delete, Compress, Archive';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            part(TableInformationPart; "Table Information Cache Part")
            {
                ApplicationArea = All;
                Caption = 'Table Size';
                ShowFilter = false;
            }
            part(CompaniesPart; "Company Size Cache Part")
            {
                ApplicationArea = All;
                Caption = 'Company Size';
                ShowFilter = false;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Companies)
            {
                Caption = 'Companies';
                ToolTip = 'View the list of companies.';
                ApplicationArea = All;
                Image = ListPage;
                RunPageMode = View;
                RunObject = page "Companies";
            }
            action(RetentionPoliciesAction)
            {
                Caption = 'Retention Policies';
                Tooltip = 'Set up retention policies that specify how long to keep various types of data';
                ApplicationArea = All;
                Image = DeleteExpiredComponents;

                RunObject = Page "Retention Policy Setup List";
            }

        }
        area(Processing)
        {
            action(DataAdministrationGuide)
            {
                Caption = 'Data Administration Guide';
                ToolTip = 'Start a guide that can help you manage settings for deleting and compressing data.';
                ApplicationArea = All;
                RunPageMode = View;
                RunObject = page "Data Administration Guide";
            }
            action(RefreshTableInformationCache)
            {
                Caption = 'Refresh';
                ToolTip = 'Refresh the information on the page. Depending on the amount of data, this might take a few minutes.';
                ApplicationArea = All;
                Image = Refresh;

                RunObject = codeunit "Table Information Cache";
            }
            action(ScheduleBackgroundRefresh)
            {
                Caption = 'Schedule Background Refresh';
                ToolTip = 'Schedule a job queue entry to refresh the data on this page for all companies. The job queue entry will run in the background.';
                ApplicationArea = All;
                Image = Calendar;

                trigger OnAction()
                var
                    ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
                begin
                    ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();
                end;
            }
            group(DataCleanup)
            {
                Caption = 'Data Cleanup';

                group(DeleteDocumentArchives)
                {
                    Caption = 'Document Archives';

                    action(DeleteExpiredSalesQuotes)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Expired Sales Quotes';
                        Tooltip = 'Delete Expired Sales Quotes';
                        RunObject = report "Delete Expired Sales Quotes";
                        Ellipsis = true;
                    }
                }
                group(DeleteInvoicedDocuments)
                {
                    Caption = 'Invoiced Documents';

                    action(DeleteInvoicedBlanketSalesOrders)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Delete Blanket Sales Orders';
                        ToolTip = 'Delete Blanket Sales Orders';
                        RunObject = Report "Delete Invd Blnkt Sales Orders";
                        Ellipsis = true;
                    }
                    action(DeleteInvoicedSalesOrders)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Sales Orders';
                        ToolTip = 'Delete Sales Orders';
                        RunObject = Report "Delete Invoiced Sales Orders";
                        Ellipsis = true;
                    }
                    action(DeleteInvoicedSalesReturnOrders)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Delete Sales Return Orders';
                        ToolTip = 'Delete Sales Return Orders';
                        RunObject = Report "Delete Invd Sales Ret. Orders";
                        Ellipsis = true;
                    }
                    action(DeleteInvoicedBlanketPurchaseOrders)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Delete Blanket Purchase Orders';
                        ToolTip = 'Delete Blanket Purchase Orders';
                        RunObject = Report "Delete Invd Blnkt Purch Orders";
                        Ellipsis = true;
                    }
                    action(DeleteInvoicedPurchaseOrders)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Purchase Orders';
                        ToolTip = 'Delete Purchase Orders';
                        RunObject = Report "Delete Invoiced Purch. Orders";
                        Ellipsis = true;
                    }
                    action(DeleteInvoicedPurchaseReturnOrders)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Delete Purchase Return Orders';
                        ToolTip = 'Delete Purchase Return Orders';
                        RunObject = Report "Delete Invd Purch. Ret. Orders";
                        Ellipsis = true;
                    }
                    action(DeleteRegisteredWarehouseDocuments)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Delete Registered Warehouse Documents';
                        ToolTip = 'Delete Registered Warehouse Documents';
                        RunObject = Report "Delete Registered Whse. Docs.";
                        Ellipsis = true;
                    }
                }
                group(CRM)
                {
                    Caption = 'Marketing';

                    action(DeleteCampaignEntries)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Delete Campaign Entries';
                        ToolTip = 'Delete Campaign Entries';

                        RunObject = report "Delete Campaign Entries";
                        Ellipsis = true;
                    }
                    action(DeleteLoggedSegments)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Delete Logged Segments';
                        ToolTip = 'Delete Logged Segments';

                        RunObject = report "Delete Logged Segments";
                        Ellipsis = true;
                    }
                    action(DeleteOpportunities)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Delete Opportunities';
                        ToolTip = 'Delete Opportunities';

                        RunObject = report "Delete Opportunities";
                        Ellipsis = true;
                    }
                    action(DeleteTasks)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Delete Tasks';
                        ToolTip = 'Delete Tasks';

                        RunObject = report "Delete Tasks";
                        Ellipsis = true;
                    }
                    action(DeleteInteractionLogEntries)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Delete Interaction Log Entries';
                        ToolTip = 'Delete Interaction Log Entries';
                        RunObject = report "Delete Interaction Log Entries";
                        Ellipsis = true;
                    }
                }
                group(CostAccounting)
                {
                    Caption = 'Cost Accounting';

                    action(CostBudgetEntries)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Delete Cost Budget Entries';
                        ToolTip = 'Delete Cost Budget Entries';

                        RunObject = report "Delete Cost Budget Entries";
                        Ellipsis = true;
                    }
                    action(CostEntries)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Delete Cost Entries';
                        ToolTip = 'Delete Cost Entries';

                        RunObject = report "Delete Cost Entries";
                        Ellipsis = true;
                    }
                    action(OldCostEntries)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Delete Old Cost Entries';
                        ToolTip = 'Delete Old Cost Entries';

                        RunObject = report "Delete Old Cost Entries";
                        Ellipsis = true;
                    }
                }
                group(Other)
                {
                    Caption = 'Miscellaneous';

                    action(DeletePhysicalInventoryLedger)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Phys. Inventory Ledger';
                        ToolTip = 'Delete Phys. Inventory Ledger';

                        RunObject = report "Delete Phys. Inventory Ledger";
                        Ellipsis = true;
                    }
                    action(DeleteDetachedMedia)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Detached media';
                        ToolTip = 'Delete media that is not being actively referenced.';
                        Ellipsis = true;
                        RunObject = Page "Detached Media Cleanup";
                    }
                    action(CleanupDuplicatedGuidedExperienceItem)
                    {
                        ApplicationArea = All;
                        Caption = 'Delete Duplicated Guided Experience Item';
                        ToolTip = 'Cleanup Duplicated Guided Experience Items';
                        Ellipsis = true;
                        RunObject = Page "Guided Experience Item Cleanup";
                    }
                }
            }
            group(DateCompression)
            {
                Caption = 'Date Compression';
                group(CompressEntries)
                {
                    Caption = 'Compress Entries';

                    action("Date Compress G/L Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Entries';
                        Image = GeneralLedger;
                        RunObject = Report "Date Compress General Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress VAT Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Entries';
                        Image = VATStatement;
                        RunObject = Report "Date Compress VAT Entries";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Bank Account Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Ledger Entries';
                        Image = BankAccount;
                        RunObject = Report "Date Compress Bank Acc. Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress G/L Budget Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Budget Entries';
                        Image = LedgerBudget;
                        RunObject = Report "Date Compr. G/L Budget Entries";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        Image = Customer;
                        RunObject = Report "Date Compress Customer Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        Image = Vendor;
                        RunObject = Report "Date Compress Vendor Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Resource Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Ledger Entries';
                        Image = Resource;
                        RunObject = Report "Date Compress Resource Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress FA Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Ledger Entries';
                        Image = FixedAssets;
                        RunObject = Report "Date Compress FA Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Maintenance Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance Ledger Entries';
                        Image = Tools;
                        RunObject = Report "Date Compress Maint. Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Insurance Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Ledger Entries';
                        Image = Insurance;
                        RunObject = Report "Date Compress Insurance Ledger";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Entries';
                        Image = Bin;
                        RunObject = Report "Date Compress Whse. Entries";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                    action("Date Compress Item Budget Entries")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Item Budget Entries';
                        Image = LedgerBudget;
                        RunObject = Report "Date Comp. Item Budget Entries";
                        Ellipsis = true;
                        ToolTip = 'Save database space by combining related entries in one new entry. You can compress entries from closed fiscal years only.';
                    }
                }
                group(DeleteEmptyRegisters)
                {
                    Caption = 'Delete Empty Registers';

                    action(DeleteEmptyGLRegisters)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        ToolTip = 'G/L Registers';
                        RunObject = Report "Delete Empty G/L Registers";
                        Ellipsis = true;
                    }
                    action(DeleteEmptyFARegisters)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Fixed Asset Registers';
                        ToolTip = 'Fixed Asset Registers';
                        RunObject = Report "Delete Empty FA Registers";
                        Ellipsis = true;
                    }
                    action(DeleteEmptyInsuranceRegisters)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Registers';
                        ToolTip = 'Insurance Registers';
                        RunObject = report "Delete Empty Insurance Reg.";
                        Ellipsis = true;
                    }
                    action(DeleteEmptyResRegisters)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Registers';
                        ToolTip = 'Resource Registers';
                        RunObject = report "Delete Empty Res. Registers";
                        Ellipsis = true;
                    }
                    action(DeleteEmptyItemRegisters)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Registers';
                        ToolTip = 'Item Registers';
                        RunObject = report "Delete Empty Item Registers";
                        Ellipsis = true;
                    }
                    action(DeleteEmptyWhseRegisters)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Registers';
                        ToolTip = 'Warehouse Registers';
                        RunObject = report "Delete Empty Whse. Registers";
                        Ellipsis = true;
                    }
                    action(DeleteCheckLedgerEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Ledger Entries'; // U.S.: check, U.K.: cheque
                        ToolTip = 'Check Ledger Entries'; // U.S.: check, U.K.: cheque
                        RunObject = report "Delete Check Ledger Entries";
                        Ellipsis = true;
                    }
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = ' Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(DataAdministrationGuide_Promoted; DataAdministrationGuide)
                {
                }
                actionref(RefreshTableInformationCache_Promoted; RefreshTableInformationCache)
                {
                }
            }
            group(Category_Report)
            {
                Caption = ' Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    var

    trigger OnOpenPage()
    var
        DataAdminPageNotification: Codeunit "Data Admin. Page Notification";
    begin
        DataAdminPageNotification.ShowRefreshNotification();
    end;

    trigger OnClosePage()
    var
        DataAdminPageNotification: Codeunit "Data Admin. Page Notification";
    begin
        DataAdminPageNotification.RecallNotificationForCurrentUser();
    end;

}