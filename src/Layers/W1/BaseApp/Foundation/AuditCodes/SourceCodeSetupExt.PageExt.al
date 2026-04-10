// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 279 SourceCodeSetupExt extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    layout
    {
        addfirst(content)
        {
            group(General)
            {
                Caption = 'General';
                field("General Journal"; Rec."General Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a general journal of the general type.';
                }
                field("IC General Journal"; Rec."IC General Journal")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code linked to entries that are posted from an intercompany general journal.';
                }
                field("Close Income Statement"; Rec."Close Income Statement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted when you run the Close Income Statement batch job.';
                }
                field("VAT Settlement"; Rec."VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Calc. and Post VAT Settlement batch job.';
                }
                field("Exchange Rate Adjmt."; Rec."Exchange Rate Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted when you run the Adjust Exchange Rates batch job.';
                }
                field("G/L Currency Revaluation"; Rec."G/L Currency Revaluation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted when you run the G/L Currency Revaluation batch job.';
                }
                field("Deleted Document"; Rec."Deleted Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted in connection with the deletion of a document.';
                }
                field("Adjust Add. Reporting Currency"; Rec."Adjust Add. Reporting Currency")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted when you change the additional reporting currency in the General Ledger Setup table.';
                }
                field("Compress G/L"; Rec."Compress G/L")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress General Ledger batch job.';
                }
                field("Compress VAT Entries"; Rec."Compress VAT Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress VAT Entries batch job.';
                }
                field("Compress Bank Acc. Ledger"; Rec."Compress Bank Acc. Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Bank Acc. Ledger batch job.';
                }
                field("Compress Check Ledger"; Rec."Compress Check Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Delete Check Ledger Entries batch job.';
                }
                field("Financially Voided Check"; Rec."Financially Voided Check")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to check ledger entries with the entry status Financially Voided.';
                }
                field("Trans. Bank Rec. to Gen. Jnl."; Rec."Trans. Bank Rec. to Gen. Jnl.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries posted after being transferred from a bank reconciliation by the Trans. Bank Rec. to Gen. Jnl. batch job.';
                }
                field(Reversal; Rec.Reversal)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from the Reverse Entries window.';
                }
                field("Cash Flow Worksheet"; Rec."Cash Flow Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code assigned to entries that are posted from the cash flow worksheet.';
                }
                field("Payment Reconciliation Journal"; Rec."Payment Reconciliation Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a payment reconciliation journal.';
                }
                field(Consolidation; Rec.Consolidation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from Consolidation.';
                }
                field(GeneralDeferral; Rec."General Deferral")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a general journal deferrals.';
                }
                field(SalesDeferral; Rec."Sales Deferral")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a sales deferrals.';
                }
                field(PurchaseDeferral; Rec."Purchase Deferral")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a purchase deferrals.';
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field(Control14; Rec.Sales)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted in connection with sales, such as orders, invoices, and credit memos.';
                }
                field("Sales Journal"; Rec."Sales Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries posted from a general journal of the sales type.';
                }
                field("Cash Receipt Journal"; Rec."Cash Receipt Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a general journal of the cash receipts type.';
                }
                field("Sales Entry Application"; Rec."Sales Entry Application")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from the Apply Customer Entries window.';
                }
                field("Unapplied Sales Entry Appln."; Rec."Unapplied Sales Entry Appln.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from the Unapply Customer Entries window.';
                }
                field(Reminder; Rec.Reminder)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a Reminder.';
                }
                field("Finance Charge Memo"; Rec."Finance Charge Memo")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a Finance Charge Memo.';
                }
                field("Compress Cust. Ledger"; Rec."Compress Cust. Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Customer Ledger batch job.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field(Control26; Rec.Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted in connection with purchases, such as orders, invoices, and credit memos.';
                }
                field("Purchase Journal"; Rec."Purchase Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a general journal of the purchase type.';
                }
                field("Payment Journal"; Rec."Payment Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a general journal of the payments type.';
                }
                field("Purchase Entry Application"; Rec."Purchase Entry Application")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from the Apply Vendor Entries window.';
                }
                field("Unapplied Purch. Entry Appln."; Rec."Unapplied Purch. Entry Appln.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from the Unapply Vendor Entries window.';
                }
                field("Compress Vend. Ledger"; Rec."Compress Vend. Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Vendor Ledger batch job.';
                }
            }
            group(Employees)
            {
                Caption = 'Employees';
                field("Employee Entry Application"; Rec."Employee Entry Application")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from the Apply Employee Entries window.';
                }
                field("Unapplied Empl. Entry Appln."; Rec."Unapplied Empl. Entry Appln.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from the Unapply Employee Entries window.';
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field(Transfer; Rec.Transfer)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted in connection with transfer orders.';
                }
                field("Item Journal"; Rec."Item Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from an item journal.';
                }
                field("Item Reclass. Journal"; Rec."Item Reclass. Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code to use in item reclassification journals.';
                }
                field("Phys. Inventory Journal"; Rec."Phys. Inventory Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a Physical Inventory Journal.';
                }
                field("Phys. Invt. Orders"; Rec."Phys. Invt. Orders")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source code to use in physical inventory orders.';
                }
                field("Revaluation Journal"; Rec."Revaluation Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a Revaluation Journal.';
                }
                field("Inventory Post Cost"; Rec."Inventory Post Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted when you run the Post Inventory Cost to G/L batch job.';
                }
                field("Compress Item Ledger"; Rec."Compress Item Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Item Ledger batch job.';
                }
                field("Compress Item Budget"; Rec."Compress Item Budget")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code that is linked to the compressed item budget entries.';
                }
                field("Adjust Cost"; Rec."Adjust Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are the result of a cost adjustment.';
                }
                field(Assembly; Rec.Assembly)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code that is linked to entries that are posted with assembly orders.';
                }
                field("Invt. Receipt"; Rec."Invt. Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the inventory receipt.';
                }
                field("Invt. Shipment"; Rec."Invt. Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the inventory shipment.';
                }
            }
            group(Resources)
            {
                Caption = 'Resources';
                field("Resource Journal"; Rec."Resource Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a Resource Journal.';
                }
                field("Compress Res. Ledger"; Rec."Compress Res. Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Resource Ledger batch job.';
                }
            }
            group(Jobs)
            {
                Caption = 'Projects';
                field("Job Journal"; Rec."Job Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a project journal.';
                }
                field("Job G/L Journal"; Rec."Job G/L Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from a general journal of the Project G/L Journal type.';
                }
                field("Job G/L WIP"; Rec."Job G/L WIP")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from the Project Post WIP to G/L batch job in the Projects module.';
                }
                field("Compress Job Ledger"; Rec."Compress Job Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Project Ledger batch job.';
                }
            }
            group("Fixed Assets")
            {
                Caption = 'Fixed Assets';
                field("Fixed Asset G/L Journal"; Rec."Fixed Asset G/L Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a fixed asset G/L journal.';
                }
                field("Fixed Asset Journal"; Rec."Fixed Asset Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a fixed asset journal.';
                }
                field("Insurance Journal"; Rec."Insurance Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from an insurance journal.';
                }
                field("Compress FA Ledger"; Rec."Compress FA Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress FA Ledger batch job.';
                }
                field("Compress Maintenance Ledger"; Rec."Compress Maintenance Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Maint. Ledger batch job.';
                }
                field("Compress Insurance Ledger"; Rec."Compress Insurance Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Insurance Ledger batch job.';
                }
            }
            group(Manufacturing)
            {
                Caption = 'Manufacturing';
                field("Consumption Journal"; Rec."Consumption Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a consumption journal.';
                }
                field("Output Journal"; Rec."Output Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from an output journal.';
                }
                field(Flushing; Rec.Flushing)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to consumption entries that are posted when you change the status of a released production order to Finished.';
                }
                field("Capacity Journal"; Rec."Capacity Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted from a capacity journal.';
                }
                field("Production Journal"; Rec."Production Journal")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code that is linked to the entries that are posted from a production journal.';
                }
                field("Production Order"; Rec."Production Order")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code that is used for def. dimension priorities on Prod. Order Components.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Whse. Item Journal"; Rec."Whse. Item Journal")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the Warehouse Item Journal.';
                }
                field("Whse. Reclassification Journal"; Rec."Whse. Reclassification Journal")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the Warehouse Reclassification Journal.';
                }
                field("Whse. Phys. Invt. Journal"; Rec."Whse. Phys. Invt. Journal")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the Warehouse Physical Inventory Journal.';
                }
                field("Whse. Put-away"; Rec."Whse. Put-away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the Warehouse Put-away.';
                }
                field("Whse. Pick"; Rec."Whse. Pick")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the Warehouse Pick.';
                }
                field("Whse. Movement"; Rec."Whse. Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the Warehouse movement.';
                }
                field("Compress Whse. Entries"; Rec."Compress Whse. Entries")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Whse. Entries batch job.';
                }
            }
            group("Cost Accounting")
            {
                Caption = 'Cost Accounting';
                field("G/L Entry to CA"; Rec."G/L Entry to CA")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from transferring general ledger entries to cost entries.';
                }
                field("Cost Journal"; Rec."Cost Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from a cost journal.';
                }
                field("Cost Allocation"; Rec."Cost Allocation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to entries that are posted from cost allocations.';
                }
                field("Transfer Budget to Actual"; Rec."Transfer Budget to Actual")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted by running the Transfer Budget to Actual batch job.';
                }
            }
        }
    }
}