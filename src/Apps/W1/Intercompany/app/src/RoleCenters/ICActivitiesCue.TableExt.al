// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;

/// <summary>
/// Extends Activities Cue with Intercompany-specific cue fields.
/// Adds IC Inbox and IC Outbox transaction counts for display in role center activity tiles.
/// </summary>
tableextension 8497 "IC Activities Cue" extends "Activities Cue"
{
    fields
    {
        field(28; "IC Inbox Transactions"; Integer)
        {
            MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
            CalcFormula = count("IC Inbox Transaction");
            Caption = 'IC Inbox Transactions';
            FieldClass = FlowField;
        }
        field(29; "IC Outbox Transactions"; Integer)
        {
            MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
            CalcFormula = count("IC Outbox Transaction");
            Caption = 'IC Outbox Transactions';
            FieldClass = FlowField;
        }
    }
}
