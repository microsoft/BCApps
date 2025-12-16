// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Availability;

using Microsoft.Inventory.Availability;
using Microsoft.QualityManagement.Document;

tableextension 20404 "Qlty. Avail. Info. Buffer" extends "Availability Info. Buffer"
{
    fields
    {
        field(20400; "Qlty. Inspection Count"; Integer)
        {
            Caption = 'Quality Inspection Count';
            ToolTip = 'Specifies the count of available quality inspections for the item tracking combination.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Header" where("Source Item No." = field("Item No."),
                                                                "Source Variant Code" = field("Variant Code Filter"),
                                                                "Source Lot No." = field("Lot No."),
                                                                "Source Serial No." = field("Serial No."),
                                                                "Source Package No." = field("Package No.")));
        }
        field(20401; "Qlty. Inspection for Lot Count"; Integer)
        {
            Caption = 'Quality Inspection Count';
            ToolTip = 'Specifies the count of available quality inspections for the lot number.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Header" where("Source Item No." = field("Item No."),
                                                                "Source Variant Code" = field("Variant Code Filter"),
                                                                "Source Lot No." = field("Lot No.")));
        }
    }
}
