// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

entitlement "EA - Azure AD Application API"
{
    Type = ApplicationScope;
    Id = 'API.ReadWrite.All';
    ObjectEntitlements = "Expense Mgmt. Edit";
}
