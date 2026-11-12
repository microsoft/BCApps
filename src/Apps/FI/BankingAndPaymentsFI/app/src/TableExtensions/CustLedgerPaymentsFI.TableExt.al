// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;
using Microsoft.Bank.Payment;

tableextension 13551 "Cust. Ledger Payments FI" extends "Cust. Ledger Entry"
{
    fields
    {
        field(13511; "Payment Reference No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Reference No.';
        }
        field(13516; "Disreg. Full Payment Discount"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Disreg. Pmt. Disc. at Full Pmt';
        }
    }

    keys
    {
        key(PaymentReference; "Payment Reference No.") { }
    }
}
