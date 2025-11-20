// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Archive;
using Microsoft.Service.Resources;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Document;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Service.Maintenance;
using Microsoft.Purchases.Vendor;

permissionset 2805 "Service Items - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read service items';

    Permissions = tabledata Customer = R,
                  tabledata Item = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Resource = R,
                  tabledata "Resource Skill" = R,
                  tabledata "Service Comment Line" = RI,
                  tabledata "Service Comment Line Archive" = R,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Cr.Memo Line" = R,
                  tabledata "Service Invoice Line" = R,
                  tabledata "Service Item" = R,
                  tabledata "Service Item Component" = R,
                  tabledata "Service Item Group" = R,
                  tabledata "Service Item Line" = R,
                  tabledata "Service Item Line Archive" = R,
                  tabledata "Service Item Log" = R,
                  tabledata "Service Ledger Entry" = R,
                  tabledata "Service Line" = R,
                  tabledata "Service Line Archive" = R,
                  tabledata "Service Mgt. Setup" = R,
                  tabledata "Service Shipment Item Line" = R,
                  tabledata "Service Shipment Line" = R,
                  tabledata "Ship-to Address" = R,
                  tabledata "Troubleshooting Header" = R,
                  tabledata "Troubleshooting Line" = R,
                  tabledata "Troubleshooting Setup" = R,
                  tabledata Vendor = R,
                  tabledata "Warranty Ledger Entry" = R;
}
