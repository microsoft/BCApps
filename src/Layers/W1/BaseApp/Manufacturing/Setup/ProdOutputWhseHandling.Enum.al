// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

enum 99000701 "Prod. Output Whse. Handling"
{
    Extensible = true;

    value(0; "No Warehouse Handling")
    {
        Caption = 'No Warehouse Handling';
    }
    value(20; "Inventory Put-away")
    {
        Caption = 'Inventory Put-away';
    }
    value(40; "Warehouse Put-away")
    {
        Caption = 'Warehouse Put-away';
    }
}
