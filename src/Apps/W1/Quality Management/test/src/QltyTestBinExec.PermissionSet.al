// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

permissionset 139957 "Qlty. Test Bin Exec"
{
    Assignable = true;

    // Supply execution prerequisites without granting the bin data or page access under test.
    Permissions = codeunit "Library Assert" = X,
                  table Bin = X;
}
