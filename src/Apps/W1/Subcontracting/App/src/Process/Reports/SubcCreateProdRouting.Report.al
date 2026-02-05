// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using System.Utilities;

report 99001503 "Subc. Create Prod. Routing"
{
    ApplicationArea = Manufacturing;
    Caption = 'Create Production BOM, Routing BOM';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Item';
            trigger OnAfterGetRecord()
            begin
                if GuiAllowed() and not HideDialogWindows then
                    Window.Update(2, "No.");

                if CreateProdBOM then
                    HandleProductionBOM(Item);

                if CreateRouting then
                    HandleRouting(Item);
            end;

            trigger OnPostDataItem()
            var
                StatusProdBOMLbl: Label 'Status Production BOM:';
                StatusRoutingLbl: Label 'Status Routing';
                StatusTxt: Text;
                SumStatusTxt: Text;
            begin
                if GuiAllowed() and not HideDialogWindows then begin
                    Window.Close();

                    if CreateProdBOM then begin
                        Clear(SumStatusTxt);
                        foreach StatusTxt in StatusProdBOMList do
                            SumStatusTxt += '\' + StatusTxt;

                        Message(StatusProdBOMLbl + '\' + SumStatusTxt);
                    end;

                    if CreateRouting then begin
                        Clear(SumStatusTxt);
                        foreach StatusTxt in StatusRoutingList do
                            SumStatusTxt += '\' + StatusTxt;

                        Message(StatusRoutingLbl + '\' + SumStatusTxt);
                    end;
                end;
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                ConfirmBOMQst: Label 'Do you really want to create BOMs for %1 items?', Comment = '%1=Number of Items';
                ConfirmBothQst: Label 'Do you really want to create routings and BOMs for %1 items?', Comment = '%1=Number of Items';
                ConfirmRoutingQst: Label 'Do you really want to create routings for %1 items?', Comment = '%1=Number of Items';
                WindowFromLbl: Label '##1#########\', Locked = true;
                WindowToLbl: Label '##2#########\', Locked = true;
            begin
                ManufacturingSetup.Get();
                if GuiAllowed() and not HideDialogWindows then begin
                    ItemCount := Item.Count();
                    if ItemCount > 1 then
                        if CreateProdBOM and CreateRouting then begin
                            if not ConfirmManagement.GetResponse(StrSubstNo(ConfirmBothQst, ItemCount), true) then
                                Error('');
                        end else begin
                            if CreateProdBOM then
                                if not ConfirmManagement.GetResponse(StrSubstNo(ConfirmBOMQst, ItemCount), true) then
                                    Error('');
                            if CreateRouting then
                                if not ConfirmManagement.GetResponse(StrSubstNo(ConfirmRoutingQst, ItemCount), true) then
                                    Error('');
                        end;
                end;
                Window.Open(WindowFromLbl + WindowToLbl);
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Optionen)
                {
                    Caption = 'Options';
                    field("Create Prod. BOM"; CreateProdBOM)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create Prod. BOM';
                        ToolTip = 'Specifies whether to create a Production BOM for the selected Items.';
                    }
                    field("Create Routing"; CreateRouting)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create Routing';
                        ToolTip = 'Specifies whether to create a Routing for the selected Items.';
                    }
                }
            }
        }
    }
    trigger OnPostReport()
    begin
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        CreateProdBOM, CreateRouting, HideDialogWindows : Boolean;
        Window: Dialog;
        ItemCount: Integer;
        StatusProdBOMList: List of [Text];
        StatusRoutingList: List of [Text];

    trigger OnInitReport()
    begin
        CreateProdBOM := true;
        CreateRouting := true;
    end;

    procedure HideStatusAndWindowsDialog(SetHideDialog: Boolean)
    begin
        HideDialogWindows := SetHideDialog;
    end;

    local procedure GetNextNo(NextNoType: Option ProdBOM,Routing): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        if NextNoType = NextNoType::ProdBOM then begin
            ManufacturingSetup.TestField(ManufacturingSetup."Production BOM Nos.");
            exit(NoSeries.GetNextNo(ManufacturingSetup."Production BOM Nos.", WorkDate(), true));
        end;
        if NextNoType = NextNoType::Routing then begin
            ManufacturingSetup.TestField(ManufacturingSetup."Routing Nos.");
            exit(NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.", WorkDate(), true));
        end;
    end;

    local procedure HandleProductionBOM(var CurrentItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        CreateBOMLbl: Label 'Create Production BOM.';
        ProdBOMCreatedMsg: Label 'Production BOM %1 was created for item %2.', Comment = '%1=Production BOM No., %2=Item No.';
        ProdBOMExistsMsg: Label 'Production BOM %1 already exists.', Comment = '%1=Production BOM No.';
        NextNoType: Option ProdBOM,Routing;
    begin
        if GuiAllowed() and not HideDialogWindows then
            Window.Update(1, CreateBOMLbl);

        if CurrentItem."Production BOM No." = '' then begin
            if CurrentItem."Production BOM No." = '' then begin
                ProductionBOMHeader.Init();
                ProductionBOMHeader."No." := GetNextNo(NextNoType::ProdBOM);
                ProductionBOMHeader.Validate(Description, CurrentItem.Description);
                ProductionBOMHeader."Description 2" := CurrentItem."Description 2";
                ProductionBOMHeader."Unit of Measure Code" := CurrentItem."Base Unit of Measure";
                if ProductionBOMHeader.Insert(true) then begin
                    CurrentItem."Production BOM No." := ProductionBOMHeader."No.";
                    CurrentItem.Modify();
                    StatusProdBOMList.Add(StrSubstNo(ProdBOMCreatedMsg, ProductionBOMHeader."No.", CurrentItem."No."));
                end;
            end
        end else
            StatusProdBOMList.Add(StrSubstNo(ProdBOMExistsMsg, CurrentItem."Production BOM No."));
    end;

    local procedure HandleRouting(var CurrentItem: Record Item)
    var
        RoutingHeader: Record "Routing Header";
        CreateRoutingLbl: Label 'Create Routing.';
        RoutingCreatedMsg: Label 'Routing %1 was created for item %2.', Comment = '%1=Routing No., %2=Item No.';
        RoutingExistsMsg: Label 'Routing %1 already exists.', Comment = '%1=Routing No.';
        NextNoType: Option ProdBOM,Routing;
    begin
        if GuiAllowed() and not HideDialogWindows then
            Window.Update(1, CreateRoutingLbl);

        if CurrentItem."Routing No." = '' then begin
            if CurrentItem."Routing No." = '' then begin
                RoutingHeader.Init();
                RoutingHeader."No." := GetNextNo(NextNoType::Routing);
                RoutingHeader.Validate(Description, CurrentItem.Description);
                RoutingHeader."Description 2" := CurrentItem."Description 2";
                if RoutingHeader.Insert(true) then begin
                    CurrentItem."Routing No." := RoutingHeader."No.";
                    CurrentItem.Modify();
                    StatusRoutingList.Add(StrSubstNo(RoutingCreatedMsg, RoutingHeader."No.", CurrentItem."No."));
                end;
                OnAfterInsertRoutingHeader(RoutingHeader);
            end;
        end else
            StatusRoutingList.Add(StrSubstNo(RoutingExistsMsg, CurrentItem."Routing No."));
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterInsertRoutingHeader(RoutingHeader: Record "Routing Header")
    begin
    end;
}