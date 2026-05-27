// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;

pageextension 20428 "Qlty. Item Tracing" extends "Item Tracing"
{
    actions
    {
        addlast(Item)
        {
            action(Qlty_QualityInspections)
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Caption = 'Quality Inspections';
                Image = CheckList;
                ToolTip = 'View quality inspections filtered by the selected item, variant, location, and tracking details.';
                RunObject = Page "Qlty. Inspection List";
                RunPageLink = "Source Item No." = field("Item No."),
                              "Source Variant Code" = field("Variant Code"),
                              "Source Lot No." = field("Lot No."),
                              "Source Serial No." = field("Serial No."),
                              "Source Package No." = field("Package No.");
                RunPageView = sorting("Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.");
            }
        }
    }
}
