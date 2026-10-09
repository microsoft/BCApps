// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.Intercompany;

/// <summary>
/// Extends Order Processor Role Center with Intercompany Activities part.
/// </summary>
pageextension 8514 ICOrderProcessorRC extends "Order Processor Role Center"
{
    layout
    {
        addafter(Control1901851508)
        {
            part("Intercompany Activities"; "Intercompany Activities")
            {
                ApplicationArea = Intercompany;
            }
        }
    }
}
