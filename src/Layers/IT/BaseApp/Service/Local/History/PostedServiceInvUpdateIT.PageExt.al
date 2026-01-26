// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12212 "Posted Service Inv. Update IT" extends "Posted Service Inv. - Update"
{
    layout
    {
        addafter(General)
        {
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Fattura Document Type"; Rec."Fattura Document Type")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the value to export into the TipoDocument XML node of the Fattura document.';
                }
            }
        }
    }
}