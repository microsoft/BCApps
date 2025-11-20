// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Automation;
using System.Text;
using System.Utilities;

page 2901 "Demand Forecast Card"
{
    Caption = 'Demand Forecast Overview';
    PageType = Card;
    SourceTable = "Production Forecast Name";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Forecast Name';
                    ToolTip = 'Specifies the name of the demand forecast.';
                    trigger OnValidate()
                    begin
                        SetMatrix();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the demand forecast.';
                }
                field("View By"; Rec."View By")
                {
                    ApplicationArea = Planning;
                    Caption = 'View by';
                    ToolTip = 'Specifies the period of time for which amounts are displayed.';

                    trigger OnValidate()
                    begin
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
                field("Quantity Type"; Rec."Quantity Type")
                {
                    ApplicationArea = Planning;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
                    trigger OnValidate()
                    begin
                        SetMatrix();
                    end;
                }
                field("Forecast Type"; Rec."Forecast Type")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast Type';
                    ToolTip = 'Specifies whether the demand forecast entry is for a sales item or a component item. If you choose Sales Item, only sales orders net the forecast. If you choose Component Item, demand from production order components net the forecast.';

                    trigger OnValidate()
                    begin
                        SetMatrix();
                    end;
                }
                field("Item Filter"; ItemFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies a filter that will show specific items on the Demand Forecast Matrix FastTab. This reduces the number of entries on the FastTab.';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        ItemFilterXMLText: Text;
                    begin
                        if not IsEditable then
                            exit;

                        ItemFilterXMLText := ItemFilterDrillDown(Rec.GetItemFilterBlobAsText());
                        if ItemFilterXMLText <> '' then begin
                            Rec.SetTextFilterToItemFilterBlob(ItemFilterXMLText);
                            Rec.Modify();
                            ItemFilter := Rec.GetItemFilterAsDisplayText();
                            SetMatrix();
                        end;
                    end;
                }
                field("Forecast By Locations"; Rec."Forecast By Locations")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast by Locations';
                    ToolTip = 'Specifies whether to create a forecast entry that includes locations.';
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        LocationFilterIsEnabled := Rec."Forecast By Locations";
                        if not Rec."Forecast By Locations" then
                            LocationFilter := '';
                        SetMatrix();
                    end;
                }
                field("Location Filter"; LocationFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies a location code if you want to create a forecast entry for a specific location.';
                    Importance = Additional;
                    Enabled = LocationFilterIsEnabled;
                    Editable = IsEditable;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(OnLookupLocationFilter(Text, LocationFilter));
                    end;

                    trigger OnValidate()
                    var
                        Location: Record Location;
                    begin
                        Location.SetFilter(Code, LocationFilter);
                        LocationFilter := Location.GetFilter(Code);
                        Rec.SetTextFilterToLocationBlob(LocationFilter);
                        Rec.Modify();
                        SetMatrix();
                    end;
                }
                field("Forecast By Variants"; Rec."Forecast By Variants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast by Variants';
                    ToolTip = 'Use this if you want to create a forecast entry including the variants.';
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        VariantFilterIsEnabled := Rec."Forecast By Variants";
                        if not Rec."Forecast By Variants" then
                            VariantFilter := '';
                        SetMatrix();
                    end;
                }
                field("Variant Filter"; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies an item variant code if you want to create a forecast entry for a specific item variant.';
                    Importance = Additional;
                    Enabled = VariantFilterIsEnabled;
                    Editable = IsEditable;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(OnLookupVariantFilter(Text));
                    end;

                    trigger OnValidate()
                    var
                        ItemVariant: Record "Item Variant";
                    begin
                        ItemVariant.SetFilter(Code, VariantFilter);
                        VariantFilter := ItemVariant.GetFilter(Code);
                        Rec.SetTextFilterToVariantFilterBlob(VariantFilter);
                        Rec.Modify();
                        SetMatrix();
                    end;
                }
                field("Date Filter"; Rec."Date Filter")
                {
                    ApplicationArea = Planning;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                    Editable = IsEditable;

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                        DateFilter: Text;
                    begin
                        DateFilter := Rec."Date Filter";
                        FilterTokens.MakeDateFilter(DateFilter);
                        Rec."Date Filter" := CopyStr(DateFilter, 1, MaxStrLen(Rec."Date Filter"));
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
            }
            part(Matrix; "Demand Forecast Variant Matrix")
            {
                ApplicationArea = Planning;
                Editable = IsEditable;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy Demand Forecast")
                {
                    ApplicationArea = Planning;
                    Caption = 'Copy Demand Forecast Entries';
                    Ellipsis = true;
                    Image = CopyForecast;
                    RunObject = Report "Copy Production Forecast";
                    ToolTip = 'Copy an existing demand forecast to quickly create a similar forecast.';
                }
            }
            action("Previous Set")
            {
                ApplicationArea = Planning;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Previous);
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = Planning;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::PreviousColumn);
                end;
            }
            action("Next Column")
            {
                ApplicationArea = Planning;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::NextColumn);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Planning;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Next);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Previous Column_Promoted"; "Previous Column")
                {
                }
                actionref("Next Column_Promoted"; "Next Column")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsEditable := CurrPage.Editable;
        Rec.CheckDateFilterIsValid();
        SetMatrixColumns("Matrix Page Step Type"::Initial);
    end;

    trigger OnAfterGetRecord()
    begin
        IsEditable := CurrPage.Editable;
        ItemFilter := Rec.GetItemFilterAsDisplayText();
        LocationFilter := Rec.GetLocationFilterBlobAsText();
        VariantFilter := Rec.GetVariantFilterBlobAsText();
        VariantFilterIsEnabled := Rec."Forecast By Variants";
        LocationFilterIsEnabled := Rec."Forecast By Locations";

        if RefreshMatrixOnNextRec then begin
            SetMatrix();
            CurrPage.Matrix.Page.Update(false);
        end;
        RefreshMatrixOnNextRec := false;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        RefreshMatrixOnNextRec := true;
        exit(Rec.Next(Steps));
    end;

    var
        RefreshMatrixOnNextRec: Boolean;


    protected var
        MatrixRecords: array[32] of Record Date;
        VariantFilterIsEnabled: Boolean;
        LocationFilterIsEnabled: Boolean;
        IsEditable: Boolean;
        ItemFilter: Text;
        LocationFilter: Text;
        VariantFilter: Text;
        MatrixColumnCaptions: array[32] of Text[1024];
        ColumnSet: Text;
        PKFirstRecInCurrSet: Text;
        CurrentSetLength: Integer;

    local procedure ItemFilterDrillDown(ItemFilterBlobText: Text): Text
    var
        Item: Record Item;
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPage: FilterPageBuilder;
        ItemCaptionTxt: Code[20];
    begin
        ItemCaptionTxt := CopyStr(Item.TableCaption(), 1, MaxStrLen(ItemCaptionTxt));
        RequestPageParametersHelper.BuildDynamicRequestPage(FilterPage, ItemCaptionTxt, Database::Item);
        RequestPageParametersHelper.SetViewOnDynamicRequestPage(FilterPage, ItemFilterBlobText, ItemCaptionTxt, Database::Item);
        FilterPage.PageCaption := ItemCaptionTxt;
        if not FilterPage.RunModal() then
            exit;
        exit(RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPage, ItemCaptionTxt, Database::Item));
    end;

    local procedure OnLookupLocationFilter(var Text: Text; LocationFilterVal: Text): Boolean
    var
        Loc: Record Location;
        LocList: Page "Location List";
    begin
        Loc.SetRange("Use As In-Transit", false);
        LocList.SetTableView(Loc);

        Loc.SetFilter(Code, LocationFilterVal);
        if Loc.FindSet() then
            LocList.SetRecord(Loc);

        LocList.LookupMode(true);
        if not (LocList.RunModal() = ACTION::LookupOK) then
            exit(false);

        Text := LocList.GetSelectionFilter();

        exit(true);
    end;

    local procedure OnLookupVariantFilter(var Text: Text): Boolean
    var
        ItemVariant: Record "Item Variant";
        ItemVariantList: Page "Item Variants";
    begin
        ItemVariantList.LookupMode(true);
        ItemVariantList.SetTableView(ItemVariant);
        if not (ItemVariantList.RunModal() = ACTION::LookupOK) then
            exit(false);

        Text := ItemVariantList.GetSelectionFilter();

        exit(true);
    end;

    protected procedure SetMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(StepType.AsInteger(), ArrayLen(MatrixRecords), false, Rec."View By", Rec."Date Filter", PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnSet, CurrentSetLength, MatrixRecords);
        SetMatrix();
    end;

    protected procedure SetMatrix()
    begin
        CurrPage.Matrix.PAGE.Load(MatrixColumnCaptions, MatrixRecords, Rec.Name, Rec."Date Filter", Rec."Forecast Type", Rec."Quantity Type", CurrentSetLength, Rec.GetItemFilterBlobAsViewFilters(), Rec.GetLocationFilterBlobAsText(), Rec."Forecast By Locations", Rec."Forecast By Variants", Rec.GetVariantFilterBlobAsText());
    end;
}

