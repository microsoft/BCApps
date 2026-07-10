// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

xmlport 27038 "SAT Transfer Reason"
{

    schema
    {
        textelement("data-set-TransferReasons")
        {
            tableelement("SAT Transfer Reason"; "SAT Transfer Reason")
            {
                XmlName = 'TransferReason';
                fieldelement(Code; "SAT Transfer Reason".Code)
                {
                }
                fieldelement(Descripcion; "SAT Transfer Reason".Description)
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

