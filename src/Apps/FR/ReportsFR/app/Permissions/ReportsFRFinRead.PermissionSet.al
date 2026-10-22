// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Bank.Reports;
using Microsoft.Finance.GeneralLedger.Reports;

permissionset 10827 "Reports FR Fin. Read"
{
    Assignable = true;
    Caption = 'French financial reports - read';

    Permissions = tabledata "FR Financial Schedule Name" = R,
                  tabledata "FR Financial Schedule Line" = R,
                  table "FR Financial Schedule Name" = X,
                  table "FR Financial Schedule Line" = X,
                  page "FR Financial Schedule Names" = X,
                  page "FR Financial Schedule" = X,
                  codeunit "FR Financial Schedule Mgt." = X,
                  codeunit "Substitute Report FR" = X,
                  report "FR Financial Schedule" = X,
                  report "G/L Account Statement FR" = X;
}
