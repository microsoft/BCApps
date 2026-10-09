// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
permissionset 50150 "Rep. Filename Test"
{
    Assignable = true;

    // Direct permissions needed for tests
    Permissions =
        tabledata "Filename Proof Document" = RIMD,
        tabledata "Filename Proof Log" = RIMD;
}
