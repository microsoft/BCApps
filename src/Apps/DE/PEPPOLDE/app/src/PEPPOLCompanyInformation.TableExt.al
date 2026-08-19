// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Peppol.DE;

using Microsoft.Foundation.Company;

tableextension 37400 "PEPPOL Company Information DE" extends "Company Information"
{
    fields
    {
        field(37400; "Use Reg. No. in E-Document"; Boolean)
        {
            Caption = 'Use Registration No. in Electronic Document';
            DataClassification = CustomerContent;
        }
    }
}