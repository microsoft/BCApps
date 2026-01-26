// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Used in IT localization only. Base enum is kept here for backwards compatibility.
/// </summary>
enum 12145 "No. Series Type"
{
    Access = Public;
    Extensible = true;

    value(0; Normal)
    {
        Caption = 'Normal';
    }
    value(1; Sales)
    {
        Caption = 'Sales';
    }
    value(2; Purchase)
    {
        Caption = 'Purchase';
    }
}