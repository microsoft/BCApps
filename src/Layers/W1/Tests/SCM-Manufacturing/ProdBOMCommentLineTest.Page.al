// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.ProductionBOM;

page 137437 "Prod. BOM Comment Line Test"
{
    PageType = Card;
    SourceTable = "Production BOM Comment Line";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = All;
                }
                field("BOM Line No."; Rec."BOM Line No.")
                {
                    ApplicationArea = All;
                }
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
