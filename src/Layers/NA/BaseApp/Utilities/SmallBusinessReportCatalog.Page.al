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
            cuegroup(CustomersAndVendors)
            {
                Caption = 'Customers and Vendors';

                actions
                {
                    action(CustomerStatement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Statement';
                        ToolTip = 'View the list of customer statements, for example, to prepare to remind customers of late payment. You must enter a date filter to establish a statement date for open item statements or a statement period for balance forward statements.';

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