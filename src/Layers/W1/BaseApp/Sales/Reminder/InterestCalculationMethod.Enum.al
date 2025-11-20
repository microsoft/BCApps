// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

enum 5 "Interest Calculation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Average Daily Balance") { Caption = 'Average Daily Balance'; }
    value(1; "Balance Due") { Caption = 'Balance Due'; }
}
