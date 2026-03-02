// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Integration.Shopify;

profile "Shpfy Tax Agent"
{
    Caption = 'Shopify Tax Agent (Copilot)', Locked = true;
    Description = 'Default role center for Shopify Tax Matching Agent';
    ProfileDescription = 'Functionality for the Shopify Tax Matching Agent to match tax jurisdictions on Shopify orders.';
    RoleCenter = "Shpfy Tax Agent RC";
}
