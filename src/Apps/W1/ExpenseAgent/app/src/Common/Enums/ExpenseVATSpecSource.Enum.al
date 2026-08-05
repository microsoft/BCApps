// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Source / provenance of an "Expense VAT Specification" line.
/// </summary>
enum 6921 "Expense VAT Spec Source"
{
    Extensible = false;

    value(0; Agent)
    {
        Caption = 'Agent';
    }
    value(1; Manual)
    {
        Caption = 'Manual';
    }
    value(2; Override)
    {
        Caption = 'Override';
    }
}
