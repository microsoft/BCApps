// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

enum 5701 "Put-away Bin Policy"
{
    Extensible = true;

    value(100; "Default Bin")
    {
        Caption = 'Default Bin';
    }

    value(200; "Put-away Template")
    {
        Caption = 'Put-away Template';
    }
}
