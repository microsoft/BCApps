// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

enum 259 "VAT Reporting Date Usage"
{
    Extensible = false;

    value(0; Enabled)
    {
        Caption = 'Enabled';
    }
    value(1; "Enabled (Prevent modification)")
    {
        Caption = 'Enabled (Prevent modification)';
    }
    value(2; Disabled)
    {
        Caption = 'Disabled';
    }
}
