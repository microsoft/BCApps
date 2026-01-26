// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

page 12189 "Service Tariff Numbers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Service Tariff Numbers';
    PageType = List;
    SourceTable = "Service Tariff Number";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the service tariff.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a text description for the service tariff.';
                }
            }
        }
    }

    actions
    {
    }
}

