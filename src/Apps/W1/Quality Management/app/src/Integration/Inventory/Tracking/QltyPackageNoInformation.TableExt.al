// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;

tableextension 20407 "Qlty. Package No. Information" extends "Package No. Information"
{
    fields
    {
        field(20400; "Qlty. Inspection Count"; Integer)
        {
            Caption = 'Quality Inspection Count';
            ToolTip = 'Specifies the count of available quality inspections for the package number.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Header" where("Source Item No." = field("Item No."),
                                                                "Source Variant Code" = field("Variant Code"),
                                                                "Source Package No." = field("Package No.")));
        }
    }
}
