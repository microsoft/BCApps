// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001501 "Transfer Source Type"
{
    Extensible = true;
    value(0; Empty)
    {
        Caption = ' ', Locked = true;
    }
    value(1; Subcontracting)
    {
        Caption = 'Subcontracting';
    }
}