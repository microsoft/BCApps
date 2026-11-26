// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.GLAccount;

permissionsetextension 8411 "IC RESOURCES - EDIT" extends "Resources - Edit"
{
    Permissions =
                  tabledata "IC G/L Account" = R;
}
