// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6925 "Expense Source"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Source';

    value(0; Manual)
    {
        Caption = 'Manual';
    }
    value(1; CorporateCard)
    {
        Caption = 'Corporate Card';
    }
}
