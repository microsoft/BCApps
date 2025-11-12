// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Pricing;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Document;
using Microsoft.Service.Resources;

permissionsetextension 6472 "Service Resources - Edit" extends "Resources - Edit"
{
    Permissions =
                  tabledata "Resource Location" = RIMD,
                  tabledata "Resource Service Zone" = Rid,
                  tabledata "Resource Skill" = Rid,
                  tabledata "Serv. Price Adjustment Detail" = r,
                  tabledata "Service Invoice Line" = RM,
                  tabledata "Service Item" = r,
                  tabledata "Service Ledger Entry" = r,
                  tabledata "Service Order Allocation" = r,
                  tabledata "Warranty Ledger Entry" = r;
}
