// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27047 "SAT Customs Regime"
{

    schema
    {
        textelement("data-set-CustomsRegimes")
        {
            tableelement("SAT Customs Regime"; "SAT Customs Regime")
            {
                XmlName = 'CustomsRegime';
                fieldelement(Code; "SAT Customs Regime".Code)
                {
                }
                fieldelement(Descripcion; "SAT Customs Regime".Description)
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
}

