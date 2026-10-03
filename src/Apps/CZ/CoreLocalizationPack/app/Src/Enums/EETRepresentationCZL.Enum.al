// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

enum 11748 "EET Representation CZL"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Direct)
    {
        Caption = 'Direct';
    }
    value(2; Indirect)
    {
        Caption = 'Indirect';
    }
}