// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.CRM.Contact;
using Microsoft.Service.Contract;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Location;
using Microsoft.CRM.Team;

permissionset 8933 "Service Contract - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read service contracts';

    Permissions = tabledata Contact = R,
                  tabledata "Contract Change Log" = R,
                  tabledata "Contract Gain/Loss Entry" = R,
                  tabledata "Contract Group" = R,
                  tabledata "Contract/Service Discount" = R,
                  tabledata Currency = R,
                  tabledata Customer = R,
                  tabledata "Filed Service Contract Header" = R,
                  tabledata "Filed Contract Line" = R,
                  tabledata "Filed Serv. Contract Cmt. Line" = R,
                  tabledata "Filed Contract Service Hour" = R,
                  tabledata "Filed Contract/Serv. Discount" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Service Comment Line" = R,
                  tabledata "Service Comment Line Archive" = R,
                  tabledata "Service Contract Account Group" = R,
                  tabledata "Service Contract Header" = R,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Contract Template" = R,
                  tabledata "Service Header" = R,
                  tabledata "Service Header Archive" = R,
                  tabledata "Service Hour" = R,
                  tabledata "Service Item" = R,
                  tabledata "Service Ledger Entry" = R,
                  tabledata "Service Order Type" = R,
                  tabledata "Service Zone" = R,
                  tabledata "Ship-to Address" = R,
                  tabledata "Warranty Ledger Entry" = R;
}