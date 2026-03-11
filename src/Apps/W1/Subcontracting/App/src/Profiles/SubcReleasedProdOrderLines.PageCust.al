// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
pagecustomization "Subc. ReleasedProdOrderLines" customizes "Released Prod. Order Lines"
{
    layout
    {
        moveafter("Finished Quantity"; "Routing No.")
        modify("Routing No.")
        {
            Visible = true;
        }
        moveafter("Routing No."; "Production BOM No.")
        modify("Production BOM No.")
        {
            Visible = true;
        }
    }
}