// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

page 310 "Tariff Numbers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tariff Numbers';
    PageType = List;
    SourceTable = "Tariff Number";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Supplementary Units"; Rec."Supplementary Units")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the customs and tax authorities require information about quantity and unit of measure for this item.';
                }
                field("Conversion Factor"; Rec."Conversion Factor")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the conversion factor for the tariff number.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the unit of measure for the tariff number.';
                }
                field("Weight Mandatory"; Rec."Weight Mandatory")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if the weight of the items with the current tariff number is to be included on the Intrastat declaration.';
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

