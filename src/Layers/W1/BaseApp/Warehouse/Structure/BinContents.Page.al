// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;
using System.Text;

page 7374 "Bin Contents"
{
    ApplicationArea = Warehouse;
    Caption = 'Bin Contents';
    DataCaptionExpression = DataCaption;
    InsertAllowed = false;
    PageType = Worksheet;
    AboutTitle = 'About Bin Contents';
    AboutText = 'Manage and configure the items stored in specific warehouse bins, set quantity limits and rules for each item, and define bin properties to support directed put-away, picking, and replenishment processes.';
    SaveValues = true;
    SourceTable = "Bin Content";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(LocationCode; LocationCode)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the locations that bin contents are shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Location.Reset();
                        Location.SetRange("Bin Mandatory", true);
                        if LocationCode <> '' then
                            Location.Code := LocationCode;
                        if PAGE.RunModal(PAGE::"Locations with Warehouse List", Location) = ACTION::LookupOK then begin
                            Location.TestField("Bin Mandatory", true);
                            LocationCode := Location.Code;
                            DefFilter();
                        end;
                        CurrPage.Update(not IsNullGuid(Rec.SystemId));
                    end;

                    trigger OnValidate()
                    begin
                        ZoneCode := '';
                        if LocationCode <> '' then
                            if WMSMgt.LocationIsAllowed(LocationCode) then begin
                                Location.Get(LocationCode);
                                Location.TestField("Bin Mandatory", true);
                            end else
                                Error(Text000, UserId);
                        DefFilter();
                        LocationCodeOnAfterValidate();
                    end;
                }
                field(ZoneCode; ZoneCode)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Zone Filter';
                    ToolTip = 'Specifies the filter that allows you to see an overview of the documents with a certain value in the Service Zone Code field.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Zone.Reset();
                        if ZoneCode <> '' then
                            Zone.Code := ZoneCode;
                        if LocationCode <> '' then
                            Zone.SetRange("Location Code", LocationCode);
                        if PAGE.RunModal(0, Zone) = ACTION::LookupOK then begin
                            ZoneCode := Zone.Code;
                            LocationCode := Zone."Location Code";
                            DefFilter();
                        end;
                        CurrPage.Update(not IsNullGuid(Rec.SystemId));
                    end;

                    trigger OnValidate()
                    begin
                        DefFilter();
                        ZoneCodeOnAfterValidate();
                    end;
                }
            }
            repeater(Control37)
            {
                ShowCaption = false;
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location code of the bin.';
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code of the bin.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';

                    trigger OnValidate()
                    begin
                        CheckQty();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that will be stored in the bin.';

                    trigger OnValidate()
                    begin
                        CheckQty();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CheckQty();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure that are in the unit of measure specified for the item in the bin.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CheckQty();
                    end;
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is the default bin for the associated item.';
                }
                field(Dedicated; Rec.Dedicated)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is used as a dedicated bin, which means that its bin content is available only to certain resources.';
                }
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class code. Only items with the same warehouse class can be stored in this bin.';
                }
                field("Bin Type Code"; Rec."Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin type that was selected for this bin.';
                }
                field("Bin Ranking"; Rec."Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin ranking.';
                }
                field("Block Movement"; Rec."Block Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how the movement of a particular item, or bin content, into or out of this bin, is blocked.';
                }
                field("Min. Qty."; Rec."Min. Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the minimum number of units of the item that you want to have in the bin at all times.';
                }
                field("Max. Qty."; Rec."Max. Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum number of units of the item that you want to have in the bin.';
                }
                field(CalcQtyUOM; Rec.CalcQtyUOM())
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item in the bin that corresponds to the line.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, are stored in the bin.';
                }
                field("Pick Quantity (Base)"; Rec."Pick Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, will be picked from the bin.';
                }
                field("ATO Components Pick Qty (Base)"; Rec."ATO Components Pick Qty (Base)")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many assemble-to-order units are picked for assembly.';
                }
                field("Negative Adjmt. Qty. (Base)"; Rec."Negative Adjmt. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many item units, in the base unit of measure, will be posted on journal lines as negative quantities.';
                }
                field("Put-away Quantity (Base)"; Rec."Put-away Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, will be put away in the bin.';
                }
                field("Positive Adjmt. Qty. (Base)"; Rec."Positive Adjmt. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many item units, in the base unit of measure, will be posted on journal lines as positive quantities.';
                }
                field(CalcQtyAvailToTakeUOM; Rec.CalcQtyAvailToTakeUOM())
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Available Qty. to Take';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available in the bin.';
                }
                field("Fixed"; Rec.Fixed)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the item (bin content) has been associated with this bin, and that the bin should normally contain the item.';
                }
                field("Cross-Dock Bin"; Rec."Cross-Dock Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin content is in a cross-dock bin.';
                }
            }
            group(Control49)
            {
                ShowCaption = false;
                fixed(Control1903651201)
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
                    group("Qty. on Adjustment Bin")
                    {
                        Caption = 'Qty. on Adjustment Bin';
                        field(CalcQtyonAdjmtBin; Rec.CalcQtyonAdjmtBin())
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Qty. on Adjustment Bin';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the adjusted quantity in a bin, when the quantity recorded in the system is inaccurate because of a physical gain or loss of an item.';

                            trigger OnDrillDown()
                            var
                                WhseEntry: Record "Warehouse Entry";
                            begin
                                LocationGet(Rec."Location Code");
                                WhseEntry.SetCurrentKey(
                                  "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
                                WhseEntry.SetRange("Item No.", Rec."Item No.");
                                WhseEntry.SetRange("Bin Code", AdjmtLocation."Adjustment Bin Code");
                                WhseEntry.SetRange("Location Code", Rec."Location Code");
                                WhseEntry.SetRange("Variant Code", Rec."Variant Code");
                                WhseEntry.SetRange("Unit of Measure Code", Rec."Unit of Measure Code");

                                PAGE.RunModal(PAGE::"Warehouse Entries", WhseEntry);
                            end;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control2; "Lot Numbers by Bin FactBox")
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
                action("Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Entries';
                    Image = BinLedger;
                    RunObject = Page "Warehouse Entries";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Location Code" = field("Location Code"),
                                  "Bin Code" = field("Bin Code"),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Item No.", "Bin Code", "Location Code", "Variant Code");
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
            }
        }
        area(processing)
        {
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Location Code")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Location Code", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Zone Code")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Zone Code", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), Page::"Bin Contents", EditinExcelFilters, StrSubstNo(ExcelFileNameTxt, Rec."Location Code", Rec."Zone Code"));
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.GetItemDescr(Rec."Item No.", Rec."Variant Code", ItemDescription);
        DataCaption := StrSubstNo('%1 ', Rec."Bin Code");
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        // if called from API (such as edit-in-excel), do not filter 
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;
        ItemDescription := '';
        Rec.GetWhseLocation(LocationCode, ZoneCode);
        DefFilter();
    end;

    trigger OnAfterGetRecord()
    begin
        RecalculatePickQuantityBaseForCurrentUnitOfMeasureCodeAsFilter();
    end;

    var
        Location: Record Location;
        AdjmtLocation: Record Location;
        Zone: Record Zone;
        WMSMgt: Codeunit "WMS Management";
        LocationCode: Code[10];
        ZoneCode: Code[10];
        DataCaption: Text[80];
        ItemDescription: Text[100];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Location code is not allowed for user %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ExcelFileNameTxt: Label 'BinContents - LocationCode %1 - ZoneCode %2', Comment = '%1 = Location Code; %2 = Zone Code';
        LocFilter: Text;
        IsSaaSExcelAddinEnabled: Boolean;

    local procedure DefFilter()
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        Rec.FilterGroup := 2;
        if LocationCode <> '' then
            Rec.SetRange("Location Code", LocationCode)
        else begin
            Clear(LocFilter);
            Clear(Location);
            Location.SetRange("Bin Mandatory", true);
            if Location.Find('-') then
                repeat
                    if WMSMgt.LocationIsAllowed(Location.Code) then
                        Location.Mark(true);
                until Location.Next() = 0;
            Location.MarkedOnly(true);
            LocFilter := SelectionFilterManagement.GetSelectionFilterForLocation(Location);
            Rec.SetFilter("Location Code", LocFilter);
        end;
        if ZoneCode <> '' then
            Rec.SetRange("Zone Code", ZoneCode)
        else
            Rec.SetRange("Zone Code");
        Rec.FilterGroup := 0;
    end;

    protected procedure CheckQty()
    begin
        Rec.TestField(Quantity, 0);
        Rec.TestField("Pick Qty.", 0);
        Rec.TestField("Put-away Qty.", 0);
        Rec.TestField("Pos. Adjmt. Qty.", 0);
        Rec.TestField("Neg. Adjmt. Qty.", 0);
    end;

    local procedure LocationGet(LocationCode: Code[10])
    begin
        if AdjmtLocation.Code <> LocationCode then
            AdjmtLocation.Get(LocationCode);
    end;

    local procedure LocationCodeOnAfterValidate()
    begin
        CurrPage.Update(not IsNullGuid(Rec.SystemId));
    end;

    local procedure ZoneCodeOnAfterValidate()
    begin
        CurrPage.Update(not IsNullGuid(Rec.SystemId));
    end;

    local procedure RecalculatePickQuantityBaseForCurrentUnitOfMeasureCodeAsFilter()
    var
        IsHandled: Boolean;
        PreviousUnitOfMeasureFilter: Text;
    begin
        IsHandled := false;
        OnBeforeRecalculatePickQuantityBaseForCurrentUnitOfMeasureCodeAsFilter(xRec, Rec, IsHandled);
        if IsHandled then
            exit;

        if (xRec."Location Code" = Rec."Location Code") and (xRec."Unit of Measure Code" = Rec."Unit of Measure Code") then
            exit;

        PreviousUnitOfMeasureFilter := Rec.GetFilter("Unit of Measure Filter");
        Rec.SetFilterOnUnitOfMeasure();
        if Rec.GetFilter("Unit of Measure Filter") = PreviousUnitOfMeasureFilter then
            exit;

        Rec.CalcFields("Pick Quantity (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculatePickQuantityBaseForCurrentUnitOfMeasureCodeAsFilter(xBinContent: Record "Bin Content"; var BinContent: Record "Bin Content"; var IsHandled: Boolean)
    begin
    end;
}

