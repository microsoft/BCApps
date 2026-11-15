// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Finance.ReceivablesPayables;

permissionsetextension 17702 "CRT GLOBAL DIM MGT" extends "D365 GLOBAL DIM MGT"
{
    Permissions = tabledata "Cartera Doc." = RM,
                  tabledata "Closed Cartera Doc." = RM,
                  tabledata "Posted Cartera Doc." = RM;
}
