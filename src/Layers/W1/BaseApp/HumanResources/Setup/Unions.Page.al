// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Setup;

page 5213 Unions
{
    ApplicationArea = BasicHR;
    Caption = 'Unions';
    PageType = List;
    SourceTable = Union;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a union code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the name of the union.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the union''s address.';
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the city of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the union''s telephone number.';
                }
                field("No. of Members Employed"; Rec."No. of Members Employed")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of members employed.';
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
    }
}

