// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

tableextension 99001507 "Subc. Vendor" extends Vendor
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001515; "Subcontr. Location Code"; Code[10])
        {
            Caption = 'Subcontracting Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(99001516; "Linked to Work Center"; Boolean)
        {
            CalcFormula = exist("Work Center" where("Subcontractor No." = field("No.")));
            Caption = 'Linked to Work Center';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99001517; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center" where("Subcontractor No." = field("No."));
        }
    }
}