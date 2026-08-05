// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.ProductionBOM;

#pragma warning disable AS0072, AS0136
pageextension 20510 "Subc. Prod BOM Lines" extends "Production BOM Lines"
{
    layout
    {
        addlast(Control1)
        {
            field("Component Supply Method"; Rec."Component Supply Method")
            {
                ApplicationArea = Subcontracting;
            }
        }
    }
}
#pragma warning restore AS0072, AS0136
