// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.ProductionBOM;

pageextension 99001510 "Subc. Prod BOM Lines" extends "Production BOM Lines"
{
    layout
    {
        addlast(Control1)
        {
            field("Subcontracting Type"; Rec."Subcontracting Type")
            {
                ApplicationArea = Manufacturing;
            }
        }
    }
}