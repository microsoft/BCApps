// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Automation;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

tableextension 13540 "Purch. Inv. Payments FI" extends "Purch. Inv. Header"
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
    }
}
