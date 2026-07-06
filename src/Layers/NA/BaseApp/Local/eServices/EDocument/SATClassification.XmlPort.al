// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27010 "SAT Classification"
{
    Caption = 'SAT Classification';

    schema
    {
        textelement("data-set-ClaveProdServ")
        {
            tableelement("SAT Classification"; "SAT Classification")
            {
                XmlName = 'c_ClaveProdServs';
                fieldelement(c_ClaveProdServ; "SAT Classification"."SAT Classification")
                {
                }
                fieldelement(Descripcion; "SAT Classification".Description)
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

