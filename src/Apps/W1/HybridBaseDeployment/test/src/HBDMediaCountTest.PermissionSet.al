// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.DataMigration;

using Microsoft.DataMigration;
using System.Environment;

permissionset 139656 "HBD Media Count Test"
{
    Assignable = false;

    Permissions = tabledata "Hybrid Company Status" = R,
                  tabledata "Hybrid Deployment Setup" = R;
}
