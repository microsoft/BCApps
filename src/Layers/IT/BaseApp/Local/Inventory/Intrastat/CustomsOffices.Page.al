// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

page 12119 "Customs Offices"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customs Offices';
    PageType = List;
    SourceTable = "Customs Office";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code that identifies the customs office. For example, use the code 014100 for the Foggia customs office.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the customs office.';
                }
            }
        }
    }

    actions
    {
    }
}

