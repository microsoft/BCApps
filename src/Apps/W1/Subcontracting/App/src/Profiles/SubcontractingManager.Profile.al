// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.RoleCenters;
profile "Subcontracting Manager"
{
    Caption = 'Subcontracting Manager';
    Customizations = "Subc. ProdOrderRouting", "Subc. ProdOrderComponents", "Subc. RoutingLines", "Subc. ReleasedProdOrderLines";
    ProfileDescription = 'Functionality for managers who coordinate external work in production, e.g. tracking of subcontracting purchase orders and transfers from production.';
    RoleCenter = "Production Planner Role Center";
}