// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Check;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;
using System.Environment.Configuration;
using System.Reflection;

permissionset 10825 "Reports FR"
{
    Access = Internal;
    Assignable = false;

    Permissions = report "Bank Acc. Det. Trial Balance" = X,
                  report "Bank Acc. Trial Balance" = X,
                  report "Cust. Detail Trial Balance" = X,
                  report "Customer Trial Balance" = X,
                  report "G/L Detail Trial Balance FR" = X,
                  report "G/L Trial Balance FR" = X,
                  report "Vendor Detail Trial Balance" = X,
                  report "Vendor Trial Balance" = X,
                  report Check = X,
                  codeunit "Check Amount Wording FR" = X,
                  codeunit "Report Layouts FR" = X,
                  codeunit "Install Reports FR" = X,
#if not CLEAN30
#pragma warning disable AL0432
                  codeunit "Reports FR" = X,
                  codeunit "Feature - Reports FR" = X,
#pragma warning restore AL0432
                  tabledata "Feature Data Update Status" = m,
#endif
                  tabledata "Report Layout List" = R,
                  tabledata "Report Layout Selection" = rim,
                  tabledata "Tenant Report Layout Selection" = rim;
}