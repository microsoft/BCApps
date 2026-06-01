// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Service.History;

reportextension 6172 "PostedServiceCrMemoWithQR" extends "Service - Credit Memo"
{
    dataset
    {
        add("Service Cr.Memo Header")
        {
            column(QR_Code_Image; "QR Code Image")
            {
            }
            column(QR_Code_Image_Lbl; FieldCaption("QR Code Image"))
            {
            }
        }
    }

    rendering
    {
        layout("ServiceCreditMemoWithQR.rdlc")
        {
            Type = RDLC;
            LayoutFile = './.resources/Template/ServiceCreditMemoWithQR.rdlc';
            Caption = 'Service Credit Memo - E-Document (RDLC)';
            Summary = 'The Service Credit Memo - E-Document (RDLC) provides the layout including E-Document QR code support.';
        }
    }
}