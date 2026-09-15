// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27023 "SAT Permission Type"
{

    schema
    {
        textelement("data-set-TipoPermiso")
        {
            tableelement("SAT Permission Type"; "SAT Permission Type")
            {
                XmlName = 'c_TipoPermisos';
                fieldelement(Code; "SAT Permission Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Permission Type".Description)
                {
                }
                fieldelement(ClaveTransporte; "SAT Permission Type"."Transport Key")
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

