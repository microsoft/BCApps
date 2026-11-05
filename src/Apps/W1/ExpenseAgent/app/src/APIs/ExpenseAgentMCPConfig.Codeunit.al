#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
codeunit 6930 "Expense Agent MCP Config."
{
    ObsoleteReason = 'MCP is not used for Expense Agent';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    trigger OnRun()
    begin
    end;
}
#endif