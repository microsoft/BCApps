// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.ProductionBOM;

pageextension 99001514 "Subc. ProdBOMVersionLines" extends "Production BOM Version Lines"
{
    layout
    {
        addlast(Control1)
        {
            field("Subcontracting Type"; Rec."Subcontracting Type")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Production BOM Line.';
            }
        }
    }
}