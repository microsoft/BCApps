// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 25 "Show Empty Amount Type"
{
    Extensible = true;

    value(0; Blank)
    {
        Caption = 'Blank';
    }
    value(1; Zero)
    {
        Caption = 'Zero';
    }
    value(2; Dash)
    {
        Caption = 'Dash';
    }
}
