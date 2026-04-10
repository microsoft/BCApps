// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.Threading;
using System.Utilities;

codeunit 3687 "Low-Level Code Calculator"
{
    var
        LowLevelCodeParam: Codeunit "Low-Level Code Parameter";
        NodeKeysAddedToTree: List of [Text];
        ConfirmQst: Label 'Calculate low-level code?';
        BackgroundJobQst: Label 'Would you like to run the low-level code calculation as a background job?';
        RecordDetailsLbl: Label 'Table %1: %2', Comment = '%1 is the table caption, %2 is the record ID';
        ResetLowLevelCodeLbl: Label 'Reset code';
        TimeTakenForRunTxt: Label 'Time taken to run low level calculation through Low- Level Code Calculator is %1.', Comment = '%1 is the time taken', Locked = true;
        LLCResetToZeroTxt: Label 'Low- Level Codes have been reset to 0 for %1 records in the %2 table.', Comment = '%1 is the count of reset records; %2 is the table in which the reset has been done', Locked = true;

    trigger OnRun()
    begin
        Calculate();
    end;

    procedure Calculate()
    begin
        Calculate(true);
    end;

    procedure Calculate(ShowConfirmation: Boolean)
    var
        BOMStructure: Codeunit "BOM Tree";
        ConfirmManagement: Codeunit "Confirm Management";
        Start: DateTime;
    begin
        // Ask for confirmation
        if ShowConfirmation then
            if not ConfirmManagement.GetResponseOrDefault(ConfirmQst, true) then
                exit;

        Start := CurrentDateTime();
        // Take locks to prevent other sessions from updating entities while the calculation is going on
        LockTables();

        LowLevelCodeParam.Create();

        PopulateBOMTree(BOMStructure);

        // This is a full run- so clean up the Low Level Codes for those nodes that are not part of the BOM tree
        ResetLowLevelCodesForEntitiesNotPartOfBOM();

        // Traverse to calculate the low level codes
        LowLevelCodeParam.SetRunMode("Low-Level Code Run Mode"::Calculate);
        BOMStructure.TraverseDown();

        // Calculation completed. Traverse to modify the database
        LowLevelCodeParam.SetRunMode("Low-Level Code Run Mode"::"Write To Database");
        BOMStructure.TraverseDown();

        LowLevelCodeParam.Close();
        Session.LogMessage('0000CIM', StrSubstNo(TimeTakenForRunTxt, CurrentDateTime() - Start), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Planning');

        OnAfterCalculate();
    end;

    procedure SuggestToRunAsBackgroundJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        DummyRecordID: RecordId;
    begin
        // check for existing job
        if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Low-Level Code Calculator") then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(BackgroundJobQst, false) then
            exit;

        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Low-Level Code Calculator", DummyRecordID, 1440); // once daily
    end;

    local procedure PopulateBOMTree(BOMStructure: Codeunit "BOM Tree")
    begin
        // Set nodes on the tree
        PopulateFromItemAndRelatedBOMs(BOMStructure);
        PopulateFromProductionBOMAndLines(BOMStructure);
        PopulateFromBOMComponents(BOMStructure);
    end;

    local procedure LockTables()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        BOMComponent: Record "BOM Component";
    begin
        Item.LockTable();
        ProductionBOMHeader.LockTable();
        ProductionBOMLine.LockTable();
        ProductionBOMVersion.LockTable();
        BOMComponent.LockTable();
    end;

    local procedure ResetLowLevelCodesForEntitiesNotPartOfBOM()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        BOMNode: Codeunit "BOM Node";
        ItemCounter: Integer;
        TotalItems: Integer;
        ProdBOMCounter: Integer;
        TotalBOMs: Integer;
        Counter: Integer;
    begin
        LowLevelCodeParam.ShowHeading(ResetLowLevelCodeLbl);
        Item.SetFilter("Low-Level Code", '<> %1', 0);
        TotalItems := Item.Count();
        ProductionBOMHeader.SetFilter("Low-Level Code", '<> %1', 0);
        TotalBOMs := ProductionBOMHeader.Count();

        LowLevelCodeParam.ShowHeading(ResetLowLevelCodeLbl);
        if Item.FindSet() then
            repeat
                BOMNode.CreateForItem(Item."No.", Item."Low-Level Code", LowLevelCodeParam);
                ItemCounter += 1;
                LowLevelCodeParam.ShowDetails(StrSubstNo(RecordDetailsLbl, Item.TableCaption(), Item."No."), ItemCounter, TotalItems + TotalBOMs);

                if not NodeKeysAddedToTree.Contains(BOMNode.GetKey()) then begin
                    Item.Mark(true);
                    Counter += 1;
                end;
            until Item.Next() = 0;
        if Counter > 0 then begin
            Item.MarkedOnly(true);
            Item.ModifyAll("Low-Level Code", 0);
            Session.LogMessage('0000CIP', StrSubstNo(LLCResetToZeroTxt, Counter, Item.TableName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Planning');
        end;

        Counter := 0;
        if ProductionBOMHeader.FindSet() then
            repeat
                BOMNode.CreateForProdBOM(ProductionBOMHeader."No.", ProductionBOMHeader."Low-Level Code", LowLevelCodeParam);
                ProdBOMCounter += 1;
                LowLevelCodeParam.ShowDetails(StrSubstNo(RecordDetailsLbl, ProductionBOMHeader.TableCaption(), ProductionBOMHeader."No."), TotalItems + ProdBOMCounter, TotalItems + TotalBOMs);

                if not NodeKeysAddedToTree.Contains(BOMNode.GetKey()) then begin
                    ProductionBOMHeader.Mark(true);
                    Counter += 1;
                end;
            until ProductionBOMHeader.Next() = 0;
        if Counter > 0 then begin
            ProductionBOMHeader.MarkedOnly(true);
            ProductionBOMHeader.ModifyAll("Low-Level Code", 0);
            Session.LogMessage('0000CIQ', StrSubstNo(LLCResetToZeroTxt, Counter, ProductionBOMHeader.TableName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Planning');
        end;
    end;

    local procedure PopulateFromItemAndRelatedBOMs(BOMStructure: Codeunit "BOM Tree")
    var
        Item: Record Item;
        Parent: Codeunit "BOM Node";
        Child: Codeunit "BOM Node";
        ItemProductionBOMs: Query "Item Production BOMs";
        Progressed: Integer;
        TotalItemCount: Integer;
    begin
        Item.SetFilter("Production BOM No.", '<> %1', '');
        TotalItemCount := Item.Count();

        ItemProductionBOMs.SetFilter(BOMStatus, '<>%1', Enum::"BOM Status"::Closed);
        ItemProductionBOMs.Open();
        while ItemProductionBOMs.Read() do
            if CheckItemProductionBOMIsCertified(ItemProductionBOMs) then begin
                Progressed += 1;
                LowLevelCodeParam.ShowDetails(StrSubstNo(RecordDetailsLbl, Item.TableCaption(), ItemProductionBOMs.No_), Progressed, TotalItemCount);

                Parent.CreateForItem(ItemProductionBOMs.No_, ItemProductionBOMs.Item_Low_Level_Code, LowLevelCodeParam);
                Child.CreateForProdBOM(ItemProductionBOMs.Production_BOM_No_, ItemProductionBOMs.BOM_Low_Level_Code, LowLevelCodeParam);

                AddChildToParent(BOMStructure, Parent, Child);

                // ensure that next nodes created are new instances
                Clear(Parent);
                Clear(Child);
            end;
        ItemProductionBOMs.Close();
    end;

    local procedure PopulateFromProductionBOMAndLines(BOMStructure: Codeunit "BOM Tree")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Parent: Codeunit "BOM Node";
        Child: Codeunit "BOM Node";
        ProductionBOMLineDetails: Query "Production BOM & Line Details";
        CurrentBOMHeaderNo: Code[20];
        Progressed: Integer;
        TotalProdBOMCount: Integer;
    begin
        TotalProdBOMCount := ProductionBOMHeader.Count();

        CurrentBOMHeaderNo := '';
        ProductionBOMLineDetails.SetFilter(Type, '<> %1', "Production BOM Line Type"::" ");
        ProductionBOMLineDetails.Open();
        while ProductionBOMLineDetails.Read() do begin
            if CurrentBOMHeaderNo <> ProductionBOMLineDetails.No_ then begin
                CurrentBOMHeaderNo := ProductionBOMLineDetails.No_;
                Progressed += 1;
            end;
            LowLevelCodeParam.ShowDetails(StrSubstNo(RecordDetailsLbl, ProductionBOMHeader.TableCaption(), ProductionBOMLineDetails.No_), Progressed, TotalProdBOMCount);

            if (ProductionBOMLineDetails.Status = ProductionBOMLineDetails.Status::Certified) or ((ProductionBOMLineDetails.BOM_Version_Code <> '') and (ProductionBOMLineDetails.BOM_Version_StartingDate <= WorkDate()) and (ProductionBOMLineDetails.BOM_Version_Status = Enum::"BOM Status"::Certified)) then begin
                Parent.CreateForProdBOM(ProductionBOMLineDetails.No_, ProductionBOMLineDetails.Low_Level_Code, LowLevelCodeParam);
                case ProductionBOMLineDetails.Type of
                    "Production BOM Line Type"::Item:
                        if ProductionBOMLineDetails.ChildItem_No_ <> '' then
                            Child.CreateForItem(ProductionBOMLineDetails.ChildItem_No_, ProductionBOMLineDetails.ChildItem_Low_Level_Code, LowLevelCodeParam);
                    "Production BOM Line Type"::"Production BOM":
                        if (ProductionBOMLineDetails.ChildBOM_No_ <> '') and (ProductionBOMLineDetails.ChildBOM_Status = ProductionBOMLineDetails.Status::Certified) then
                            Child.CreateForProdBOM(ProductionBOMLineDetails.ChildBOM_No_, ProductionBOMLineDetails.ChildBOM_Low_Level_Code, LowLevelCodeParam);
                end;

                if Child.IsInitialized() then
                    if not BOMStructure.ChildHasKey(Parent.GetKey(), Child.GetKey()) then
                        AddChildToParent(BOMStructure, Parent, Child);

                // ensure that next nodes created are new instances
                Clear(Parent);
                Clear(Child);
            end;
        end;
        ProductionBOMLineDetails.Close();
    end;

    local procedure PopulateFromBOMComponents(BOMStructure: Codeunit "BOM Tree")
    var
        BOMComponent: Record "BOM Component";
        Parent: Codeunit "BOM Node";
        Child: Codeunit "BOM Node";
        BOMComponentItems: Query "BOM Component Items";
        Progressed: Integer;
        TotalBomComponentCount: Integer;
    begin
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        TotalBomComponentCount := BOMComponent.Count();

        BOMComponentItems.SetRange(Type, BOMComponent.Type::Item);
        BOMComponentItems.Open();
        while BOMComponentItems.Read() do begin
            Progressed += 1;
            LowLevelCodeParam.ShowDetails(StrSubstNo(RecordDetailsLbl, BOMComponent.TableCaption(), BOMComponentItems.Parent_Item_No_), Progressed, TotalBomComponentCount);

            Parent.CreateForItem(BOMComponentItems.Parent_Item_No_, BOMComponentItems.Parent_Low_Level_Code, LowLevelCodeParam);
            Child.CreateForItem(BOMComponentItems.No_, BOMComponentItems.Child_Low_Level_Code, LowLevelCodeParam);

            if not BOMStructure.ChildHasKey(Parent.GetKey(), Child.GetKey()) then
                AddChildToParent(BOMStructure, Parent, Child);

            // ensure that next nodes created are new instances
            Clear(Parent);
            Clear(Child);
        end;
        BOMComponentItems.Close();
    end;

    local procedure AddKeyToList(BOMKey: Text)
    begin
        if NodeKeysAddedToTree.Contains(BOMKey) then
            exit;
        NodeKeysAddedToTree.Add(BOMKey);
    end;

    local procedure AddChildToParent(BOMStructure: Codeunit "BOM Tree"; Parent: Codeunit "BOM Node"; Child: Codeunit "BOM Node")
    begin
        // there can be multiple relations with same parent & child combination, e.g. a BOM can have two lines with the same item or another BOM
        if BOMStructure.ChildHasKey(Parent.GetKey(), Child.GetKey()) then
            exit;

        BOMStructure.AddRelation(Parent, Child);
        AddKeyToList(Parent.GetKey());
        AddKeyToList(Child.GetKey());
    end;

    local procedure CheckItemProductionBOMIsCertified(var ItemProductionBOMs: Query "Item Production BOMs"): Boolean
    var
        VersionManagement: Codeunit VersionManagement;
    begin
        if ItemProductionBOMs.BOMStatus = ItemProductionBOMs.BOMStatus::Certified then
            exit(true);

        exit(VersionManagement.GetBOMVersion(ItemProductionBOMs.Production_BOM_No_, WorkDate(), true) <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate()
    begin
    end;
}