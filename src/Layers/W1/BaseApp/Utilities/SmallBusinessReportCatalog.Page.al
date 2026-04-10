#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 9025 "Small Business Report Catalog"
{
    Caption = 'Report Catalog';
    PageType = CardPart;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page is no longer used.';
    ObsoleteTag = '27.0';

    layout
    {
        area(content)
        {
            cuegroup(AgedAccountsReports)
            {
                Caption = 'Aged Accounts Reports';

                actions
                {
                    action(AgedAccountsReceivable)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Receivable';
                        Image = TileReport;
                        RunPageMode = Create;
                        ToolTip = 'Specifies amounts owed by customers and the length of time outstanding.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunAgedAccountsReceivableReport(false);
                        end;
                    }
                    action(AgedAccountsPayable)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Payable';
                        Image = TileReport;
                        RunPageMode = Create;
                        ToolTip = 'Specifies amounts owed to creditors and the length of time outstanding.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunAgedAccountsPayableReport(false);
                        end;
                    }
                }
            }
            cuegroup(CustomersAndVendors)
            {
                Caption = 'Customers and Vendors';

                actions
                {
                    action(CustomerTop10List)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Top 10 List';
                        ToolTip = 'Specifies information about customers'' purchases and balances.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunCustomerTop10ListReport(false);
                        end;
                    }
                    action(VendorTop10List)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Top 10 List';
                        ToolTip = 'View a list of the vendors from whom you purchase the most or to whom you owe the most.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunVendorTop10ListReport(false);
                        end;
                    }
                    action(CustomerStatement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Statement';
                        ToolTip = 'Specifies a list of customer statements.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunCustomerStatementReport(false);
                        end;
                    }
                }
            }
            cuegroup(OtherReports)
            {
                Caption = 'Other Reports';

                actions
                {
                    action("Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Trial Balance';
                        Image = TileCurrency;
                        ToolTip = 'Specifies the chart of accounts with balances and net changes. You can use the report at the close of an accounting period or fiscal year.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunTrialBalanceReport(false);
                        end;
                    }
                    action("Detail Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detail Trial Balance';
                        Image = TileCurrency;
                        ToolTip = 'Specifies general ledger account balances and activities.';

                        trigger OnAction()
                        begin
                            SmallBusinessReportCatalogCU.RunDetailTrialBalanceReport(false);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    var
        SmallBusinessReportCatalogCU: Codeunit "Small Business Report Catalog";
}
#endif