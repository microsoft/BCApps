// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;

tableextension 99001509 "Subc. Purchase Header" extends "Purchase Header"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001520; "Subc. Location Code"; Code[10])
        {
            Caption = 'Subcontracting Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies the code for the location where the subcontracted items are stored for pickup and delivery.';
        }
        field(99001521; "Subcontracting Order"; Boolean)
        {
            CalcFormula = exist("Purchase Line" where("Document Type" = const(Order),
                                                       "Document No." = field("No."),
                                                       "Prod. Order No." = filter(<> ''),
                                                       "Prod. Order Line No." = filter(<> 0)));
            Caption = 'Subcontracting Order';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the subcontracting orders that have been created.';
        }
    }
}