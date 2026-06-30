// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

pageextension 11392 "Post Codes NL" extends "Post Codes"
{
    actions
    {
        addlast(processing)
        {
            group("&Post Code")
            {
                Caption = '&Post Code';
                Image = ZoneCode;
                action("&Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Ranges';
                    Image = Ranges;
                    RunObject = Page "Post Code Ranges";
                    RunPageLink = "Post Code" = field(Code),
                                    City = field(City);
                    RunPageView = sorting("Post Code", City, Type, "From No.");
                    ToolTip = 'View or edit street names and cities by post codes. When you enter the post code and house number in an address field the program assists you in filling in the corresponding street name and city. If the house number does not fit into a range by the given post code, the Post Code Range window appears with a list of all the street names and cities by the given post code for you to select from.';
                }
            }
        }
    }
}

