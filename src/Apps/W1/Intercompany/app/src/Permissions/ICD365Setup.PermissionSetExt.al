// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.Setup;

permissionsetextension 8405 "IC D365 SETUP" extends "D365 SETUP"
{
    Permissions =
                  tabledata "IC Setup" = RIMD;
}
