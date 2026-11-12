// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AutomaticAccounts;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.IO;
using System.Threading;
using Microsoft.Bank.Payment;

tableextension 13537 "Posted Gen. Jnl. Payments FI" extends "Posted Gen. Journal Line"
{
    fields
    {
        field(13511; "Payment Reference No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Reference No.';
        }
        field(13512; "Bank Message Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Message Type';
            InitValue = "Reference No";
            OptionCaption = 'Reference No,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No","Invoice Information",Message,"Long Message","Tax Message";
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
            Caption = 'Payment date';
        }
    }
}
