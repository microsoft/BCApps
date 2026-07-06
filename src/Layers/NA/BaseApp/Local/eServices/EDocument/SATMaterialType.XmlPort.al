// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27039 "SAT Material Type"
{

    schema
    {
        textelement("data-set-MaterialTypes")
        {
            tableelement("SAT Material Type"; "SAT Material Type")
            {
                XmlName = 'MaterialType';
                fieldelement(Code; "SAT Material Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Material Type".Description)
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

