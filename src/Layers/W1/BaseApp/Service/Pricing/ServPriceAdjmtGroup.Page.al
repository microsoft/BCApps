// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

page 6082 "Serv. Price Adjmt. Group"
{
    ApplicationArea = Service;
    Caption = 'Service Price Adjustment Groups';
    PageType = List;
    SourceTable = "Service Price Adjustment Group";
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
                    ToolTip = 'Specifies a code for the service price adjustment group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service price adjustment group.';
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
            action("&Details")
            {
                ApplicationArea = Service;
                Caption = '&Details';
                Image = View;
                RunObject = Page "Serv. Price Adjmt. Detail";
                RunPageLink = "Serv. Price Adjmt. Gr. Code" = field(Code);
                ToolTip = 'View details about the price.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Details_Promoted"; "&Details")
                {
                }
            }
        }
    }
}

