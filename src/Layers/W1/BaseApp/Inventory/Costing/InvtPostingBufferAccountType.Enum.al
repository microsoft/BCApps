// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

#pragma warning disable AL0659
enum 48 "Invt. Posting Buffer Account Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Inventory (Interim)")
    {
        Caption = 'Inventory (Interim)';
    }
    value(1; "Invt. Accrual (Interim)")
    {
        Caption = 'Invt. Accrual (Interim)';
    }
    value(2; Inventory)
    {
        Caption = 'Inventory';
    }
    value(3; "WIP Inventory")
    {
        Caption = 'WIP Inventory';
    }
    value(4; "Inventory Adjmt.")
    {
        Caption = 'Inventory Adjmt.';
    }
    value(5; "Direct Cost Applied")
    {
        Caption = 'Direct Cost Applied';
    }
    value(6; "Overhead Applied")
    {
        Caption = 'Overhead Applied';
    }
    value(7; "Purchase Variance")
    {
        Caption = 'Purchase Variance';
    }
    value(8; COGS)
    {
        Caption = 'COGS';
    }
    value(9; "COGS (Interim)")
    {
        Caption = 'COGS (Interim)';
    }
    value(10; "Material Variance")
    {
        Caption = 'Material Variance';
    }
    value(11; "Capacity Variance")
    {
        Caption = 'Capacity Variance';
    }
    value(12; "Subcontracted Variance")
    {
        Caption = 'Subcontracted Variance';
    }
    value(13; "Cap. Overhead Variance")
    {
        Caption = 'Cap. Overhead Variance';
    }
    value(14; "Mfg. Overhead Variance")
    {
        Caption = 'Mfg. Overhead Variance';
    }
    value(15; "Direct Cost Non-Inventory Applied")
    {
        Caption = 'Direct Cost Non-Inventory Applied';
    }
    value(16; "Material - Non Inventory Variance")
    {
        Caption = 'Material - Non Inventory Variance';
    }
}
