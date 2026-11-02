// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

enum 5869 "Derogatory Posting Role"
{
    Access = Internal;
    Extensible = false;

    value(0; Source)
    {
        Caption = 'Source';
    }
    value(1; "Generated Mirror")
    {
        Caption = 'Generated Mirror';
    }
    value(2; Reversal)
    {
        Caption = 'Reversal';
    }
    value(3; Internal)
    {
        Caption = 'Internal';
    }
}
