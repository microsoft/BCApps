// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.Contact;

pageextension 10812 "Contact Card" extends "Contact Card"
{
    layout
    {
        addafter("APE Code")
        {

            field("SIREN No. FR"; Rec."SIREN No. FR")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the SIREN No. for the contact.';
            }
        }
    }
}
