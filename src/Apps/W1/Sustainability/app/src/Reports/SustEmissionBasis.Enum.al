// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sustainability.Reports;

enum 6233 "Sust. Emission Basis"
{
    Extensible = true;

    value(0; Average)
    {
        Caption = 'Average';
    }
    value(1; "Details by Item Tracking")
    {
        Caption = 'Details by Item Tracking';
    }
}
