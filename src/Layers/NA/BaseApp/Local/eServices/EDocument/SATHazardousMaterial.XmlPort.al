// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27024 "SAT Hazardous Material"
{

    schema
    {
        textelement("data-set-MaterialPeligroso")
        {
            tableelement("SAT Hazardous Material"; "SAT Hazardous Material")
            {
                XmlName = 'c_MaterialsPeligroso';
                fieldelement(Code; "SAT Hazardous Material".Code)
                {
                }
                fieldelement(Descripcion; "SAT Hazardous Material".Description)
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

