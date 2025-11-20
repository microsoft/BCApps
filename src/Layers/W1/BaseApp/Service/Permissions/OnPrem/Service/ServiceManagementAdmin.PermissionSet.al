// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.CRM.Outlook;
using Microsoft.Service.Maintenance;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.CRM.Setup;
using Microsoft.Service.Loaner;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Resources;
using Microsoft.Service.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.Item;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Sales.Pricing;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.UOM;
using Microsoft.Utilities;

permissionset 3600 "Service Management - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'SM setup';

    Permissions = tabledata "Contract Group" = RIMD,
                  tabledata "Contract/Service Discount" = RIMD,
                  tabledata Customer = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Customer Templ." = RIMD,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "Exchange Folder" = RIMD,
                  tabledata "Fault Area" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata Item = R,
                  tabledata "Job Responsibility" = R,
                  tabledata Loaner = RIMD,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata "Payment Terms" = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Resolution Code" = RIMD,
                  tabledata Resource = R,
                  tabledata "Resource Service Zone" = RIMD,
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Serv. Price Adjustment Detail" = RIMD,
                  tabledata "Serv. Price Group Setup" = RIMD,
                  tabledata "Service Comment Line" = RIMD,
                  tabledata "Service Comment Line Archive" = RIMD,
                  tabledata "Service Contract Header" = RIMD,
                  tabledata "Service Cost" = RIMD,
                  tabledata "Service Hour" = RIMD,
                  tabledata "Service Item" = R,
                  tabledata "Service Item Group" = RIMD,
                  tabledata "Service Item Line" = R,
                  tabledata "Service Item Line Archive" = R,
                  tabledata "Service Line" = R,
                  tabledata "Service Line Archive" = R,
                  tabledata "Service Line Price Adjmt." = RIMD,
                  tabledata "Service Mgt. Setup" = RIMD,
                  tabledata "Service Order Type" = RIMD,
                  tabledata "Service Price Adjustment Group" = RIMD,
                  tabledata "Service Price Group" = RIMD,
                  tabledata "Service Shelf" = RIMD,
                  tabledata "Service Status Priority Setup" = RIMD,
                  tabledata "Service Zone" = RIMD,
                  tabledata "Skill Code" = RIMD,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Unit of Measure" = R,
                  tabledata "Work Type" = R,
                  tabledata "Work-Hour Template" = RIMD;
}
