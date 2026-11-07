// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27017 "SAT Payment Term"
{
    Caption = 'SAT Payment Term';

    schema
    {
        textelement("data-set-MetodoPago")
        {
            tableelement("SAT Payment Term"; "SAT Payment Term")
            {
                XmlName = 'c_MetodoPagos';
                fieldelement(c_MetodoPago; "SAT Payment Term".Code)
                {
                }
                fieldelement(Descripcion; "SAT Payment Term".Description)
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

