// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Address;

page 368 "Order Address"
{
    Caption = 'Order Address';
    DataCaptionExpression = Rec.Caption();
    PageType = Card;
    SourceTable = "Order Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the street address.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                group(CountyGroup)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; Rec.County)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number associated with the order address.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Address")
            {
                Caption = '&Address';
                Image = Addresses;
                separator(Action39)
                {
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
}

