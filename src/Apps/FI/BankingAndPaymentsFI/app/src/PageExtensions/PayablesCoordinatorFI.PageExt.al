// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Task;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.Threading;

pageextension 13562 "Payables Coordinator FI" extends "Acc. Payables Coordinator RC"
{
    actions
    {
        addlast(Sections)
        {
            action("Bank payments to send FI")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank payments to send';
                Image = VendorPayment;
                RunObject = Page "Bank Payments to send FI";
                ToolTip = 'View the payments that will be registered to the vendors.';
            }
        }
    }
}
