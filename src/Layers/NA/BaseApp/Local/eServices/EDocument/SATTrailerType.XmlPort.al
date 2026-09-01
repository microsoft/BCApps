// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27022 "SAT Trailer Type"
{

    schema
    {
        textelement("data-set-TipoDeRemolque")
        {
            tableelement("SAT Trailer Type"; "SAT Trailer Type")
            {
                XmlName = 'c_TipoRemolques';
                fieldelement(Code; "SAT Trailer Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Trailer Type".Description)
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

