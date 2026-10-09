// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

page 3356 "SAT Transport Types MX"
{
    Caption = 'SAT Transport Types';
    PageType = List;
    SourceTable = "SAT Transport Type MX";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SAT catalog code for the transport mode (c_CveTransporte). Used as ViaEntradaSalida in the Carta Porte XML for international shipments.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the transport mode.';
                }
            }
        }
    }
}
