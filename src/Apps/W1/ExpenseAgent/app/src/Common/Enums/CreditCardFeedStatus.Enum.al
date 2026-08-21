// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6901 "Credit Card Feed Status"
{
    Access = Internal;
    Caption = 'Credit Card Feed Status';

    value(0; Received)
    {
        Caption = 'Received';
    }
    value(1; Processed)
    {
        Caption = 'Processed';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
}