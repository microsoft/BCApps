// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27021 "SAT Federal Motor Transport"
{

    schema
    {
        textelement("data-set-AutotransporteFederal")
        {
            tableelement("SAT Federal Motor Transport"; "SAT Federal Motor Transport")
            {
                XmlName = 'c_TipoAutotransporteFederal';
                fieldelement(Code; "SAT Federal Motor Transport".Code)
                {
                }
                fieldelement(Descripcion; "SAT Federal Motor Transport".Description)
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

