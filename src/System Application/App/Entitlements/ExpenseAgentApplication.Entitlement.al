// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Apps;
using System.Email;
using System.Environment.Configuration;

entitlement "Expense Agent Application"
{
    Type = Application;
    Id = 'ee1eb5fd-719b-44f2-97d0-0efd34bc4148';

    ObjectEntitlements = "Application Objects - Exec",
                         "System Application - Basic",
                         "Exten. Mgt. - Admin",
                         "Email - Admin",
                         "Feature Key - Admin";
}
