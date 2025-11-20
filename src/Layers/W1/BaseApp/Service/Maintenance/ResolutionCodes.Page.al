// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

page 5928 "Resolution Codes"
{
    ApplicationArea = Service;
    Caption = 'Resolution Codes';
    PageType = List;
    SourceTable = "Resolution Code";
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
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the resolution.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the resolution code.';
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
        area(processing)
        {
            action("Import IRIS to Resolution Code")
            {
                ApplicationArea = Service;
                Caption = 'Import IRIS to Resolution Code';
                Image = Import;
                RunObject = XMLport "Import IRIS to Resol. Codes";
                ToolTip = 'Import the International Repair Coding System to define resolution codes for service items.';
            }
        }
    }
}

