// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

/// <summary>
/// Indicates whether a spend request is required before posting expenses to a G/L account.
/// </summary>
enum 6843 "Spend Request Required"
{
    Extensible = true;
    Caption = 'Spend Request Required';

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Required)
    {
        Caption = 'Required';
    }
}
