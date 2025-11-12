// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;

page 99000811 "Prod. BOM Where-Used"
{
    Caption = 'Prod. BOM Where-Used';
    DataCaptionExpression = SetCaption();
    PageType = Worksheet;
    SourceTable = "Where-Used Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CalculateDate; CalculateDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculation Date';
                    ToolTip = 'Specifies the date for which you want to show the where-used lines.';

                    trigger OnValidate()
                    begin
                        CalculateDateOnAfterValidate();
                    end;
                }
                field(ShowLevel; ShowLevel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Levels';
                    OptionCaption = 'Single,Multi';
                    ToolTip = 'Specifies the level of detail for the where-used lines.';

                    trigger OnValidate()
                    begin
                        ShowLevelOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the item that the base item or production BOM is assigned to.';
                }
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the production BOM that the item or production BOM component is assigned to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the item to which the item or production BOM component is assigned.';
                }
                field("Quantity Needed"; Rec."Quantity Needed")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the item or the production BOM component that is needed for the assigned item.';
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

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(WhereUsedMgt.FindRecord(Which, Rec));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(WhereUsedMgt.NextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    begin
        BuildForm();
    end;

    var
        ProdBOMHeader: Record "Production BOM Header";
        WhereUsedMgt: Codeunit "Where-Used Management";
        CalculateDate: Date;
        DescriptionIndent: Integer;

    protected var
        Item: Record Item;
        ShowLevel: Option Single,Multi;

    procedure SetProdBOM(NewProdBOMHeader: Record "Production BOM Header"; NewCalcDate: Date)
    begin
        ProdBOMHeader := NewProdBOMHeader;
        CalculateDate := NewCalcDate;
    end;

    procedure SetItem(NewItem: Record Item; NewCalcDate: Date)
    begin
        Item := NewItem;
        CalculateDate := NewCalcDate;
    end;

    procedure BuildForm()
    begin
        OnBeforeBuildForm(WhereUsedMgt, ShowLevel);
        if ProdBOMHeader."No." <> '' then
            WhereUsedMgt.WhereUsedFromProdBOM(ProdBOMHeader, CalculateDate, ShowLevel = ShowLevel::Multi)
        else
            WhereUsedMgt.WhereUsedFromItem(Item, CalculateDate, ShowLevel = ShowLevel::Multi);
        OnAfterBuildForm(WhereUsedMgt, ShowLevel, Item, ProdBOMHeader, CalculateDate);
    end;

    procedure SetCaption(): Text
    var
        IsHandled: Boolean;
        Result: Text;
    begin
        IsHandled := false;
        OnBeforeSetCaption(Item, ProdBOMHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ProdBOMHeader."No." <> '' then
            exit(ProdBOMHeader."No." + ' ' + ProdBOMHeader.Description);

        exit(Item."No." + ' ' + Item.Description);
    end;

    local procedure CalculateDateOnAfterValidate()
    begin
        BuildForm();
        CurrPage.Update(false);
    end;

    local procedure ShowLevelOnAfterValidate()
    begin
        BuildForm();
        CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec."Level Code" - 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildForm(var WhereUsedManagement: Codeunit "Where-Used Management"; ShowLevel: Option; Item: Record Item; ProductionBOMHeader: Record "Production BOM Header"; CalculateDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBuildForm(var WhereUsedManagement: Codeunit "Where-Used Management"; ShowLevel: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCaption(Item: Record Item; ProdBOM: Record "Production BOM Header"; var Result: Text; var IsHandled: Boolean)
    begin
    end;
}

