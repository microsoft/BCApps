// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Environment;
using System.Threading;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;

tableextension 13545 "Purch. Setup Payments FI" extends "Purchases & Payables Setup"
{
    fields
    {
        field(13519; "Payment Batch Nos."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Bank Batch Nos.';
            TableRelation = "No. Series";
        }
    }
}
