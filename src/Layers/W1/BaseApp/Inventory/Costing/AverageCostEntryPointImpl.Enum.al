// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5848 "Average Cost Entry Point Impl." implements "Average Cost Entry Point"
{
    Extensible = true;

    value(5848; "Default Implementation")
    {
        Caption = 'Default Implementation';
        Implementation = "Average Cost Entry Point" = "Avg. Cost Entry Point Mgt.";
    }
}
