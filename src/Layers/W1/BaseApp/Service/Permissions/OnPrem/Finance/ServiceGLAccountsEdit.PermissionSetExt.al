// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Pricing;

permissionsetextension 6465 "Service G/L Accounts - Edit" extends "General Ledger Accounts - Edit"
{
    Permissions =
                  tabledata "Service Contract Account Group" = r,
                  tabledata "Service Cost" = r;
}
