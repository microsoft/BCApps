// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27011 "SAT Relationship Type"
{
    Caption = 'SAT Relationship Type';

    schema
    {
        textelement("data-set-c_TipoRelacion")
        {
            tableelement("SAT Relationship Type"; "SAT Relationship Type")
            {
                XmlName = 'c_TipoRelacions';
                fieldelement(c_TipoRelacion; "SAT Relationship Type"."SAT Relationship Type")
                {
                }
                fieldelement(Descripcion; "SAT Relationship Type".Description)
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

