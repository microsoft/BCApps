// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

page 3355 "SAT ISTMO Regions MX"
{
    Caption = 'SAT ISTMO Regions';
    PageType = List;
    SourceTable = "SAT ISTMO Region MX";
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
                    ToolTip = 'Specifies the SAT catalog code for the ISTMO de Tehuantepec development zone pole (c_RegistroISTMO).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the ISTMO pole location.';
                }
            }
        }
    }
}
