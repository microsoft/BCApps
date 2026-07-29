// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Review;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;

permissionsetextension 1002 "LOCAL READ NL" extends "LOCAL READ"
{

    Permissions = tabledata "Audit File Buffer" = R,
                  tabledata "CBG Statement" = R,
                  tabledata "CBG Statement Line" = R,
                  tabledata "CBG Statement Line Add. Info." = R,
                  tabledata "Detail Line" = R,
                  tabledata "Elec. Tax Decl. Error Log" = R,
                  tabledata "Elec. Tax Decl. Response Msg." = R,
                  tabledata "Elec. Tax Decl. VAT Category" = R,
                  tabledata "Elec. Tax Declaration Header" = R,
                  tabledata "Elec. Tax Declaration Line" = R,
                  tabledata "Elec. Tax Declaration Setup" = R,
                  tabledata "Export Protocol" = R,
                  tabledata "Freely Transferable Maximum" = R,
                  tabledata "G/L Entry Application Buffer" = R,
                  tabledata "Import Protocol" = R,
                  tabledata "Payment History" = R,
                  tabledata "Payment History Export Buffer" = R,
                  tabledata "Payment History Line" = R,
                  tabledata "Post Code Range" = R,
                  tabledata "Post Code Update Log Entry" = R,
                  tabledata "Proposal Line" = R,
                  tabledata "Reconciliation Buffer" = R,
                  tabledata "Reporting ICP" = R,
                  tabledata "Transaction Mode" = R;
}
