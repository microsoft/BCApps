// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using Microsoft.Warehouse.Structure;

/// <summary>
/// Allows destination bin selection for manual quality dispositions.
/// Assign alongside the Quality Inspector or Quality Admin and Supervisor role.
/// </summary>
permissionset 20408 "QltyMgmt - Bin View"
{
    Caption = 'Quality Destination Bin Lookup';
    Access = Public;
    Assignable = true;

    Permissions =
        tabledata Bin = R,
        page "Bin List" = X;
}
