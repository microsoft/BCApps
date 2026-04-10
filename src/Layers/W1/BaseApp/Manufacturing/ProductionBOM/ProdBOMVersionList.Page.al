// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

page 99000800 "Prod. BOM Version List"
{
    Caption = 'Prod. BOM Version List';
    CardPageID = "Production BOM Version";
    DataCaptionFields = "Production BOM No.", "Version Code", Description;
    Editable = false;
    PageType = List;
    SourceTable = "Production BOM Version";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production BOM version.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        StartingDateOnAfterValidate();
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
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

    local procedure StartingDateOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

