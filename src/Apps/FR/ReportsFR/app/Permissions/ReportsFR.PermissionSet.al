// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;

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
                  report "Vendor Trial Balance" = X;
}