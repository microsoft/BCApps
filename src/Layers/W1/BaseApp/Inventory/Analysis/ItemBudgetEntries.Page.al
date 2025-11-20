// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Utilities;

page 7133 "Item Budget Entries"
{
    ApplicationArea = ItemBudget;
    Caption = 'Item Budget Entries';
    DataCaptionExpression = Rec.GetCaption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Budget Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = ItemBudget;
                    Editable = false;
                    ToolTip = 'Specifies the name of the item budget that the entry belongs to.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the date of this item budget entry.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the number of the item that this budget entry applies to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies a description of the budget figure.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the source type of this budget entry.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = GlobalDimension1CodeEnable;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = GlobalDimension1CodeVisible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = GlobalDimension2CodeEnable;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = GlobalDimension2CodeVisible;
                }
                field("Budget Dimension 1 Code"; Rec."Budget Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = BudgetDimension1CodeEnable;
                    ToolTip = 'Specifies the dimension value code for the Budget Dimension 1 code that this item budget entry is linked to.';
                    Visible = BudgetDimension1CodeVisible;
                }
                field("Budget Dimension 2 Code"; Rec."Budget Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = BudgetDimension2CodeEnable;
                    ToolTip = 'Specifies the dimension value code for the Budget Dimension 2 code that this item budget entry is linked to.';
                    Visible = BudgetDimension2CodeVisible;
                }
                field("Budget Dimension 3 Code"; Rec."Budget Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = BudgetDimension3CodeEnable;
                    ToolTip = 'Specifies the dimension value code for the Budget Dimension 3 Code that this item budget entry is linked to.';
                    Visible = BudgetDimension3CodeVisible;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that this item budget entry is linked to.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the quantity of this item budget entry.';
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the cost amount of this item budget entry.';
                }
                field("Sales Amount"; Rec."Sales Amount")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the sales amount of this item budget line entry.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = ItemBudget;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
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
        area(navigation)
        {
            group("<Action23>")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("<Action24>")
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Entry No." <> 0 then
            if Rec."Dimension Set ID" <> xRec."Dimension Set ID" then
                LowestModifiedEntryNo := Rec."Entry No.";
    end;

    trigger OnClosePage()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        if LowestModifiedEntryNo < 2147483647 then
            UpdateItemAnalysisView.SetLastBudgetEntryNo(LowestModifiedEntryNo - 1);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec."Entry No." < LowestModifiedEntryNo then
            LowestModifiedEntryNo := Rec."Entry No.";
        exit(true);
    end;

    trigger OnInit()
    begin
        BudgetDimension3CodeEnable := true;
        BudgetDimension2CodeEnable := true;
        BudgetDimension1CodeEnable := true;
        GlobalDimension2CodeEnable := true;
        GlobalDimension1CodeEnable := true;
        BudgetDimension3CodeVisible := true;
        BudgetDimension2CodeVisible := true;
        BudgetDimension1CodeVisible := true;
        GlobalDimension2CodeVisible := true;
        GlobalDimension1CodeVisible := true;
        LowestModifiedEntryNo := 2147483647;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Entry No." < LowestModifiedEntryNo then
            LowestModifiedEntryNo := Rec."Entry No.";
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Budget Name" := Rec.GetRangeMin("Budget Name");
        Rec."Analysis Area" := Rec.GetRangeMin("Analysis Area");
        if (ItemBudgetName.Name <> Rec."Budget Name") or (ItemBudgetName."Analysis Area" <> Rec."Analysis Area") then
            ItemBudgetName.Get(Rec."Analysis Area", Rec."Budget Name");
        if Rec.GetFilter("Item No.") <> '' then
            Rec."Item No." := GetFirstItem(Rec.GetFilter("Item No."));
        Rec.Date := GetFirstDate(Rec.GetFilter(Date));
        Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));

        if Rec.GetFilter("Global Dimension 1 Code") <> '' then
            Rec."Global Dimension 1 Code" :=
              GetFirstDimValue(GLSetup."Global Dimension 1 Code", Rec.GetFilter("Global Dimension 1 Code"));

        if Rec.GetFilter("Global Dimension 2 Code") <> '' then
            Rec."Global Dimension 2 Code" :=
              GetFirstDimValue(GLSetup."Global Dimension 2 Code", Rec.GetFilter("Global Dimension 2 Code"));

        if Rec.GetFilter("Budget Dimension 1 Code") <> '' then
            Rec."Budget Dimension 1 Code" :=
              GetFirstDimValue(ItemBudgetName."Budget Dimension 1 Code", Rec.GetFilter("Budget Dimension 1 Code"));

        if Rec.GetFilter("Budget Dimension 2 Code") <> '' then
            Rec."Budget Dimension 2 Code" :=
              GetFirstDimValue(ItemBudgetName."Budget Dimension 2 Code", Rec.GetFilter("Budget Dimension 2 Code"));

        if Rec.GetFilter("Budget Dimension 3 Code") <> '' then
            Rec."Budget Dimension 3 Code" :=
              GetFirstDimValue(ItemBudgetName."Budget Dimension 3 Code", Rec.GetFilter("Budget Dimension 3 Code"));

        if Rec.GetFilter("Location Code") <> '' then
            Rec."Location Code" := GetFirstLocationCode(Rec.GetFilter("Location Code"));
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Budget Name") = '' then
            ItemBudgetName.Init()
        else begin
            Rec.CopyFilter("Analysis Area", ItemBudgetName."Analysis Area");
            Rec.CopyFilter("Budget Name", ItemBudgetName.Name);
            ItemBudgetName.FindFirst();
        end;
        CurrPage.Editable := not ItemBudgetName.Blocked;
        GLSetup.Get();
        GlobalDimension1CodeEnable := GLSetup."Global Dimension 1 Code" <> '';
        GlobalDimension2CodeEnable := GLSetup."Global Dimension 2 Code" <> '';
        BudgetDimension1CodeEnable := ItemBudgetName."Budget Dimension 1 Code" <> '';
        BudgetDimension2CodeEnable := ItemBudgetName."Budget Dimension 2 Code" <> '';
        BudgetDimension3CodeEnable := ItemBudgetName."Budget Dimension 3 Code" <> '';
        GlobalDimension1CodeVisible := GLSetup."Global Dimension 1 Code" <> '';
        GlobalDimension2CodeVisible := GLSetup."Global Dimension 2 Code" <> '';
        BudgetDimension1CodeVisible := ItemBudgetName."Budget Dimension 1 Code" <> '';
        BudgetDimension2CodeVisible := ItemBudgetName."Budget Dimension 2 Code" <> '';
        BudgetDimension3CodeVisible := ItemBudgetName."Budget Dimension 3 Code" <> '';
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        LowestModifiedEntryNo: Integer;
        GlobalDimension1CodeVisible: Boolean;
        GlobalDimension2CodeVisible: Boolean;
        BudgetDimension1CodeVisible: Boolean;
        BudgetDimension2CodeVisible: Boolean;
        BudgetDimension3CodeVisible: Boolean;
        GlobalDimension1CodeEnable: Boolean;
        GlobalDimension2CodeEnable: Boolean;
        BudgetDimension1CodeEnable: Boolean;
        BudgetDimension2CodeEnable: Boolean;
        BudgetDimension3CodeEnable: Boolean;

    local procedure GetFirstItem(ItemFilter: Text[250]): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        if Item.FindFirst() then
            exit(Item."No.");

        exit('');
    end;

    local procedure GetFirstDate(DateFilter: Text[250]): Date
    var
        Period: Record Date;
    begin
        if DateFilter = '' then
            exit(0D);
        Period.SetRange("Period Type", Period."Period Type"::Date);
        Period.SetFilter("Period Start", DateFilter);
        if Period.FindFirst() then
            exit(Period."Period Start");

        exit(0D);
    end;

    local procedure GetFirstDimValue(DimCode: Code[20]; DimValFilter: Text[250]): Code[20]
    var
        DimVal: Record "Dimension Value";
    begin
        if (DimCode = '') or (DimValFilter = '') then
            exit('');
        DimVal.SetRange("Dimension Code", DimCode);
        DimVal.SetFilter(Code, DimValFilter);
        if DimVal.FindFirst() then
            exit(DimVal.Code);

        exit('');
    end;

    local procedure GetFirstLocationCode(LocationCodetFilter: Text[250]): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetFilter(Code, LocationCodetFilter);
        if Location.FindFirst() then
            exit(Location.Code);

        exit('');
    end;
}

