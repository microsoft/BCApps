// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 6637 ReturnReasonExt extends "Return Reason"
{
    fields
    {
        field(3; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(4; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
    }

    fieldgroups
    {
        addlast(DropDown; "Default Location Code", "Inventory Value Zero")
        {
        }
    }
}
