// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;

codeunit 99000769 "Production BOM-Check"
{
    Permissions = TableData Item = r,
                  TableData "Routing Line" = r,
                  TableData "Manufacturing Setup" = r;
    TableNo = "Production BOM Header";

    trigger OnRun()
    begin
        Code(Rec, '');
    end;

    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RtngLine: Record "Routing Line";
        MfgSetup: Record "Manufacturing Setup";
        VersionMgt: Codeunit VersionManagement;
        Window: Dialog;
        NoOfItems: Integer;
        ItemCounter: Integer;
        CircularRefInBOMErr: Label 'The production BOM %1 has a circular reference. Pay attention to the production BOM %2 that closes the loop.', Comment = '%1 = Production BOM No., %2 = Production BOM No.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Checking Item           #1########## @2@@@@@@@@@@@@@';
        Text001: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number %3, BOM level %4.';
        Text003: Label '%1 with %2 %3 cannot be found. Check %4 %5 %6 %7.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure "Code"(var ProdBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    var
        CalculateLowLevelCode: Codeunit "Calculate Low-Level Code";
    begin
        ProdBOMHeader.TestField("Unit of Measure Code");
        MfgSetup.Get();
        if MfgSetup."Dynamic Low-Level Code" then begin
            CalculateLowLevelCode.SetActualProdBOM(ProdBOMHeader);
            ProdBOMHeader."Low-Level Code" := CalculateLowLevelCode.CalcLevels(2, ProdBOMHeader."No.", ProdBOMHeader."Low-Level Code", 1);
            CalculateLowLevelCode.RecalcLowerLevels(ProdBOMHeader."No.", ProdBOMHeader."Low-Level Code", false);
            ProdBOMHeader.Modify();
        end else
            CheckBOM(ProdBOMHeader."No.", VersionCode);

        ProcessItems(ProdBOMHeader, VersionCode, CalculateLowLevelCode);

        OnAfterCode(ProdBOMHeader, VersionCode);
    end;

    local procedure ProcessItems(var ProductionBOMHeader: Record "Production BOM Header"; VersionCode: Code[20]; var CalculateLowLevelCode: Codeunit "Calculate Low-Level Code")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessItems(ProductionBOMHeader, VersionCode, IsHandled);
        if IsHandled then
            exit;

        Item.SetCurrentKey("Production BOM No.");
        Item.SetRange("Production BOM No.", ProductionBOMHeader."No.");

        OnProcessItemsOnAfterItemSetFilters(Item, ProductionBOMHeader);
        if Item.FindSet() then begin
            OpenDialogWindow();
            NoOfItems := Item.Count();
            ItemCounter := 0;
            repeat
                ItemCounter := ItemCounter + 1;

                UpdateDialogWindow(Item);
                if MfgSetup."Dynamic Low-Level Code" then
                    CalculateLowLevelCode.Run(Item);
                if Item."Routing No." <> '' then
                    CheckBOMStructure(Item, ProductionBOMHeader."No.", VersionCode, 1);
                ItemUnitOfMeasure.Get(Item."No.", ProductionBOMHeader."Unit of Measure Code");
            until Item.Next() = 0;
        end;
    end;

    local procedure OpenDialogWindow()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenDialogWindow(Window, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() then
            Window.Open(Text000);
    end;

    local procedure UpdateDialogWindow(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDialogWindow(Item, ItemCounter, NoOfItems, Window, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() then begin
            Window.Update(1, Item."No.");
            Window.Update(2, Round(ItemCounter / NoOfItems * 10000, 1));
        end;
    end;

#if not CLEAN26
    [Obsolete('Replaced by CheckBOMStructure(var FirstLevelItem: Record Item; BOMHeaderNo: Code[20]; VersionCode: Code[20]; Level: Integer)', '26.0')]
    procedure CheckBOMStructure(BOMHeaderNo: Code[20]; VersionCode: Code[20]; Level: Integer)
    var
        Item: Record Item;
    begin
        CheckBOMStructure(Item, BOMHeaderNo, VersionCode, Level);
    end;
#endif

    procedure CheckBOMStructure(var FirstLevelItem: Record Item; BOMHeaderNo: Code[20]; VersionCode: Code[20]; Level: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        IsHandled: Boolean;
    begin
        if Level > 99 then
            Error(
              Text001,
              99, BOMHeaderNo, FirstLevelItem."Production BOM No.", Level);

        ProductionBOMHeader.Get(BOMHeaderNo);
        OnCheckBOMStructureOnAfterGetProdBOMHeader(ProductionBOMHeader, VersionCode, FirstLevelItem);

        ProductionBOMLine.SetRange("Production BOM No.", BOMHeaderNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetFilter("No.", '<>%1', '');

        OnCheckBOMStructureOnBeforeFindProdBOMComponent(ProductionBOMLine);

        if ProductionBOMLine.FindSet() then
            repeat
                case ProductionBOMLine.Type of
                    ProductionBOMLine.Type::Item:
                        if ProductionBOMLine."Routing Link Code" <> '' then begin
                            IsHandled := false;
                            OnCheckBOMStructureOnBeforeCheckRoutingLine(FirstLevelItem, ProductionBOMLine, BOMHeaderNo, VersionCode, Level, IsHandled);
                            if not IsHandled then begin
                                FirstLevelItem.TestField("Routing No.");
                                RtngLine.SetRange("Routing No.", FirstLevelItem."Routing No.");
                                RtngLine.SetRange("Routing Link Code", ProductionBOMLine."Routing Link Code");
                                if not RtngLine.FindFirst() then
                                    Error(
                                      Text003,
                                      RtngLine.TableCaption(),
                                      RtngLine.FieldCaption("Routing Link Code"),
                                      ProductionBOMLine."Routing Link Code",
                                      ProductionBOMLine.FieldCaption("Production BOM No."),
                                      ProductionBOMLine."Production BOM No.",
                                      ProductionBOMLine.FieldCaption("Line No."),
                                      ProductionBOMLine."Line No.");
                            end;
                        end;
                    ProductionBOMLine.Type::"Production BOM":
                        CheckBOMStructure(
                          FirstLevelItem,
                          ProductionBOMLine."No.",
                          VersionMgt.GetBOMVersion(ProductionBOMLine."No.", WorkDate(), true), Level + 1);
                end;
            until ProductionBOMLine.Next() = 0;
    end;

    procedure ProdBOMLineCheck(ProdBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetFilter(Type, '<>%1', ProductionBOMLine.Type::" ");
        ProductionBOMLine.SetRange("No.", '');
        if ProductionBOMLine.FindFirst() then
            ProductionBOMLine.FieldError("No.");

        OnAfterProdBomLineCheck(ProductionBOMLine, VersionCode);
    end;

    procedure CheckBOM(ProductionBOMNo: Code[20]; VersionCode: Code[20])
    var
        TempProductionBOMHeader: Record "Production BOM Header" temporary;
    begin
        TempProductionBOMHeader."No." := ProductionBOMNo;
        TempProductionBOMHeader.Insert();
        CheckCircularReferencesInProductionBOM(TempProductionBOMHeader, VersionCode);
    end;

    local procedure CheckCircularReferencesInProductionBOM(var TempProductionBOMHeader: Record "Production BOM Header" temporary; VersionCode: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdItem: Record Item;
        ProductionBOMNo: Code[20];
        NextVersionCode: Code[20];
        CheckNextLevel: Boolean;
        IsHandled: Boolean;
    begin
        ProductionBOMLine.SetRange("Production BOM No.", TempProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetFilter("No.", '<>%1', '');
        OnCheckCircularReferencesInProductionBOMOnAfterProdBOMLineSetFilters(ProductionBOMLine, TempProductionBOMHeader, VersionCode);
        if ProductionBOMLine.FindSet() then
            repeat
                IsHandled := false;
                OnCheckCircularReferencesInProductionBOMOnBeforeProdBOMLineCheck(ProductionBOMLine, IsHandled);
                if not IsHandled then begin
                    if ProductionBOMLine.Type = ProductionBOMLine.Type::Item then begin
                        ProdItem.SetLoadFields("Production BOM No.");
                        ProdItem.Get(ProductionBOMLine."No.");
                        ProductionBOMNo := ProdItem."Production BOM No.";
                    end else
                        ProductionBOMNo := ProductionBOMLine."No.";

                    if ProductionBOMNo <> '' then begin
                        TempProductionBOMHeader."No." := ProductionBOMNo;
                        if not TempProductionBOMHeader.Insert() then
                            Error(CircularRefInBOMErr, ProductionBOMNo, ProductionBOMLine."Production BOM No.");

                        NextVersionCode := VersionMgt.GetBOMVersion(ProductionBOMNo, WorkDate(), true);
                        if NextVersionCode <> '' then
                            CheckNextLevel := true
                        else begin
                            ProductionBOMHeader.Get(ProductionBOMNo);
                            CheckNextLevel := ProductionBOMHeader.Status = ProductionBOMHeader.Status::Certified;
                        end;

                        if CheckNextLevel then
                            CheckCircularReferencesInProductionBOM(TempProductionBOMHeader, NextVersionCode);

                        TempProductionBOMHeader.Get(ProductionBOMNo);
                        TempProductionBOMHeader.Delete();
                    end;
                end;
            until ProductionBOMLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ProductionBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdBomLineCheck(ProductionBOMLine: Record "Production BOM Line"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenDialogWindow(var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessItems(var ProdBOMHeader: Record "Production BOM Header"; VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDialogWindow(var Item: Record Item; ItemCounter: Integer; NoOfItems: Integer; var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessItemsOnAfterItemSetFilters(var Item: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCircularReferencesInProductionBOMOnAfterProdBOMLineSetFilters(var ProductionBOMLine: Record "Production BOM Line"; TempProductionBOMHeader: Record "Production BOM Header" temporary; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCircularReferencesInProductionBOMOnBeforeProdBOMLineCheck(var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBOMStructureOnAfterGetProdBOMHeader(ProductionBOMHeader: Record "Production BOM Header"; var VersionCode: Code[20]; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBOMStructureOnBeforeFindProdBOMComponent(var ProdBOMComponent: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckBOMStructureOnBeforeCheckRoutingLine(Item: Record Item; ProductionBOMLine: Record "Production BOM Line"; BOMHeaderNo: Code[20]; VersionCode: Code[20]; Level: Integer; var IsHandled: Boolean)
    begin
    end;
}

