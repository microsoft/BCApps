// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.DataAdministration;

permissionsetextension 7100 "Exp. Activity Reten. View" extends "Retention Pol. View"
{
    Permissions = codeunit "Expense Activity Retention" = X;
}
