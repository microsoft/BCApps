// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Contract;

permissionsetextension 6467 "Service G/L Accounts - View" extends "General Ledger Accounts - View"
{
    Permissions = tabledata "Service Contract Account Group" = R;
}