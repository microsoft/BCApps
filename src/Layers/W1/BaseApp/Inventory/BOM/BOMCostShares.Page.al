// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Reports;

page 5872 "BOM Cost Shares"
{
    Caption = 'BOM Cost Shares';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "BOM Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            grid(Option)
            {
                Caption = 'Option';
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the items that are shown in the BOM Cost Shares window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Text := Item."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        UpdatePage();
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Lines';
                IndentationColumn = Rec.Indentation;
                ShowAsTree = true;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the item''s position in the BOM structure. Lower-level items are indented under their parents.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = IsParentExpr;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = IsParentExpr;
                    ToolTip = 'Specifies the item''s description.';
                }
                field(HasWarning; HasWarning)
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Warning';
                    Editable = false;
                    Style = Attention;
                    StyleExpr = HasWarning;
                    ToolTip = 'Specifies if the field can be chosen to open the BOM Warning Log window to see a description of the issue.';

                    trigger OnDrillDown()
                    begin
                        if HasWarning then
                            ShowWarnings();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant code that you entered in the Variant Filter field in the Item Availability by BOM Level window.';
                    Visible = false;
                }
                field("Qty. per Parent"; Rec."Qty. per Parent")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the parent.';
                }
                field("Qty. per Top Item"; Rec."Qty. per Top Item")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the top item.';
                }
                field("Qty. per BOM Line"; Rec."Qty. per BOM Line")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the item on the BOM line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("BOM Unit of Measure Code"; Rec."BOM Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the unit of measure of the BOM item. ';
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the item''s replenishment system.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                    Visible = false;
                }
                field("Scrap Qty. per Parent"; Rec."Scrap Qty. per Parent")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item are scrapped to output the top item quantity.';
                    Visible = false;
                }
                field("Scrap Qty. per Top Item"; Rec."Scrap Qty. per Top Item")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item are scrapped to output the parent item quantity.';
                    Visible = false;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the item''s overhead rate.';
                    Visible = false;
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s lot size. The value is copied from the Lot Size field on the item card.';
                    Visible = false;
                }
                field("Resource Usage Type"; Rec."Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how the cost of the resource on the assembly BOM is allocated during assembly.';
                    Visible = false;
                }
                field("Rolled-up Material Cost"; Rec."Rolled-up Material Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the material cost of all items at all levels of the parent item''s BOM, added to the material cost of the item itself.';
                }
                field("Rolled-up Mat. Non-Invt. Cost"; Rec."Rolled-up Mat. Non-Invt. Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the non inventory material cost of all items at all levels of the parent item''s BOM, added to the non inventory material cost of the item itself.';
                }
                field("Rolled-up Capacity Cost"; Rec."Rolled-up Capacity Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the capacity costs related to the item''s parent item and other items in the parent item''s BOM.';
                }
                field("Rolled-up Subcontracted Cost"; Rec."Rolled-up Subcontracted Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level cost of outsourcing operations to a subcontractor.';
                }
                field("Rolled-up Mfg. Ovhd Cost"; Rec."Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item''s overhead capacity cost rolled up from underlying item levels.';
                }
                field("Rolled-up Capacity Ovhd. Cost"; Rec."Rolled-up Capacity Ovhd. Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the rolled-up manufacturing overhead cost of the item.';
                }
                field("Rolled-up Scrap Cost"; Rec."Rolled-up Scrap Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of all component material that will eventually be scrapped to produce the parent item.';
                }
                field("Single-Level Material Cost"; Rec."Single-Level Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the total material cost of all components on the parent item''s BOM.';
                    Visible = false;
                }
                field("Single-Lvl Mat. Non-Invt. Cost"; Rec."Single-Lvl Mat. Non-Invt. Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the total non inventory material cost of all components on the parent item''s BOM.';
                    Visible = false;
                }
                field("Single-Level Capacity Cost"; Rec."Single-Level Capacity Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the capacity costs related to the item''s parent item only.';
                    Visible = false;
                }
                field("Single-Level Subcontrd. Cost"; Rec."Single-Level Subcontrd. Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the single-level cost of outsourcing operations to a subcontractor.';
                    Visible = false;
                }
                field("Single-Level Cap. Ovhd Cost"; Rec."Single-Level Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the single-level capacity overhead cost.';
                    Visible = false;
                }
                field("Single-Level Mfg. Ovhd Cost"; Rec."Single-Level Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the single-level manufacturing overhead cost.';
                    Visible = false;
                }
                field("Single-Level Scrap Cost"; Rec."Single-Level Scrap Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of material at this BOM level that will eventually be scrapped in order to produce the parent item.';
                    Visible = false;
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the sum of all cost at this BOM level.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Show Warnings")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Warnings';
                Image = ErrorLog;
                ToolTip = 'View details about bottlenecks.';

                trigger OnAction()
                begin
                    ShowWarningsForAllLines();
                end;
            }
        }
        area(reporting)
        {
            action("BOM Cost Share Distribution")
            {
                ApplicationArea = Assembly;
                Caption = 'BOM Cost Share Distribution';
                Image = "Report";
                ToolTip = 'Get a graphical overview of how an assembled or produced item''s cost is distributed through its BOM. The first chart shows the total unit cost of the parent item''s components and labor resources broken down in up to five different cost shares. The pie chart labeled By Material/Labor shows the proportional distribution between the parent item''s material and labor costs, as well as its own manufacturing overhead. The material cost share includes the item''s material costs. The labor cost share includes capacity, capacity overhead and subcontracted costs. The pie chart labeled By Direct/Indirect shows the proportional distribution between the parent item''s direct and indirect costs. The direct cost share includes the item''s material, capacity, and subcontracted costs.';

                trigger OnAction()
                begin
                    ShowBOMCostShareDistribution();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Warnings_Promoted"; "Show Warnings")
                {
                }
                actionref("BOM Cost Share Distribution_Promoted"; "BOM Cost Share Distribution")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DummyBOMWarningLog: Record "BOM Warning Log";
    begin
        IsParentExpr := not Rec."Is Leaf";

        HasWarning := not Rec.IsLineOk(false, DummyBOMWarningLog);
    end;

    trigger OnOpenPage()
    begin
        UpdatePage();
    end;

    var
        Item: Record Item;
        SourceRecordVar: Variant;
        IsParentExpr: Boolean;
        HasWarning: Boolean;

#pragma warning disable AA0074
        Text000: Label 'None of the items in the filter have a BOM.';
        Text001: Label 'There are no warnings.';
#pragma warning restore AA0074

    protected var
        ItemFilter: Code[250];
        ShowBy: Enum "BOM Structure Show By";

    procedure InitItem(var NewItem: Record Item)
    var
        ConstantTxt: Label '''%1''', Locked = true;
    begin
        Item.Copy(NewItem);
        ItemFilter := '';
        if Item."No." <> '' then
            ItemFilter := StrSubstNo(ConstantTxt, Item."No.");
        ShowBy := ShowBy::Item;
    end;

    procedure InitSource(NewSourceRecordVar: Variant; NewShowBy: Enum "BOM Structure Show By")
    begin
        SourceRecordVar := NewSourceRecordVar;
        ShowBy := NewShowBy;
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure InitSource()', '27.0')]
    procedure InitAsmOrder(NewAsmHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        SourceRecordVar := NewAsmHeader;
        ShowBy := ShowBy::Assembly;
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by procedure InitSource()', '27.0')]
    procedure InitProdOrder(NewProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        SourceRecordVar := NewProdOrderLine;
        ShowBy := ShowBy::Production;
    end;
#endif

    local procedure UpdatePage()
    var
#if not CLEAN27
        AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header";
        ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line";
#endif   
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        HasBOM: Boolean;
        IsHandled: Boolean;
#if not CLEAN27
        ShowByOption: Option;
#endif
    begin
        IsHandled := false;
#if not CLEAN27
        ShowByOption := ShowBy.AsInteger();
        case ShowBy of
            ShowBy::Assembly:
                AssemblyHeader := SourceRecordVar;
            ShowBy::Production:
                ProdOrderLine := SourceRecordVar;
        end;
        OnBeforeRefreshPage(Rec, Item, AssemblyHeader, ProdOrderLine, ShowByOption, ItemFilter, IsHandled);
        ShowBy := Enum::"BOM Structure Show By".FromInteger(ShowByOption);
#endif
        OnBeforeUpdatePage(Rec, Item, SourceRecordVar, ShowBy, ItemFilter, IsHandled);
        if IsHandled then
            exit;

        Item.SetFilter("No.", ItemFilter);
        Item.SetRange("Date Filter", 0D, WorkDate());
        CalcBOMTree.SetItemFilter(Item);

        case ShowBy of
            ShowBy::Item:
                begin
                    Item.FindSet();
                    repeat
                        HasBOM := Item.HasBOM() or Item.HasRoutingNo();
                    until HasBOM or (Item.Next() = 0);

                    if not HasBOM then
                        Error(Text000);
                    CalcBOMTree.GenerateTreeForManyItems(Item, Rec, "BOM Tree Type"::Cost);
                end;
            else
                CalcBOMTree.GenerateTreeForSource(SourceRecordVar, Rec, "BOM Tree Type"::Cost, ShowBy, WorkDate());
        end;

        CurrPage.Update(false);
    end;

    local procedure ShowBOMCostShareDistribution()
    var
        Item2: Record Item;
    begin
        Rec.TestField(Type, Rec.Type::Item);

        Item2.Get(Rec."No.");
        Item2.SetRange("No.", Rec."No.");
        Item2.SetFilter("Variant Filter", Rec."Variant Code");
        if ShowBy <> ShowBy::Item then
            Item2.SetFilter("Location Filter", Rec."Location Code");

        REPORT.Run(REPORT::"BOM Cost Share Distribution", true, true, Item2);
    end;

    local procedure ShowWarnings()
    var
        TempBOMWarningLog: Record "BOM Warning Log" temporary;
    begin
        if Rec.IsLineOk(true, TempBOMWarningLog) then
            Message(Text001)
        else
            PAGE.RunModal(PAGE::"BOM Warning Log", TempBOMWarningLog);
    end;

    local procedure ShowWarningsForAllLines()
    var
        TempBOMWarningLog: Record "BOM Warning Log" temporary;
    begin
        if Rec.AreAllLinesOk(TempBOMWarningLog) then
            Message(Text001)
        else
            PAGE.RunModal(PAGE::"BOM Warning Log", TempBOMWarningLog);
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnBeforeUpdatePage()', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefreshPage(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ShowBy: Option; ItemFilter: Code[250]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePage(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item; var SourceRecordVar: Variant; ShowBy: Enum "BOM Structure Show By"; ItemFilter: Code[250]; var IsHandled: Boolean)
    begin
    end;
}

