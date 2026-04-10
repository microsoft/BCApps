// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

page 5943 "Service Order Status Setup"
{
    ApplicationArea = Service;
    Caption = 'Service Order Status Setup';
    PageType = List;
    SourceTable = "Service Status Priority Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Order Status"; Rec."Service Order Status")
                {
                    ApplicationArea = Service;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
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

    trigger OnOpenPage()
    begin
        if CurrPage.LookupMode then
            CurrPage.Editable(false)
        else
            CurrPage.Editable(true);
    end;
}

