// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27003 "CFDI Cancellation Reason"
{

    schema
    {
        textelement("data-set-CancellationReason")
        {
            tableelement("CFDI Cancellation Reason"; "CFDI Cancellation Reason")
            {
                XmlName = 'Motivo';
                fieldelement(Code; "CFDI Cancellation Reason".Code)
                {
                }
                fieldelement(Descripcion; "CFDI Cancellation Reason".Description)
                {
                }
                fieldelement(SubstitutionRequired; "CFDI Cancellation Reason"."Substitution Number Required")
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

