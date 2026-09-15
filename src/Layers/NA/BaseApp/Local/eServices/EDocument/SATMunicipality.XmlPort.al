// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27027 "SAT Municipality"
{

    schema
    {
        textelement("data-set-c_Municipio")
        {
            tableelement("SAT Municipality"; "SAT Municipality")
            {
                XmlName = 'Municipio';
                fieldelement(Code; "SAT Municipality".Code)
                {
                }
                fieldelement(State; "SAT Municipality".State)
                {
                }
                fieldelement(Descripcion; "SAT Municipality".Description)
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

