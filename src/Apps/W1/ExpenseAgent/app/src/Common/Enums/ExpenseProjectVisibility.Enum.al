// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6983 "Expense Project Visibility"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Project Visibility';

    value(0; "Assigned projects")
    {
        Caption = 'Assigned projects';
    }
    value(1; "All projects")
    {
        Caption = 'All projects';
    }
}
