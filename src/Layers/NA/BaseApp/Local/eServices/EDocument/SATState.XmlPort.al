// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27026 "SAT State"
{

    schema
    {
        textelement("data-set-c_Estados")
        {
            tableelement("SAT State"; "SAT State")
            {
                XmlName = 'Estado';
                fieldelement(Code; "SAT State".Code)
                {
                }
                fieldelement(Descripcion; "SAT State".Description)
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

