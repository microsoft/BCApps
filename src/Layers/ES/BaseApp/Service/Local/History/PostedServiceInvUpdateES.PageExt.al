// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 10736 "Posted Service Inv. Update ES" extends "Posted Service Inv. - Update"
{
    layout
    {
        addafter("Posting Date")
        {
            field("Country/Region Code"; Rec."Country/Region Code")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies the country/region of the address.';
            }
        }
        addafter(Payment)
        {
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                }
            }
        }
    }

}
