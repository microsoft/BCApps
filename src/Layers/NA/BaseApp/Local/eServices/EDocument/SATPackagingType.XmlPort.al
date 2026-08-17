// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27025 "SAT Packaging Type"
{

    schema
    {
        textelement("data-set-TipoDeEmbalaje")
        {
            tableelement("SAT Packaging Type"; "SAT Packaging Type")
            {
                XmlName = 'c_TiposEmbalaje';
                fieldelement(Code; "SAT Packaging Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Packaging Type".Description)
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

