// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;

tableextension 20403 "Qlty. Entry Summary" extends "Entry Summary"
{
    fields
    {
        field(20400; "Qlty. Inspection Count"; Integer)
        {
            Caption = 'Quality Inspection Count';
            ToolTip = 'Specifies the count of available quality inspections for the item tracking combination.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Header" where("Source Lot No." = field("Lot No."),
                                                                "Source Serial No." = field("Serial No."),
                                                                "Source Package No." = field("Package No.")));
        }
    }
}
