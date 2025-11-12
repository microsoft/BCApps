// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6062 "Service Contract Groups"
{
    ApplicationArea = Service;
    Caption = 'Service Contract Groups';
    PageType = List;
    SourceTable = "Contract Group";
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
                    ToolTip = 'Specifies a code for the contract group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the contract group.';
                }
                field("Disc. on Contr. Orders Only"; Rec."Disc. on Contr. Orders Only")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that contract/service discounts only apply to service lines linked to service orders created for the service contracts in the contract group.';
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

