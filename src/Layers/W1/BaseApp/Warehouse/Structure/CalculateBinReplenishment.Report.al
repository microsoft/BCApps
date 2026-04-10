// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Worksheet;

report 7300 "Calculate Bin Replenishment"
{
    Caption = 'Calculate Bin Replenishment';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bin Content"; "Bin Content")
        {
            DataItemTableView = sorting("Location Code", "Item No.", "Variant Code", "Warehouse Class Code", Fixed, "Bin Ranking") order(descending) where(Fixed = filter(true));
            RequestFilterFields = "Bin Code", "Item No.";

            trigger OnAfterGetRecord()
            begin
                Replenishmt.ReplenishBin("Bin Content", AllowBreakbulk);
            end;

            trigger OnPostDataItem()
            begin
                if not Replenishmt.InsertWhseWkshLine() then
                    if not HideDialog then
                        Message(Text000);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Location Code", LocationCode);
                Replenishmt.SetWhseWorksheet(
                  WhseWkshTemplateName, WhseWkshName, LocationCode, DoNotFillQtytoHandle);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(WorksheetTemplateName; WhseWkshTemplateName)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Worksheet Template Name';
                        TableRelation = "Whse. Worksheet Template";
                        ToolTip = 'Specifies the name of the worksheet template that applies to the movement lines.';

                        trigger OnValidate()
                        begin
                            if WhseWkshTemplateName = '' then
                                WhseWkshName := '';
                        end;
                    }
                    field(WorksheetName; WhseWkshName)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Worksheet Name';
                        ToolTip = 'Specifies the name of the worksheet the movement lines will belong to.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            WhseWorksheetName.SetRange("Worksheet Template Name", WhseWkshTemplateName);
                            WhseWorksheetName.SetRange("Location Code", LocationCode);
                            if PAGE.RunModal(0, WhseWorksheetName) = ACTION::LookupOK then
                                WhseWkshName := WhseWorksheetName.Name;
                        end;

                        trigger OnValidate()
                        begin
                            WhseWorksheetName.Get(WhseWkshTemplateName, WhseWkshName, LocationCode);
                        end;
                    }
                    field(LocCode; LocationCode)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Location Code';
                        TableRelation = Location;
                        ToolTip = 'Specifies the location at which bin replenishment will be calculated.';
                    }
                    field(AllowBreakbulk; AllowBreakbulk)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Allow Breakbulk';
                        ToolTip = 'Specifies that the bin will be replenished from bin content that is stored in another unit of measure if the item is not found in the original unit of measure.';
                    }
                    field(DoNotFillQtytoHandle; DoNotFillQtytoHandle)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies that the Quantity to Handle field on each worksheet line must be filled manually. ';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Replenishmt: Codeunit Replenishment;
#pragma warning disable AA0074
        Text000: Label 'There is nothing to replenish.';
#pragma warning restore AA0074

    protected var
        WhseWkshTemplateName: Code[10];
        WhseWkshName: Code[10];
        AllowBreakbulk: Boolean;

        DoNotFillQtytoHandle: Boolean;
        HideDialog: Boolean;
        LocationCode: Code[10];

    procedure InitializeRequest(WhseWkshTemplateName2: Code[10]; WhseWkshName2: Code[10]; LocationCode2: Code[10]; AllowBreakbulk2: Boolean; HideDialog2: Boolean; DoNotFillQtytoHandle2: Boolean)
    begin
        WhseWkshTemplateName := WhseWkshTemplateName2;
        WhseWkshName := WhseWkshName2;
        LocationCode := LocationCode2;
        AllowBreakbulk := AllowBreakbulk2;
        HideDialog := HideDialog2;
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
    end;
}

