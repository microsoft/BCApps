// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;
pagecustomization "Subc. RoutingLines" customizes "Routing Lines"
{
    layout
    {
        modify("Routing Link Code")
        {
            Visible = true;
        }
    }
}