// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

page 11407 "Post Code Ranges"
{
    Caption = 'Post Code Ranges';
    DataCaptionFields = "Post Code", City;
    Editable = false;
    PageType = List;
    SourceTable = "Post Code Range";

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code to which the address data is related.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city linked to the postal code in the postal code field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of house number range.';
                }
                field("From No."; Rec."From No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first house number of the range.';
                }
                field("To No."; Rec."To No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last house number of the range.';
                }
                field("Street Name"; Rec."Street Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the street of the postcode and house number range.';
                }
            }
        }
    }

    actions
    {
    }
}

