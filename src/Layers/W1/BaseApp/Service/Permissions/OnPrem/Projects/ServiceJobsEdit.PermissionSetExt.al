// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;

permissionsetextension 6469 "Service Jobs - Edit" extends "Jobs - Edit"
{
    Permissions = tabledata "Service Header" = r,
                  tabledata "Service Header Archive" = r,
                  tabledata "Service Invoice Line" = r,
                  tabledata "Service Ledger Entry" = r;
}
