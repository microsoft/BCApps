// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Warehouse.Journal;

page 7373 "Bin Creation Wksh. Name List"
{
    Caption = 'Bin Creation Wksh. Name List';
    DataCaptionExpression = DataCaption();
    DelayedInsert = true;
    Editable = false;
    PageType = List;
    SourceTable = "Bin Creation Wksh. Name";

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
                    ToolTip = 'Specifies a name for the worksheet.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description for the worksheet.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for which the worksheet should be used.';
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
                    BinCreateLine.TemplateSelectionFromBatch(Rec);
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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then begin
            BinCreateName := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowed(Rec."Location Code") then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := BinCreateName;
                    if Rec.Find(Which) then
                        while true do begin
                            if WMSManagement.LocationIsAllowed(Rec."Location Code") then
                                exit(true);
                            if Rec.Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        BinCreateName := Rec;
        repeat
            NextSteps := Rec.Next(Steps / Abs(Steps));
            if WMSManagement.LocationIsAllowed(Rec."Location Code") then begin
                RealSteps := RealSteps + NextSteps;
                BinCreateName := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := BinCreateName;
        Rec.Find();
        exit(RealSteps);
    end;

    trigger OnOpenPage()
    begin
        BinCreateLine.OpenWkshBatch(Rec);
    end;

    var
        BinCreateLine: Record "Bin Creation Worksheet Line";
        BinCreateName: Record "Bin Creation Wksh. Name";
        WMSManagement: Codeunit "WMS Management";

    local procedure DataCaption(): Text[250]
    var
        BinCreateTemplate: Record "Bin Creation Wksh. Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Worksheet Template Name") <> '' then
                if Rec.GetRangeMin("Worksheet Template Name") = Rec.GetRangeMax("Worksheet Template Name") then
                    if BinCreateTemplate.Get(Rec.GetRangeMin("Worksheet Template Name")) then
                        exit(BinCreateTemplate.Name + ' ' + BinCreateTemplate.Description);
    end;
}

