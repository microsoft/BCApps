// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
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
using Microsoft.Purchases.History;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;
using Microsoft.Bank.Payment;

tableextension 13543 "Vendor Ledger Payments FI" extends "Vendor Ledger Entry"
{
    fields
    {
        field(13512; "Bank Message Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Message Type';
            InitValue = "Reference No.";
            OptionCaption = 'Reference No.,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No.","Invoice Information",Message,"Long Message","Tax Message";
        }
        field(13513; "Payment Message"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Message';
        }
        field(13514; "Payment Message 2"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Message 2';
        }
        field(13515; "Planned Payment Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Payment Date';
        }
    }
}
