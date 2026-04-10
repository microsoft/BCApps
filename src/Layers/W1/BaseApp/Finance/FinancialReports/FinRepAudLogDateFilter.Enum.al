// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 8391 "Fin. Rep. Aud. Log Date Filter"
{
    value(0; Blank)
    {
        Caption = ' ';
    }
    value(1; Last30Days)
    {
        Caption = 'Last 30 Days';
    }
    value(2; YearToDate)
    {
        Caption = 'Year to Date';
    }
}