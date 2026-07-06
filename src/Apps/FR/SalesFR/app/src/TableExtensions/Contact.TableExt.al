// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.Contact;

tableextension 10805 Contact extends Contact
{
    fields
    {
        field(10806; "SIREN No. FR"; Code[9])
        {
            Caption = 'SIREN No.';
            DataClassification = CustomerContent;
        }
    }
}
