// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

enum 11748 "EET Message Log Level CZL"
{
    Extensible = true;

    value(0; Disabled)
    {
        Caption = 'Disabled';
    }
    value(1; Errors)
    {
        Caption = 'Errors';
    }
    value(2; ErrorsAndWarnings)
    {
        Caption = 'Errors and Warnings';
    }
    value(3; All)
    {
        Caption = 'All';
    }
}
