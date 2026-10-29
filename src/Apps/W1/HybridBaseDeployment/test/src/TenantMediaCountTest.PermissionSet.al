// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

permissionset 139656 "HBD Media Count Test"
{
    Assignable = false;

    Permissions = tabledata "Hybrid Company Status" = R,
                  tabledata "Hybrid Deployment Setup" = R;
}
