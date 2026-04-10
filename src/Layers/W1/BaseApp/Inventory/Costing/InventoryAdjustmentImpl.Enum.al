// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5895 "Inventory Adjustment Impl." implements "Inventory Adjustment"
{
    Extensible = true;

    value(5895; "Default Implementation")
    {
        Caption = 'Default Implementation';
        Implementation = "Inventory Adjustment" = "Inventory Adjustment";
    }
}
