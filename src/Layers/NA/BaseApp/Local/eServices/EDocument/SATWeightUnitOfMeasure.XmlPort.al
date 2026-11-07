// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27019 "SAT Weight Unit Of Measure"
{

    schema
    {
        textelement("data-set-PesoUnidados")
        {
            tableelement("SAT Weight Unit of Measure"; "SAT Weight Unit of Measure")
            {
                XmlName = 'PesoUnidad';
                fieldelement(Code; "SAT Weight Unit of Measure".Code)
                {
                }
                fieldelement(Name; "SAT Weight Unit of Measure".Name)
                {
                }
                fieldelement(Descripcion; "SAT Weight Unit of Measure".Description)
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

