// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

page 6021 "Resource Service Zones"
{
    ApplicationArea = Service;
    Caption = 'Resource Service Zones';
    PageType = List;
    SourceTable = "Resource Service Zone";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the title of the resource located in the service zone.';
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service zone where the resource will be located. A resource can be located in more than one zone at a time.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date when the resource is located in the service zone.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the resource''s assignment to the service zone.';
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

