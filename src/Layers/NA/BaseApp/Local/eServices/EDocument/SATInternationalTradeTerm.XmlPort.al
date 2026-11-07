// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27045 "SAT International Trade Term"
{

    schema
    {
        textelement("data-set-Incoterms")
        {
            tableelement("SAT International Trade Term"; "SAT International Trade Term")
            {
                XmlName = 'c_Incoterm';
                fieldelement(Code; "SAT International Trade Term".Code)
                {
                }
                fieldelement(Descripcion; "SAT International Trade Term".Description)
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

