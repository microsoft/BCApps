// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

page 805 "Online Map Parameter FactBox"
{
    Caption = 'Online Map Parameter';
    Editable = false;
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field(Text001; Text001)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{1}';
            }
            field(Text002; Text002)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{2}';
            }
            field(Text003; Text003)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{3}';
            }
            field(Text004; Text004)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{4}';
            }
            field(Text005; Text005)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{5}';
            }
            field(Text006; Text006)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{6}';
            }
            field(Text007; Text007)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{7}';
            }
            field(Text008; Text008)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{8}';
            }
            field(Text009; Text009)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{9}';
            }
            field(LatitudeLbl; LatitudeLbl)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{10}';
            }
            field(LongitudeLbl; LongitudeLbl)
            {
                ApplicationArea = Basic, Suite;
                Caption = '{11}';
            }
        }
    }

    actions
    {
    }

    var
#pragma warning disable AA0074
        Text001: Label 'Street (Address1)';
        Text002: Label 'City';
        Text003: Label 'State (County)';
        Text004: Label 'Post Code/ZIP Code';
        Text005: Label 'Country/Region Code';
        Text006: Label 'Country/Region Name';
        Text007: Label 'Culture Information, e.g., en-us';
        Text008: Label 'Distance in (Miles/Kilometers)';
        Text009: Label 'Route (Quickest/Shortest)';
#pragma warning restore AA0074
        LatitudeLbl: Label 'GPS Latitude';
        LongitudeLbl: Label 'GPS Longitude';
}

