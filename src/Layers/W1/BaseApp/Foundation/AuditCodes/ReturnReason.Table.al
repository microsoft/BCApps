#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

using Microsoft.Inventory.Location;

table 6635 "Return Reason"
{
    Caption = 'Return Reason';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Return Reason is moved to Business Foundation';
    ObsoleteState = Moved;
    ObsoleteTag = '25.0';
    MovedTo = 'f3552374-a1f2-4356-848e-196002525837';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(4; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Default Location Code", "Inventory Value Zero")
        {
        }
    }
}
#endif