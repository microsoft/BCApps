// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11306 "Representative Card"
{
    Caption = 'Representative Card';
    PageType = Card;
    SourceTable = Representative;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the representative.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the VAT declaration representative.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address that is associated with the VAT declaration representative.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/City';
                    ToolTip = 'Specifies the postal code that is associated with the VAT declaration representative.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city that is associated with the VAT declaration representative.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country or region code that is associated with the VAT declaration representative.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county that is associated with the VAT declaration representative.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address of the VAT declaration representative.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the VAT declaration representative.';
                }
                field("Issued by"; Rec."Issued by")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region that issued the VAT declaration representative.';
                }
                field("Identification Type"; Rec."Identification Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification type that is associated with the VAT declaration representative. Identification types include NVAT and TIN.';
                }
            }
        }
    }

    actions
    {
    }
}

