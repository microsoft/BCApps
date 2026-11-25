// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 10047 "IRS 1099 Statement Source"
{
    Extensible = false;

    value(0; "Document Line")
    {
        Caption = 'Document Line';
    }
    value(1; "Supplemental Line")
    {
        Caption = 'Supplemental Line';
    }
}
