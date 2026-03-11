// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions;

using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;

enum 20456 "Qlty. Disposition Action" implements "Qlty. Disposition"
{
    Extensible = true;
    Caption = 'Quality Disposition Action';

    value(0; "Change Item Tracking")
    {
        Caption = 'Change Item Tracking';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Change Tracking";
    }
    value(1; "Move with Item Reclassification")
    {
        Caption = 'Move with Item Reclassification';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Move Item Reclass.";
    }
    value(2; "Move with Warehouse Reclassification")
    {
        Caption = 'Move with Warehouse Reclassification';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Move Whse.Reclass.";
    }
    value(3; "Move with Internal Movement")
    {
        Caption = 'Move with Internal Movement';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Internal Move";
    }
    value(4; "Move with Movement Worksheet")
    {
        Caption = 'Move with Movement Worksheet';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Move Worksheet";
    }
    value(6; "Move with automatic choice")
    {
        Caption = 'Move with automatic choice';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Move Auto Choose";
    }
    value(7; "Dispose with Negative Inventory Adjustment")
    {
        Caption = 'Dispose with Negative Inventory Adjustment';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Neg. Adjust Inv.";
    }
    value(8; "Create Internal Put-away")
    {
        Caption = 'Create Internal Put-away';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Internal Put-away";
    }
    value(9; "Create Warehouse Put-away")
    {
        Caption = 'Create Warehouse Put-away';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Warehouse Put-away";
    }
    value(10; "Create Transfer Order")
    {
        Caption = 'Create Transfer Order';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Transfer";
    }
    value(11; "Create Purchase Return")
    {
        Caption = 'Create Purchase Return';
        Implementation = "Qlty. Disposition" = "Qlty. Disp. Purchase Return";
    }
}
