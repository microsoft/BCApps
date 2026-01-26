// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
pagecustomization "Subc. ProdOrderRouting" customizes "Prod. Order Routing"
{
    layout
    {
        modify("Flushing Method")
        {
            Visible = true;
        }
        moveafter("Flushing Method"; "Routing Link Code")
        modify("Routing Link Code")
        {
            Visible = true;
        }
        moveafter("Routing Link Code"; "Location Code")
        modify("Location Code")
        {
            Visible = true;
        }
    }
}