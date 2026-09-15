// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27012 "SAT Use Code"
{
    Caption = 'SAT Use Code';

    schema
    {
        textelement("data-set-UsoCFDI")
        {
            tableelement("SAT Use Code"; "SAT Use Code")
            {
                XmlName = 'c_UsoCFDIs';
                fieldelement(c_UsoCFDI; "SAT Use Code"."SAT Use Code")
                {
                }
                fieldelement(Descripcion; "SAT Use Code".Description)
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

