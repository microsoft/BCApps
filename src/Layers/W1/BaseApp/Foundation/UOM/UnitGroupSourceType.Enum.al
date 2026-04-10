// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.UOM;

enum 5402 "Unit Group Source Type"
{
    Extensible = false;

    value(0; Item)
    {
        Caption = 'Item';
    }
    value(1; Resource)
    {
        Caption = 'Resource';
    }
}