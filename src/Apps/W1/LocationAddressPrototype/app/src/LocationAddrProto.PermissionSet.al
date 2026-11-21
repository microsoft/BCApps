// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

permissionset 17700 "Location Addr. Proto"
{
    Assignable = true;
    Caption = 'Location Address Prototype';
    Permissions =
        page "Location Address Editor" = X,
        codeunit "Location Address Mgt." = X,
        codeunit "Sales Address Mgt." = X;
}
