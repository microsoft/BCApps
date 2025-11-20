// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 333 "Account Schedule Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Net Amount")
    {
        Caption = 'Net Amount';
    }
    value(1; "Debit Amount")
    {
        Caption = 'Debit Amount';
    }
    value(2; "Credit Amount")
    {
        Caption = 'Credit Amount';
    }
}
