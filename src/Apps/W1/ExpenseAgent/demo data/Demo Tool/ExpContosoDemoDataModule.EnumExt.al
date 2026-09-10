// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool;

enumextension 8201 "Exp. Contoso Demo Data Module" extends "Contoso Demo Data Module"
{
    value(8201; "Expense Agent")
    {
        Implementation = "Contoso Demo Data Module" = "Expense Agent Contoso Module";
    }
}