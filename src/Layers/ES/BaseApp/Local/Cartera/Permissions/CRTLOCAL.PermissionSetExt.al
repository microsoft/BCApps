// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

permissionsetextension 7000100 "CRT LOCAL" extends "LOCAL"
{
    Permissions = tabledata "BG/PO Comment Line" = RIMD,
                  tabledata "BG/PO Post. Buffer" = RIMD,
                  tabledata "Bill Group" = RIMD,
                  tabledata "Cartera Doc." = RIMd,
                  tabledata "Cartera Report Selections" = RIMD,
                  tabledata "Cartera Setup" = RIMD,
                  tabledata "Closed Bill Group" = RIMd,
                  tabledata "Closed Cartera Doc." = RIMd,
                  tabledata "Closed Payment Order" = RIMd,
                  tabledata "Customer Rating" = RIMD,
                  tabledata "Doc. Post. Buffer" = RIMD,
                  tabledata "Fee Range" = RIMD,
                  tabledata Installment = RIMD,
                  tabledata "Non-Payment Period" = RIMD,
                  tabledata "Operation Fee" = RIMD,
                  tabledata "Payment Day" = RIMD,
                  tabledata "Payment Order" = RIMD,
                  tabledata "Posted Bill Group" = RIMd,
                  tabledata "Posted Cartera Doc." = RIMd,
                  tabledata "Posted Payment Order" = RIMd,
                  tabledata Suffix = RIMD;
}
