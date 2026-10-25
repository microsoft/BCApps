// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

permissionsetextension 8408 "IC GENERAL LEDGER - ADMIN" extends "General Ledger - Admin"
{
    Permissions =
                  tabledata "IC Bank Account" = RIMD,
                  tabledata "IC Dimension" = RIMD,
                  tabledata "IC Dimension Value" = RIMD,
                  tabledata "IC G/L Account" = RIMD,
                  tabledata "IC Partner" = RIMD,
                  tabledata "IC Setup" = RIMD;
}
