// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 10046 "IRS 1099 Supplemental Type"
{
    Extensible = false;

    value(0; Amount)
    {
        Caption = 'Amount';
    }
    value(1; "Occupation Codes")
    {
        Caption = 'Occupation Codes';
    }
}
