// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7108 "Exp. Spend Req. Line Type"
{
    Extensible = true;

    value(0; "Category")
    {
        Caption = 'Category';
    }
    value(1; "Lump Sum")
    {
        Caption = 'Lump Sum';
    }
}