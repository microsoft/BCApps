// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;

permissionsetextension 8409 "IC GENERAL LEDGER ACCOUNTS - EDIT" extends "General Ledger Accounts - Edit"
{
    Permissions =
                  tabledata "IC Bank Account" = r,
                  tabledata "IC G/L Account" = Rm,
                  tabledata "IC Partner" = r;
}
