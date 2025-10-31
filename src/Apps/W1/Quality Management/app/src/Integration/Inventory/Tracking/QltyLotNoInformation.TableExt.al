// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;

tableextension 20405 "Qlty. Lot No. Information" extends "Lot No. Information"
{
    fields
    {
        field(20400; "Qlty. Inspection Test Count"; Integer)
        {
            Caption = 'Quality Inspection Test Count';
            ToolTip = 'Specifies the count of available quality inspection tests for the lot number.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Test Header" where("Source Item No." = field("Item No."),
                                                                     "Source Variant Code" = field("Variant Code"),
                                                                     "Source Lot No." = field("Lot No.")));
        }
    }
}
