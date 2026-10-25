// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.Setup;

permissionsetextension 8403 "IC D365 BASIC ISV" extends "D365 BASIC ISV"
{
    Permissions =
                  tabledata "IC Setup" = RIMD;
}
