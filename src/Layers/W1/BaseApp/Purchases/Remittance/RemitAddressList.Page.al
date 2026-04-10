// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Remittance;

page 2369 "Remit Address List"
{
    Caption = 'Remit Address List';
    CardPageID = "Remit Address";
    DataCaptionFields = "Code";
    Editable = false;
    PageType = List;
    SourceTable = "Remit Address";
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use as default address';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Location")
            {
                Caption = 'Location';
                Image = Addresses;
                separator(Action001)
                {
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the location on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
            }
        }
    }
}

