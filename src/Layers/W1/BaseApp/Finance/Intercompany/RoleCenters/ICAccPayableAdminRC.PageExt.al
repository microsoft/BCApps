// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Intercompany;

/// <summary>
/// Extends Acc. Payable Administrator RC with Intercompany Activities part.
/// </summary>
pageextension 8513 ICAccPayableAdminRC extends "Acc. Payable Administrator RC"
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
