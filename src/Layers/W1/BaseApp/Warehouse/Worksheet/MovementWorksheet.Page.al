// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;

page 7351 "Movement Worksheet"
{
    ApplicationArea = Warehouse;
    Caption = 'Movement Worksheets';
    DataCaptionFields = Name;
    DelayedInsert = true;
    PageType = Worksheet;
    AboutTitle = 'About Movement Worksheets';
    AboutText = 'Plan and execute internal warehouse item movements between bins and zones for purposes such as reorganization or inspection, using worksheet lines that can be filled manually or with automated suggestions, and register the movements for advanced warehouse management.';
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Whse. Worksheet Line";
    SourceTableView = sorting("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentWkshName; CurrentWkshName)
            {
                ApplicationArea = Warehouse;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the worksheet in which you plan movements of inventory in the warehouse.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    Rec.LookupWhseWkshName(Rec, CurrentWkshName, CurrentLocationCode);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    Rec.CheckWhseWkshName(CurrentWkshName, CurrentLocationCode, Rec);
                    CurrentWkshNameOnAfterValidate();
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Warehouse;
                Caption = 'Location Code';
                Editable = false;
                ToolTip = 'Specifies the location where you plan to move inventory in the warehouse.';
            }
            field(CurrentSortingMethod; CurrentSortingMethod)
            {
                ApplicationArea = Warehouse;
                Caption = 'Sorting Method';
                OptionCaption = ' ,Item,,To Bin Code,Due Date';
                ToolTip = 'Specifies the method by which the movement worksheet lines are sorted.';

                trigger OnValidate()
                begin
                    CurrentSortingMethodOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that the line concerns.';

                    trigger OnValidate()
                    begin
                        Rec.GetItem(Rec."Item No.", ItemDescription);
                        ItemNoOnAfterValidate();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item on the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("From Zone Code"; Rec."From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone from which the items should be taken.';
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin from which the items should be taken.';
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone in which the items should be placed.';
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin into which the items should be placed.';

                    trigger OnValidate()
                    begin
                        ToBinCodeOnAfterValidate();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item you want to move.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                    end;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be handled in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, expressed in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item you want to move.';

                    trigger OnValidate()
                    begin
                        QtytoHandleOnAfterValidate();
                    end;
                }
                field("Qty. to Handle (Base)"; Rec."Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity you want to handle, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Handled"; Rec."Qty. Handled")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that has been handled and registered.';
                }
                field("Qty. Handled (Base)"; Rec."Qty. Handled (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that has been handled and registered, in the base unit of measure.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the due date of the line.';

                    trigger OnValidate()
                    begin
                        DueDateOnAfterValidate();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
#pragma warning disable AA0100
                field("ROUND(CheckAvailQtytoMove / ItemUOM.""Qty. per Unit of Measure"",UOMMgt.QtyRndPrecision)"; Round(Rec.CheckAvailQtytoMove() / ItemUOM."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()))
#pragma warning restore AA0100
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Available Qty. to Move';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many item units are available to be moved from the From bin, taking into account other warehouse movements for the item.';
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                fixed(Control1900669001)
                {
                    ShowCaption = false;
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Warehouse;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control8; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                SubPageLink = "Item No." = field("Item No."),
                              "Variant Code" = field("Variant Code"),
                              "Location Code" = field("Location Code");
                Visible = false;
            }
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Entries';
                    Image = BinLedger;
                    RunObject = Page "Warehouse Entries";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    RunPageView = sorting("Item No.", "Location Code", "Variant Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Ledger E&ntries';
                    Image = ItemLedger;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Autofill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Handle';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.Copy(Rec);
                        Rec.AutofillQtyToHandle(WhseWkshLine);
                    end;
                }
                action("Delete Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Handle';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.Copy(Rec);
                        Rec.DeleteQtyToHandle(WhseWkshLine);
                    end;
                }
                separator(Action54)
                {
                }
                action("Calculate Bin &Replenishment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Bin &Replenishment';
                    Ellipsis = true;
                    Image = CalculateBinReplenishment;
                    ToolTip = 'Calculate the movement of items from bulk storage bins with lower bin rankings to bins with a high bin ranking in the picking areas.';

                    trigger OnAction()
                    var
                        Location: Record Location;
                        BinContent: Record "Bin Content";
                        ReplenishBinContent: Report "Calculate Bin Replenishment";
                    begin
                        Location.Get(Rec."Location Code");
                        ReplenishBinContent.InitializeRequest(
                          Rec."Worksheet Template Name", Rec.Name, Rec."Location Code",
                          Location."Allow Breakbulk", false, false);

                        ReplenishBinContent.SetTableView(BinContent);
                        OnCalculateBinAndReplenishmentActionOnBeforeReplenishBinContentRun(ReplenishBinContent, Rec, Location);
                        ReplenishBinContent.Run();
                        Clear(ReplenishBinContent);
                    end;
                }
                action("Get Bin Content")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Get Bin Content';
                    Ellipsis = true;
                    Image = GetBinContent;
                    ToolTip = 'Use a function to create transfer lines with items to put away or pick based on the actual content in the specified bin.';

                    trigger OnAction()
                    var
                        BinContent: Record "Bin Content";
                        DummyRec: Record "Whse. Internal Put-away Header";
                        GetBinContent: Report "Whse. Get Bin Content";
                    begin
                        BinContent.SetRange("Location Code", Rec."Location Code");
                        GetBinContent.SetTableView(BinContent);
                        GetBinContent.SetParameters(Rec, DummyRec, Enum::"Warehouse Destination Type 2"::"MovementWorksheet");
                        GetBinContent.Run();
                    end;
                }
                separator(Action3)
                {
                }
                action("Create Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Movement';
                    Ellipsis = true;
                    Image = CreateMovement;
                    ToolTip = 'Create the specified warehouse movement documents.';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.SetFilter(Quantity, '>0');
                        WhseWkshLine.CopyFilters(Rec);
                        if WhseWkshLine.FindFirst() then
                            Rec.MovementCreate(WhseWkshLine)
                        else
                            Error(Text001);

                        WhseWkshLine.Reset();
                        Rec.CopyFilters(WhseWkshLine);
                        Rec.FilterGroup(2);
                        Rec.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                        Rec.SetRange(Name, Rec.Name);
                        Rec.SetRange("Location Code", CurrentLocationCode);
                        Rec.FilterGroup(0);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the worksheet to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec.Name)), Enum::"Edit in Excel Filter Type"::Equal, CurrentWkshName, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Worksheet Template Name")), Enum::"Edit in Excel Filter Type"::Equal, CurrentWkshTemplateName, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Location Code")), Enum::"Edit in Excel Filter Type"::Equal, CurrentLocationCode, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), Page::"Movement Worksheet", EditInExcelFilters, StrSubstNo(ExcelFileNameTxt, CurrentWkshName, CurrentWkshTemplateName));
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create Movement_Promoted"; "Create Movement")
                {
                }
                actionref("Get Bin Content_Promoted"; "Get Bin Content")
                {
                }
                actionref("Calculate Bin &Replenishment_Promoted"; "Calculate Bin &Replenishment")
                {
                }
                group("Category_Qty. to Handle")
                {
                    Caption = 'Qty. to Handle';
                    ShowAs = SplitButton;

                    actionref("Autofill Qty. to Handle_Promoted"; "Autofill Qty. to Handle")
                    {
                    }
                    actionref("Delete Qty. to Handle_Promoted"; "Delete Qty. to Handle")
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ItemTrackingLines_Promoted; ItemTrackingLines)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Warehouse Entries_Promoted"; "Warehouse Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.GetItem(Rec."Item No.", ItemDescription);
    end;

    trigger OnAfterGetRecord()
    begin
        if not ItemUOM.Get(Rec."Item No.", Rec."From Unit of Measure Code") then
            ItemUOM.Init();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        ItemDescription := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Sorting Sequence No." := Rec.GetSortSeqNo("Whse. Activity Sorting Method".FromInteger(CurrentSortingMethod));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec."Sorting Sequence No." := Rec.GetSortSeqNo("Whse. Activity Sorting Method".FromInteger(CurrentSortingMethod));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        // if called from API (such as edit-in-excel), do not refresh 
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;
        Rec.SetUpNewLine(
          CurrentWkshTemplateName, CurrentWkshName,
          CurrentLocationCode, "Whse. Activity Sorting Method".FromInteger(CurrentSortingMethod), xRec."Line No.");
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ServerSetting: Codeunit "Server Setting";
        WhseWkshSelected: Boolean;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        // if called from API (such as edit-in-excel), do not filter 
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;
        OpenedFromBatch := (Rec.Name <> '') and (Rec."Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentWkshName := Rec.Name;
            CurrentLocationCode := Rec."Location Code";
            Rec.OpenWhseWksh(Rec, CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
            exit;
        end;
        Rec.TemplateSelection(PAGE::"Movement Worksheet", 2, Rec, WhseWkshSelected);
        if not WhseWkshSelected then
            Error('');
        Rec.OpenWhseWksh(Rec, CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
    end;

    var
        ItemUOM: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
        CurrentWkshTemplateName: Code[10];
        CurrentWkshName: Code[10];
        CurrentLocationCode: Code[10];
        CurrentSortingMethod: Option " ",Item,,"Shelf/Bin No.","Due Date";
        ItemDescription: Text[100];
#pragma warning disable AA0074
        Text001: Label 'There is nothing to handle.';
#pragma warning restore AA0074
        ExcelFileNameTxt: Label 'MovementWorkSheet - CurrentWkshName %1 - CurrentWksTemplateName %2', Comment = '%1 = Worksheet Name; %2 = Worksheet Template Name';
        OpenedFromBatch: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;

    protected procedure ItemNoOnAfterValidate()
    begin
        if CurrentSortingMethod = CurrentSortingMethod::Item then
            CurrPage.Update();
    end;

    protected procedure ToBinCodeOnAfterValidate()
    begin
        if CurrentSortingMethod = CurrentSortingMethod::"Shelf/Bin No." then
            CurrPage.Update();
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    protected procedure QtytoHandleOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    protected procedure DueDateOnAfterValidate()
    begin
        if CurrentSortingMethod = CurrentSortingMethod::"Due Date" then
            CurrPage.Update();
    end;

    protected procedure CurrentWkshNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        Rec.SetWhseWkshName(CurrentWkshName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;

    protected procedure CurrentSortingMethodOnAfterValidate()
    begin
        Rec.SortWhseWkshLines(
          CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode,
          "Whse. Activity Sorting Method".FromInteger(CurrentSortingMethod));
        CurrPage.Update(false);
        Rec.SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateBinAndReplenishmentActionOnBeforeReplenishBinContentRun(var CalculateBinReplenishment: Report "Calculate Bin Replenishment"; WhseWorksheetLine: Record "Whse. Worksheet Line"; Location: Record Location)
    begin
    end;
}

