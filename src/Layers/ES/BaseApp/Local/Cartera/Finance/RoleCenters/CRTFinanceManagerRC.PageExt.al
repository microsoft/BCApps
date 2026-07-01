// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;

pageextension 7000171 "CRT Finance Manager RC" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Group")
        {
            group("Group62")
            {
                Caption = 'Cartera';
                group("Group63")
                {
                    Caption = 'Receivables';
                    action("Cartera Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Journal';
                        RunObject = page "Cartera Journal";
                    }
                    action("Receivables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receivables Docs';
                        RunObject = page "Receivables Cartera Docs";
                    }
                    action("Bill Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill Groups';
                        RunObject = page "Bill Groups List";
                    }
                    action("Posted Bill Group Select.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Bill Groups';
                        RunObject = page "Posted Bill Groups List";
                    }
                    action("Closed Receivables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Receivables Docs';
                        RunObject = page "Receivable Closed Cartera Docs";
                    }
                    action("Closed Bill Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Bill Groups';
                        RunObject = page "Closed Bill Groups List";
                    }
                    group("Group64")
                    {
                        Caption = 'Batch Settlement';
                        action("Posted Bill &Groups")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posted Bill Groups (Batch)';
                            RunObject = page "Posted Bill Group Select.";
                        }
                    }
                }
                group("Group65")
                {
                    Caption = 'Payables';
                    action("Cartera Journal1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Journal';
                        RunObject = page "Cartera Journal";
                    }
                    action("Payables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payables Docs';
                        RunObject = page "Payables Cartera Docs";
                    }
                    action("Payment Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Orders';
                        RunObject = page "Payment Orders List";
                    }
                    action("Posted Payment Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Orders';
                        RunObject = page "Posted Payment Orders List";
                    }
                    action("Closed Payables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Payables Docs';
                        RunObject = page "Payable Closed Cartera Docs";
                    }
                    action("Closed Payment Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Payment Orders';
                        RunObject = page "Closed Payment Orders List";
                    }
                    group("Group66")
                    {
                        Caption = 'Batch Settlement';
                        action("Posted Payment &Orders")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posted Payment Orders (Batch)';
                            RunObject = page "Posted Payment Orders Select.";
                        }
                    }
                }
                group("Group67")
                {
                    Caption = 'Reports';
                    action("Bank - Summ. Bill Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank - Summ. Bill Group';
                        RunObject = report "Bank - Summ. Bill Group";
                    }
                    action("Bank - Risk")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank - Risk';
                        RunObject = report "Bank - Risk";
                    }
                    action("Customer - Due Payments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Due Payments';
                        RunObject = report "Customer - Due Payments";
                    }
                    action("Payment Order Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Order Listing';
                        RunObject = report "Payment Order Listing";
                    }
                    action("Closed Payment Order Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Payment Order Listing';
                        RunObject = report "Closed Payment Order Listing";
                    }
                    action("Posted Payment Order Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Order Listing';
                        RunObject = report "Posted Payment Order Listing";
                    }
                    action("Closed Bill Group Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Bill Group Listing';
                        RunObject = report "Closed Bill Group Listing";
                    }
                    action("Posted Bill Group Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Bill Group Listing';
                        RunObject = report "Posted Bill Group Listing";
                    }
                    action("Bill Group Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill Group Listing';
                        RunObject = report "Bill Group Listing";
                    }
                    action("Notice Assignement Credits")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Notice Assignement Credits';
                        RunObject = report "Notice Assignment Credits";
                    }
                    action("Payment order - Export N34")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment order - Export N34';
                        RunObject = report "Payment order - Export N34";
                    }
                    action("PO - Export N34.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'PO - Export N34.1';
                        RunObject = report "PO - Export N34.1";
                    }
                    action("Void PO - Export")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Void PO - Export';
                        RunObject = report "Void PO - Export";
                    }
                    action("Vendor - Due Payments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Due Payments';
                        RunObject = report "Vendor - Due Payments";
                    }
                    action("Bill group - Export factoring")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill group - Export factoring';
                        RunObject = report "Bill group - Export factoring";
                    }
                    action("Bill group - Export factoring1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill group - Export factoring';
                        RunObject = report "Bill group - Export factoring";
                    }
                }
                group("Group68")
                {
                    Caption = 'Setup';
                    action("Cartera Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Setup';
                        RunObject = page "Cartera Setup";
                    }
                    action("Cartera Source Code Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Source Code Setup';
                        RunObject = page "Cartera Source Cd. Setup";
                    }
                    action("Category Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Category Codes';
                        RunObject = page "Category Codes";
                    }
                    action("Cartera Report Selections")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Report Selections';
                        RunObject = page "Report Selection - Cartera";
                    }
                }
            }
        }
    }
}