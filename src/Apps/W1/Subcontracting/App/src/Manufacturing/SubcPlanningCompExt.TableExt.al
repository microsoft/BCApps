// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Warehouse.Structure;

tableextension 99001503 "Subc. Planning Comp Ext." extends "Planning Component"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001524; "Subcontracting Type"; Enum "Subcontracting Type")
        {
            Caption = 'Subcontracting Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Planning Component.';
            trigger OnValidate()
            var
                SubcontractingManagement: Codeunit "Subcontracting Management";
            begin
                SubcontractingManagement.UpdateSubcontractingTypeForPlanningComponent(Rec);
            end;
        }
        field(99001525; "Orig. Location Code"; Code[10])
        {
            Caption = 'Original Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(99001526; "Orig. Bin Code"; Code[20])
        {
            Caption = 'Original Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin;
        }
    }
}