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
        field(99001524; "Component Supply Method"; Enum "Component Supply Method")
        {
            Caption = 'Component Supply Method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how components are supplied to the subcontractor for the planning component. Vendor-supplied - components are provided by the subcontractor. Consignment at Vendor - components are owned by your company but stored at the subcontractor location. Transfer to Vendor - components are sent to the subcontractor through a transfer order.';
            trigger OnValidate()
            var
                SubcontractingManagement: Codeunit "Subcontracting Management";
            begin
                SubcontractingManagement.UpdateComponentSupplyMethodForPlanningComponent(Rec);
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