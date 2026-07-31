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
                        ToolTip = 'Specifies the Cartera Journal for this bank account.';
                    }
                    action("Receivables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receivables Docs';
                        RunObject = page "Receivables Cartera Docs";
                        ToolTip = 'Specifies the receivables documents for this bank account.';
                    }
                    action("Bill Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill Groups';
                        RunObject = page "Bill Groups List";
                        ToolTip = 'Specifies the bill groups for this bank account.';
                    }
                    action("Posted Bill Group Select.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Bill Groups';
                        RunObject = page "Posted Bill Groups List";
                        ToolTip = 'Specifies the posted bill groups for this bank account.';
                    }
                    action("Closed Receivables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Receivables Docs';
                        RunObject = page "Receivable Closed Cartera Docs";
                        ToolTip = 'Specifies the closed receivables documents for this bank account.';
                    }
                    action("Closed Bill Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Bill Groups';
                        RunObject = page "Closed Bill Groups List";
                        ToolTip = 'Specifies the closed bill groups for this bank account.';
                    }
                    group("Group64")
                    {
                        Caption = 'Batch Settlement';
                        action("Posted Bill &Groups")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posted Bill Groups (Batch)';
                            RunObject = page "Posted Bill Group Select.";
                            ToolTip = 'Specifies the posted bill groups for this bank account.';
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
                        ToolTip = 'Specifies the Cartera Journal for this bank account.';
                    }
                    action("Payables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payables Docs';
                        RunObject = page "Payables Cartera Docs";
                        ToolTip = 'Specifies the payables documents for this bank account.';
                    }
                    action("Payment Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Orders';
                        RunObject = page "Payment Orders List";
                        ToolTip = 'Specifies the payment orders for this bank account.';
                    }
                    action("Posted Payment Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Orders';
                        RunObject = page "Posted Payment Orders List";
                        ToolTip = 'Specifies the posted payment orders for this bank account.';
                    }
                    action("Closed Payables Docs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Payables Docs';
                        RunObject = page "Payable Closed Cartera Docs";
                        ToolTip = 'Specifies the closed payables documents for this bank account.';
                    }
                    action("Closed Payment Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Payment Orders';
                        RunObject = page "Closed Payment Orders List";
                        ToolTip = 'Specifies the closed payment orders for this bank account.';
                    }
                    group("Group66")
                    {
                        Caption = 'Batch Settlement';
                        action("Posted Payment &Orders")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posted Payment Orders (Batch)';
                            RunObject = page "Posted Payment Orders Select.";
                            ToolTip = 'Specifies the posted payment orders for this bank account.';
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
                        ToolTip = 'Specifies the bank summary bill group for this bank account.';
                    }
                    action("Bank - Risk")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank - Risk';
                        RunObject = report "Bank - Risk";
                        ToolTip = 'Specifies the bank risk report for this bank account.';
                    }
                    action("Customer - Due Payments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Due Payments';
                        RunObject = report "Customer - Due Payments";
                        ToolTip = 'Specifies the customer due payments for this bank account.';
                    }
                    action("Payment Order Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Order Listing';
                        RunObject = report "Payment Order Listing";
                        ToolTip = 'Specifies the payment order listing for this bank account.';
                    }
                    action("Closed Payment Order Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Payment Order Listing';
                        RunObject = report "Closed Payment Order Listing";
                        ToolTip = 'Specifies the closed payment order listing for this bank account.';
                    }
                    action("Posted Payment Order Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Order Listing';
                        RunObject = report "Posted Payment Order Listing";
                        ToolTip = 'Specifies the posted payment order listing for this bank account.';
                    }
                    action("Closed Bill Group Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closed Bill Group Listing';
                        RunObject = report "Closed Bill Group Listing";
                        ToolTip = 'Specifies the closed bill group listing for this bank account.';
                    }
                    action("Posted Bill Group Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Bill Group Listing';
                        RunObject = report "Posted Bill Group Listing";
                        ToolTip = 'Specifies the posted bill group listing for this bank account.';
                    }
                    action("Bill Group Listing")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill Group Listing';
                        RunObject = report "Bill Group Listing";
                        ToolTip = 'Specifies the bill group listing for this bank account.';
                    }
                    action("Notice Assignement Credits")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Notice Assignement Credits';
                        ToolTip = 'Specifies the notice assignment credits for this bank account.';
                        RunObject = report "Notice Assignment Credits";
                    }
                    action("Payment order - Export N34")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment order - Export N34';
                        ToolTip = 'Specifies the payment order export N34 for this bank account.';
                        RunObject = report "Payment order - Export N34";
                    }
                    action("PO - Export N34.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'PO - Export N34.1';
                        ToolTip = 'Specifies the PO export N34.1 for this bank account.';
                        RunObject = report "PO - Export N34.1";
                    }
                    action("Void PO - Export")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Void PO - Export';
                        ToolTip = 'Specifies the void PO export for this bank account.';
                        RunObject = report "Void PO - Export";
                    }
                    action("Vendor - Due Payments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Due Payments';
                        ToolTip = 'Specifies the vendor due payments for this bank account.';
                        RunObject = report "Vendor - Due Payments";
                    }
                    action("Bill group - Export factoring")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill group - Export factoring';
                        ToolTip = 'Specifies the bill group export factoring for this bank account.';
                        RunObject = report "Bill group - Export factoring";
                    }
                    action("Bill group - Export factoring1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bill group - Export factoring';
                        RunObject = report "Bill group - Export factoring";
                        ToolTip = 'Specifies the bill group export factoring for this bank account.';
                    }
                }
                group("Group68")
                {
                    Caption = 'Setup';
                    action("Cartera Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Setup';
                        ToolTip = 'Specifies the Cartera setup for this bank account.';
                        RunObject = page "Cartera Setup";
                    }
                    action("Cartera Source Code Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Source Code Setup';
                        RunObject = page "Cartera Source Cd. Setup";
                        ToolTip = 'Specifies the Cartera source code setup for this bank account.';
                    }
                    action("Category Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Category Codes';
                        RunObject = page "Category Codes";
                        ToolTip = 'Specifies the category codes for this bank account.';
                    }
                    action("Cartera Report Selections")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cartera Report Selections';
                        RunObject = page "Report Selection - Cartera";
                        ToolTip = 'Specifies the Cartera report selections for this bank account.';
                    }
                }
            }
        }
    }
}