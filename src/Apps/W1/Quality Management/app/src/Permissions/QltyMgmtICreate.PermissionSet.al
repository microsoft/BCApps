// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;

/// <summary>
/// Grants the minimum permissions required to initiate quality inspections from
/// automatic procedures triggered by other operations (for example, production order
/// completion, purchase receipts, warehouse activities, and similar background
/// scenarios), as well as from manual actions invoked by the user in the UI
/// (for example, the "Create Quality Inspection" action on documents and lines).
/// Setup and configuration data is exposed as read-only, while inspection
/// records can be created and updated, so that Quality Management data is only
/// modified through Quality Management code paths and not by direct user interaction.
/// </summary>
permissionset 20407 "QltyMgmt - I. Create"
{
    Caption = 'Quality Inspection - Create';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMgmt - Objects";

    Permissions =
        tabledata "Qlty. Management Setup" = r,
        tabledata "Qlty. Inspection Gen. Rule" = r,
        tabledata "Qlty. Inspection Result" = r,
        tabledata "Qlty. Test" = r,
        tabledata "Qlty. Test Lookup Value" = r,
        tabledata "Qlty. Inspection Template Hdr." = r,
        tabledata "Qlty. Inspection Template Line" = r,
        tabledata "Qlty. Inspect. Source Config." = r,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = r,
        tabledata "Qlty. Inspection Header" = rIm,
        tabledata "Qlty. Inspection Line" = rIm,
        tabledata "Qlty. I. Result Condit. Conf." = rIm,
        tabledata Item = r,
        tabledata "Reservation Entry" = r,
        tabledata "Tracking Specification" = r,
        tabledata "Warehouse Entry" = r,
        tabledata "Warehouse Journal Line" = r,
        tabledata "Warehouse Receipt Line" = r,
        tabledata "Sales Line" = r,
        tabledata "Purchase Line" = r,
        tabledata "Prod. Order Line" = r,
        tabledata "Prod. Order Routing Line" = r,
        tabledata "Item Journal Line" = r,
        tabledata "Item Ledger Entry" = r,
        tabledata "Transfer Line" = r,
        tabledata "Posted Assembly Header" = r;
}
