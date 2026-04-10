// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;

permissionsetextension 6468 "Service Inventory - Edit" extends "Inventory - Edit"
{
    Permissions = tabledata "Filed Contract Line" = r,
                  tabledata Loaner = r,
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Serv. Price Adjustment Detail" = r,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Invoice Line" = R,
                  tabledata "Service Item" = R,
                  tabledata "Service Item Component" = R,
                  tabledata "Service Item Group" = R,
                  tabledata "Service Item Line" = r,
                  tabledata "Service Ledger Entry" = r,
                  tabledata "Troubleshooting Setup" = Rd,
                  tabledata "Warranty Ledger Entry" = r;
}