// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27028 "SAT Locality"
{

    schema
    {
        textelement("data-set-c_Localidad")
        {
            tableelement("SAT Locality"; "SAT Locality")
            {
                XmlName = 'Localidad';
                fieldelement(Code; "SAT Locality".Code)
                {
                }
                fieldelement(State; "SAT Locality".State)
                {
                }
                fieldelement(Descripcion; "SAT Locality".Description)
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

