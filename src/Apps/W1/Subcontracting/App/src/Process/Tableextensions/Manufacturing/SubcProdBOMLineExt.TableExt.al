// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.ProductionBOM;

tableextension 99001531 "Subc. Prod BOM Line Ext." extends "Production BOM Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001522; "Component Supply Method"; Enum "Component Supply Method")
        {
            Caption = 'Component Supply Method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how components are supplied to the subcontractor for the production BOM line.';
        }
    }
}