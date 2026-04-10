// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Warehouse.Journal;

page 7346 "Worksheet Names List"
{
    Caption = 'Worksheet Names List';
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Worksheet Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
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
            action("Edit Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'Edit Worksheet';
                Image = OpenWorksheet;
                ShortCutKey = 'Return';
                ToolTip = 'Open the related worksheet.';

                trigger OnAction()
                begin
                    WhseWkshLine.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Worksheet_Promoted"; "Edit Worksheet")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Worksheet Template Name");
    end;

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        WhseWkshLine.OpenWhseWkshBatch(Rec);
        Rec.FilterGroup(2);
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(CopyStr(UserId, 1, 50)));
        Rec.FilterGroup(0);
    end;

    var
        WhseWkshLine: Record "Whse. Worksheet Line";
}

