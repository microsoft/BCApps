// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;

pageextension 4413 "SOA Contact Card Ext" extends "Contact Card"
{
    layout
    {
        addafter("E-Mail")
        {
            field("SOA E-Mail 2"; Rec."E-Mail 2")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Email 2';
                ToolTip = 'Specifies an alternate email address for the contact.';
            }
        }
    }
}
