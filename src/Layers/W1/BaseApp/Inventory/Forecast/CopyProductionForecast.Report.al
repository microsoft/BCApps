// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 99003803 "Copy Production Forecast"
{
    Caption = 'Copy Demand Forecast Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Production Forecast Entry"; "Production Forecast Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Production Forecast Name", "Item No.";

            trigger OnAfterGetRecord()
            begin
                if "Entry No." > LastEntryNo then
                    CurrReport.Break();
                ProdForecastEntry2 := "Production Forecast Entry";

                if ToProdForecastEntry."Production Forecast Name" <> '' then
                    ProdForecastEntry2."Production Forecast Name" := ToProdForecastEntry."Production Forecast Name";
                if ToProdForecastEntry."Item No." <> '' then
                    ProdForecastEntry2."Item No." := ToProdForecastEntry."Item No.";
                if ToProdForecastEntry."Location Code" <> '' then
                    ProdForecastEntry2."Location Code" := ToProdForecastEntry."Location Code";
                if ToProdForecastEntry."Variant Code" <> '' then
                    ProdForecastEntry2."Variant Code" := ToProdForecastEntry."Variant Code";
                ProdForecastEntry2."Component Forecast" := ToProdForecastEntry."Component Forecast";
                if Format(ChangeDateExpression) <> '' then
                    ProdForecastEntry2."Forecast Date" := CalcDate(ChangeDateExpression, "Forecast Date");

                ProdForecastEntry2."Entry No." := NextEntryNo;
                if CheckDemandForecastEntry() then begin
                    OnBeforeProdForecastEntryInsert(ProdForecastEntry2, ToProdForecastEntry);
                    ProdForecastEntry2.Insert();
                    NextEntryNo := NextEntryNo + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                ToProdForecastEntry.TestField("Production Forecast Name");
                if not ShowConfirm() then
                    exit;

                LockTable();

                LastEntryNo := ProdForecastEntry2.GetLastEntryNo();
                NextEntryNo := LastEntryNo + 1;
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
                    group("Copy to")
                    {
                        Caption = 'Copy to';
                        field(ProductionForecastName; ToProdForecastEntry."Production Forecast Name")
                        {
                            ApplicationArea = Planning;
                            Caption = 'Demand Forecast Name';
                            TableRelation = "Production Forecast Name";
                            ToolTip = 'Specifies the name of the demand forecast to which you want to copy the entries. Before you can select a demand forecast name, it must be set up in the Demand Forecast Names window, which you open by clicking the field.';
                            ShowMandatory = true;
                            NotBlank = true;
                        }
                        field(ItemNo; ToProdForecastEntry."Item No.")
                        {
                            ApplicationArea = Planning;
                            Caption = 'Item No.';
                            TableRelation = Item;
                            ToolTip = 'Specifies the number of the item to which you want to copy the entries. To see the existing item numbers, click the field.';

                            trigger OnValidate()
                            begin
                                ToProdForecastEntry."Variant Code" := '';
                            end;
                        }
                        field(VariantCode; ToProdForecastEntry."Variant Code")
                        {
                            ApplicationArea = Planning;
                            Caption = 'Variant Code';
                            ToolTip = 'Specifies a item variants for the demand forecast to which you are copying entries.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                ItemVariant: record "Item Variant";
                                ItemVariants: Page "Item Variants";
                            begin
                                ItemVariant.SetRange("Item No.", ToProdForecastEntry."Item No.");
                                ItemVariants.LookupMode := true;
                                ItemVariants.SetTableView(ItemVariant);
                                if ItemVariants.RunModal() <> ACTION::LookupOK then
                                    exit;

                                ItemVariants.GetRecord(ItemVariant);
                                ToProdForecastEntry.Validate("Variant Code", ItemVariant.Code);
                                Text := ItemVariant.Code;
                                exit(false);
                            end;
                        }
                        field(LocationCode; ToProdForecastEntry."Location Code")
                        {
                            ApplicationArea = Planning;
                            Caption = 'Location Code';
                            TableRelation = Location;
                            ToolTip = 'Specifies a location for the demand forecast to which you are copying entries.';
                        }
                    }
                    field(ComponentForecast; ToProdForecastEntry."Component Forecast")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Component Forecast';
                        ToolTip = 'Specifies whether the entry is for a component item. Leave the field blank if the entry is for a sales item.';
                    }
                    field(DateChangeFormula; ChangeDateExpression)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Date Change Formula';
                        ToolTip = 'Specifies how the dates on the entries that are copied will be changed. Use a date formula; for example, to copy last week''s forecast to this week, use the formula 1W (one week).';
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
#pragma warning disable AA0074
        Text000: Label 'Do you want to copy the demand forecast?';
#pragma warning restore AA0074

    protected var
        ToProdForecastEntry: Record "Production Forecast Entry";
        ProdForecastEntry2: Record "Production Forecast Entry";
        ChangeDateExpression: DateFormula;
        LastEntryNo: Integer;
        NextEntryNo: Integer;

    local procedure CheckDemandForecastEntry(): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        if ProdForecastEntry2."Variant Code" <> '' then begin
            ItemVariant.SetRange("Item No.", ProdForecastEntry2."Item No.");
            ItemVariant.SetRange(Code, ProdForecastEntry2."Variant Code");
            exit(not ItemVariant.IsEmpty());
        end
        else
            exit(true);
    end;

    local procedure ShowConfirm() Confirmed: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowConfirm(IsHandled, Confirmed);
        if IsHandled then
            exit;

        Confirmed := Confirm(Text000, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdForecastEntryInsert(var ProdForecastEntry: Record "Production Forecast Entry"; ToProdForecastEntry: Record "Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowConfirm(var IsHandled: Boolean; var Confirmed: Boolean)
    begin
    end;
}

