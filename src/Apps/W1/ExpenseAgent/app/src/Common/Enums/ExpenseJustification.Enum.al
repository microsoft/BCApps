// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Specifies when a justification is required for an expense: never, always, or when rule conditions are not met.
/// </summary>
enum 6908 "Expense Justification"
{
    Caption = 'Justification Mandatory';

    value(0; " ")
    {
        Caption = 'None';
    }
    value(1; Always)
    {
        Caption = 'Always';
    }
    value(2; "Against Conditions")
    {
        Caption = 'Against Conditions';
    }
}