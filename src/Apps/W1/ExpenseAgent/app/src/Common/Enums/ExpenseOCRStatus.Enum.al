// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6909 "Expense OCR Status"
{
    Access = Internal;
    Caption = 'OCR Status';

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Sent)
    {
        Caption = 'Sent';
    }
    value(2; Processed)
    {
        Caption = 'Processed';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
}