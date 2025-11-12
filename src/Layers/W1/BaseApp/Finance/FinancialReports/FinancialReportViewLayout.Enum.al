// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 5000 "Financial Report View Layout"
{
    Extensible = true;

    value(0; "Show None")
    {
        Caption = 'Show None';
    }
    value(1; "Show Filters Only")
    {
        Caption = 'Show Filters Only';
    }
    value(2; "Show All")
    {
        Caption = 'Show All';
    }
}
