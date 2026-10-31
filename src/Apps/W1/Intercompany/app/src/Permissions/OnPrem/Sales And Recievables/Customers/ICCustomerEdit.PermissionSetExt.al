// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Partner;

permissionsetextension 8412 "IC CUSTOMER - EDIT" extends "Customer - Edit"
{
    Permissions =
                  tabledata "IC Bank Account" = Rm,
                  tabledata "IC Partner" = Rm;
}
