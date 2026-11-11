// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Intercompany;

/// <summary>
/// Extends Business Manager Role Center with Intercompany Activities part.
/// </summary>
pageextension 8512 ICBusinessManagerRC extends "Business Manager Role Center"
{
    layout
    {
        addafter(ApprovalsActivities)
        {
            part("Intercompany Activities"; "Intercompany Activities")
            {
                ApplicationArea = Intercompany;
            }
        }
    }
}
