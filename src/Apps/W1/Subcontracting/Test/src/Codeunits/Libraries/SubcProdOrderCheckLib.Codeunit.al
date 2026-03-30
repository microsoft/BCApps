// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 139987 "Subc. ProdOrderCheckLib"
{
    var
        Assert: Codeunit Assert;
        ProdOrderRefreshed: Boolean;
        DescriptionMismatchOnOperationLbl: Label 'Description mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        DirectUnitCostMismatchOnOperationLbl: Label 'Direct Unit Cost mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        DueDateMismatchOnLineLbl: Label 'Due Date mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        ExpectedComponentsButFoundLbl: Label 'Expected %1 components, but found %2', Locked = true;
        ExpectedRoutingLinesButFoundLbl: Label 'Expected %1 routing lines, but found %2', Locked = true;
        FlushingMethodMismatchOnLineLbl: Label 'Flushing Method mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        IndirectCostPercentMismatchOnOperationLbl: Label 'Indirect Cost %% mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        ItemNoMismatchOnLineLbl: Label 'Item No. mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        LocationCodeMismatchOnLineLbl: Label 'Location Code mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        NoMismatchOnOperationLbl: Label 'No. mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        OverheadRateMismatchOnOperationLbl: Label 'Overhead Rate mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        ProdOrderComponentWithLineNoNotFoundLbl: Label 'Production Order Component with Line No. %1 not found', Locked = true;
        ProdOrderRoutingLineWithOperationNoNotFoundLbl: Label 'Production Order Routing Line with Operation No. %1 not found', Locked = true;
        QuantityMismatchOnLineLbl: Label 'Quantity mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        QuantityPerMismatchOnLineLbl: Label 'Quantity per mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        RoutingLinkCodeMismatchOnLineLbl: Label 'Routing Link Code mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        RoutingLinkCodeMismatchOnOperationLbl: Label 'Routing Link Code mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        RunTimeMismatchOnOperationLbl: Label 'Run Time mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        SetupTimeMismatchOnOperationLbl: Label 'Setup Time mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        TypeMismatchOnOperationLbl: Label 'Type mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        UnitCostCalculationMismatchOnOperationLbl: Label 'Unit Cost Calculation mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        WorkCenterGroupCodeMismatchOnOperationLbl: Label 'Work Center Group Code mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        WorkCenterNoMismatchOnOperationLbl: Label 'Work Center No. mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;

    procedure CreateTempProdOrderComponentFromSetup(var TempProdOrderComponent: Record "Prod. Order Component" temporary; PurchLine: Record "Purchase Line")
    var
        TempProdOrderComponent2: Record "Prod. Order Component" temporary;
        SubManagementSetup: Record "Subc. Management Setup";
        LineNo: Integer;
    begin
        // Fill temporary Production Order Component from setup configuration
        SubManagementSetup.Get();

        TempProdOrderComponent2.Copy(TempProdOrderComponent, true);
        if TempProdOrderComponent2.FindLast() then
            LineNo := TempProdOrderComponent2."Line No." + 10000
        else
            LineNo := 10000;

        TempProdOrderComponent.Init();
        TempProdOrderComponent."Line No." := LineNo;
        TempProdOrderComponent."Item No." := SubManagementSetup."Preset Component Item No.";
        TempProdOrderComponent."Location Code" := GetVendorSubcontractingLocation(PurchLine."Buy-from Vendor No.");
        TempProdOrderComponent."Routing Link Code" := SubManagementSetup."Rtng. Link Code Purch. Prov.";
        TempProdOrderComponent."Flushing Method" := SubManagementSetup."Def. provision flushing method";

        TempProdOrderComponent.Insert();
    end;

    local procedure GetVendorSubcontractingLocation(VendorNo: Code[20]): Code[10]
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(Vendor."Subcontr. Location Code");
        exit('');
    end;

    procedure CreateTempProdOrderRoutingFromSetup(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; OperationNo: Code[10])
    var
        SubManagementSetup: Record "Subc. Management Setup";
        WorkCenter: Record "Work Center";
    begin
        SubManagementSetup.Get();

        TempProdOrderRoutingLine.Init();
        TempProdOrderRoutingLine."Operation No." := OperationNo;
        TempProdOrderRoutingLine.Type := TempProdOrderRoutingLine.Type::"Work Center";
        TempProdOrderRoutingLine."No." := SubManagementSetup."Common Work Center No.";
        TempProdOrderRoutingLine."Routing Link Code" := SubManagementSetup."Rtng. Link Code Purch. Prov.";

        if SubManagementSetup."Common Work Center No." <> '' then
            if WorkCenter.Get(SubManagementSetup."Common Work Center No.") then begin
                TempProdOrderRoutingLine."Work Center No." := WorkCenter."No.";
                TempProdOrderRoutingLine."Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
                TempProdOrderRoutingLine."Direct Unit Cost" := WorkCenter."Direct Unit Cost";
                TempProdOrderRoutingLine."Indirect Cost %" := WorkCenter."Indirect Cost %";
                TempProdOrderRoutingLine."Overhead Rate" := WorkCenter."Overhead Rate";
                TempProdOrderRoutingLine."Flushing Method" := SubManagementSetup."Def. provision flushing method";
            end;

        TempProdOrderRoutingLine.Insert();
    end;

    procedure VerifyProdOrder(PurchLine: Record "Purchase Line"; var ProdOrder: Record "Production Order")
    begin
        PurchLine.SetLoadFields("Prod. Order No.", Quantity);
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order No. should be set on Purchase Line');

        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        Assert.AreEqual(PurchLine.Quantity, ProdOrder.Quantity, 'Production Order should have correct Quantity');
    end;

    procedure VerifyProdOrderComponentsMatchTempRecords(ProdOrder: Record "Production Order"; var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    var
        ActualProdOrderComponent: Record "Prod. Order Component";
        ActualComponentCount: Integer;
        LineNo: Integer;
        TempComponentCount: Integer;
    begin
        // Count temporary components
        TempProdOrderComponent.Reset();
        TempComponentCount := TempProdOrderComponent.Count();

        // Count actual components
        ActualProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ActualProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualComponentCount := ActualProdOrderComponent.Count();

        // Verify counts match
        Assert.AreEqual(TempComponentCount, ActualComponentCount,
            StrSubstNo(ExpectedComponentsButFoundLbl, TempComponentCount, ActualComponentCount));

        // Verify each component in sequence
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindSet() then
            repeat
                LineNo := TempProdOrderComponent."Line No.";

                // Find corresponding actual component
                ActualProdOrderComponent.SetRange("Line No.", LineNo);
                Assert.IsTrue(ActualProdOrderComponent.FindFirst(),
                    StrSubstNo(ProdOrderComponentWithLineNoNotFoundLbl, LineNo));

                // Verify key fields match
                VerifyProdOrderComponentFields(TempProdOrderComponent, ActualProdOrderComponent);
            until TempProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyProdOrderComponentFields(TempComponent: Record "Prod. Order Component" temporary; ActualComponent: Record "Prod. Order Component")
    begin
        // Verify essential fields match between temporary and actual component
        Assert.AreEqual(TempComponent."Item No.", ActualComponent."Item No.",
            StrSubstNo(ItemNoMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Item No.", ActualComponent."Item No."));

        Assert.AreEqual(TempComponent."Flushing Method", ActualComponent."Flushing Method",
            StrSubstNo(FlushingMethodMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Flushing Method", ActualComponent."Flushing Method"));

        Assert.AreEqual(TempComponent."Routing Link Code", ActualComponent."Routing Link Code",
            StrSubstNo(RoutingLinkCodeMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Routing Link Code", ActualComponent."Routing Link Code"));

        Assert.AreEqual(TempComponent."Location Code", ActualComponent."Location Code",
            StrSubstNo(LocationCodeMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Location Code", ActualComponent."Location Code"));

        // Verify quantities if set in temporary record
        if TempComponent."Quantity per" <> 0 then
            Assert.AreEqual(TempComponent."Quantity per", ActualComponent."Quantity per",
                StrSubstNo(QuantityPerMismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent."Quantity per", ActualComponent."Quantity per"));

        if TempComponent.Quantity <> 0 then
            Assert.AreEqual(TempComponent.Quantity, ActualComponent.Quantity,
                StrSubstNo(QuantityMismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent.Quantity, ActualComponent.Quantity));

        // Verify dates if set in temporary record
        if TempComponent."Due Date" <> 0D then
            Assert.AreEqual(TempComponent."Due Date", ActualComponent."Due Date",
                StrSubstNo(DueDateMismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent."Due Date", ActualComponent."Due Date"));
    end;

    procedure VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder: Record "Production Order"; var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    var
        ActualProdOrderRoutingLine: Record "Prod. Order Routing Line";
        OperationNo: Code[10];
        ActualRoutingCount: Integer;
        TempRoutingCount: Integer;
    begin
        // Count temporary routing lines
        TempProdOrderRoutingLine.Reset();
        TempRoutingCount := TempProdOrderRoutingLine.Count();

        // Count actual routing lines
        ActualProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ActualProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualRoutingCount := ActualProdOrderRoutingLine.Count();

        // Verify counts match
        Assert.AreEqual(TempRoutingCount, ActualRoutingCount,
            StrSubstNo(ExpectedRoutingLinesButFoundLbl, TempRoutingCount, ActualRoutingCount));

        // Verify each routing line in sequence
        TempProdOrderRoutingLine.Reset();
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                OperationNo := TempProdOrderRoutingLine."Operation No.";

                // Find corresponding actual routing line
                ActualProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
                Assert.IsTrue(ActualProdOrderRoutingLine.FindFirst(),
                    StrSubstNo(ProdOrderRoutingLineWithOperationNoNotFoundLbl, OperationNo));

                // Verify key fields match
                VerifyProdOrderRoutingLineFields(TempProdOrderRoutingLine, ActualProdOrderRoutingLine);
            until TempProdOrderRoutingLine.Next() = 0;
    end;

    local procedure VerifyProdOrderRoutingLineFields(TempRoutingLine: Record "Prod. Order Routing Line" temporary; ActualRoutingLine: Record "Prod. Order Routing Line")
    begin
        // Verify essential fields match between temporary and actual routing line
        Assert.AreEqual(TempRoutingLine.Type, ActualRoutingLine.Type,
            StrSubstNo(TypeMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine.Type, ActualRoutingLine.Type));

        Assert.AreEqual(TempRoutingLine."No.", ActualRoutingLine."No.",
            StrSubstNo(NoMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."No.", ActualRoutingLine."No."));

        Assert.AreEqual(TempRoutingLine."Work Center No.", ActualRoutingLine."Work Center No.",
            StrSubstNo(WorkCenterNoMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."Work Center No.", ActualRoutingLine."Work Center No."));

        Assert.AreEqual(TempRoutingLine."Routing Link Code", ActualRoutingLine."Routing Link Code",
            StrSubstNo(RoutingLinkCodeMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."Routing Link Code", ActualRoutingLine."Routing Link Code"));

        // Verify Work Center Group Code if set
        if TempRoutingLine."Work Center Group Code" <> '' then
            Assert.AreEqual(TempRoutingLine."Work Center Group Code", ActualRoutingLine."Work Center Group Code",
                StrSubstNo(WorkCenterGroupCodeMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Work Center Group Code", ActualRoutingLine."Work Center Group Code"));

        // Verify Unit Cost Calculation if set
        Assert.AreEqual(TempRoutingLine."Unit Cost Calculation", ActualRoutingLine."Unit Cost Calculation",
            StrSubstNo(UnitCostCalculationMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."Unit Cost Calculation", ActualRoutingLine."Unit Cost Calculation"));

        // Verify cost fields if set in temporary record
        if TempRoutingLine."Direct Unit Cost" <> 0 then
            Assert.AreEqual(TempRoutingLine."Direct Unit Cost", ActualRoutingLine."Direct Unit Cost",
                StrSubstNo(DirectUnitCostMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Direct Unit Cost", ActualRoutingLine."Direct Unit Cost"));

        if TempRoutingLine."Indirect Cost %" <> 0 then
            Assert.AreEqual(TempRoutingLine."Indirect Cost %", ActualRoutingLine."Indirect Cost %",
                StrSubstNo(IndirectCostPercentMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Indirect Cost %", ActualRoutingLine."Indirect Cost %"));

        if TempRoutingLine."Overhead Rate" <> 0 then
            Assert.AreEqual(TempRoutingLine."Overhead Rate", ActualRoutingLine."Overhead Rate",
                StrSubstNo(OverheadRateMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Overhead Rate", ActualRoutingLine."Overhead Rate"));

        // Verify time fields if set in temporary record
        if TempRoutingLine."Setup Time" <> 0 then
            Assert.AreEqual(TempRoutingLine."Setup Time", ActualRoutingLine."Setup Time",
                StrSubstNo(SetupTimeMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Setup Time", ActualRoutingLine."Setup Time"));

        if TempRoutingLine."Run Time" <> 0 then
            Assert.AreEqual(TempRoutingLine."Run Time", ActualRoutingLine."Run Time",
                StrSubstNo(RunTimeMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Run Time", ActualRoutingLine."Run Time"));

        // Verify description if set
        if TempRoutingLine.Description <> '' then
            Assert.AreEqual(TempRoutingLine.Description, ActualRoutingLine.Description,
                StrSubstNo(DescriptionMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine.Description, ActualRoutingLine.Description));
    end;

    procedure CreateTempProdOrderComponentFromBOM(var TempProdOrderComponent: Record "Prod. Order Component" temporary; BOMNo: Code[20]; PurchLine: Record "Purchase Line")
    var
        ProductionBOMLine: Record "Production BOM Line";
        SubManagementSetup: Record "Subc. Management Setup";
        LineNo: Integer;
    begin
        // Create temporary Production Order Components based on BOM lines
        TempProdOrderComponent.Reset();
        TempProdOrderComponent.DeleteAll();
        if TempProdOrderComponent.FindLast() then
            LineNo := TempProdOrderComponent."Line No."
        else
            LineNo := 0;

        SubManagementSetup.SetLoadFields("Def. provision flushing method");
        SubManagementSetup.Get();

        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        if ProductionBOMLine.FindSet() then
            repeat
                LineNo += 10000;
                TempProdOrderComponent.Init();
                TempProdOrderComponent."Line No." := LineNo;
                TempProdOrderComponent."Item No." := ProductionBOMLine."No.";
                TempProdOrderComponent."Quantity per" := ProductionBOMLine."Quantity per";
                TempProdOrderComponent."Unit of Measure Code" := ProductionBOMLine."Unit of Measure Code";
                TempProdOrderComponent."Routing Link Code" := ProductionBOMLine."Routing Link Code";
                if ProductionBOMLine."Subcontracting Type" in [ProductionBOMLine."Subcontracting Type"::"Purchase", ProductionBOMLine."Subcontracting Type"::InventoryByVendor] then
                    TempProdOrderComponent."Location Code" := GetVendorSubcontractingLocation(PurchLine."Buy-from Vendor No.")
                else
                    TempProdOrderComponent."Location Code" := PurchLine."Location Code";
                if ProdOrderRefreshed then
                    TempProdOrderComponent."Flushing Method" := "Flushing Method"::"Pick + Manual"
                else
                    TempProdOrderComponent."Flushing Method" := SubManagementSetup."Def. provision flushing method";
                TempProdOrderComponent.Insert();
            until ProductionBOMLine.Next() = 0;
    end;

    procedure CreateTempProdOrderComponentFromBOMVersion(var TempProdOrderComponent: Record "Prod. Order Component" temporary; BOMNo: Code[20]; BOMVersionNo: Code[20]; PurchLine: Record "Purchase Line")
    var
        ProductionBOMLine: Record "Production BOM Line";
        LineNo: Integer;
    begin
        // Create temporary Production Order Components based on BOM Version lines
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindLast() then
            LineNo := TempProdOrderComponent."Line No."
        else
            LineNo := 0;

        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ProductionBOMLine.SetRange("Version Code", BOMVersionNo);
        if ProductionBOMLine.FindSet() then
            repeat
                LineNo += 10000;
                TempProdOrderComponent.Init();
                TempProdOrderComponent."Line No." := LineNo;
                TempProdOrderComponent."Item No." := ProductionBOMLine."No.";
                TempProdOrderComponent."Quantity per" := ProductionBOMLine."Quantity per";
                TempProdOrderComponent."Unit of Measure Code" := ProductionBOMLine."Unit of Measure Code";
                TempProdOrderComponent."Routing Link Code" := ProductionBOMLine."Routing Link Code";
                // Set default flushing method and location code from setup or defaults
                TempProdOrderComponent."Location Code" := PurchLine."Location Code";
                TempProdOrderComponent."Flushing Method" := "Flushing Method"::"Pick + Manual";
                TempProdOrderComponent.Insert();
            until ProductionBOMLine.Next() = 0;
    end;

    procedure CreateTempProdOrderRoutingFromRouting(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; RoutingNo: Code[20])
    var
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Create temporary Production Order Routing Lines based on Routing lines
        TempProdOrderRoutingLine.Reset();
        TempProdOrderRoutingLine.DeleteAll();

        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindSet() then
            repeat
                TempProdOrderRoutingLine.Init();
                TempProdOrderRoutingLine."Operation No." := RoutingLine."Operation No.";
                TempProdOrderRoutingLine.Type := RoutingLine.Type;
                TempProdOrderRoutingLine."No." := RoutingLine."No.";
                TempProdOrderRoutingLine.Description := RoutingLine.Description;
                TempProdOrderRoutingLine."Setup Time" := RoutingLine."Setup Time";
                TempProdOrderRoutingLine."Run Time" := RoutingLine."Run Time";
                TempProdOrderRoutingLine."Wait Time" := RoutingLine."Wait Time";
                TempProdOrderRoutingLine."Move Time" := RoutingLine."Move Time";
                TempProdOrderRoutingLine."Routing Link Code" := RoutingLine."Routing Link Code";

                // Set Work Center specific fields
                case RoutingLine.Type of
                    RoutingLine.Type::"Work Center":
                        if WorkCenter.Get(RoutingLine."No.") then begin
                            TempProdOrderRoutingLine."Work Center No." := WorkCenter."No.";
                            TempProdOrderRoutingLine."Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
                            TempProdOrderRoutingLine."Direct Unit Cost" := WorkCenter."Direct Unit Cost";
                            TempProdOrderRoutingLine."Indirect Cost %" := WorkCenter."Indirect Cost %";
                            TempProdOrderRoutingLine."Overhead Rate" := WorkCenter."Overhead Rate";
                            TempProdOrderRoutingLine."Flushing Method" := WorkCenter."Flushing Method";
                        end;
                    RoutingLine.Type::"Machine Center":
                        if MachineCenter.Get(RoutingLine."No.") then begin
                            TempProdOrderRoutingLine."Work Center No." := MachineCenter."Work Center No.";
                            if WorkCenter.Get(MachineCenter."Work Center No.") then begin
                                TempProdOrderRoutingLine."Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
                                TempProdOrderRoutingLine."Direct Unit Cost" := MachineCenter."Direct Unit Cost";
                                TempProdOrderRoutingLine."Indirect Cost %" := MachineCenter."Indirect Cost %";
                                TempProdOrderRoutingLine."Overhead Rate" := MachineCenter."Overhead Rate";
                                TempProdOrderRoutingLine."Flushing Method" := MachineCenter."Flushing Method";
                            end;
                        end;
                end;

                TempProdOrderRoutingLine.Insert();
            until RoutingLine.Next() = 0;
    end;

    procedure CreateTempProdOrderRoutingFromRoutingVersion(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; RoutingNo: Code[20]; VersionCode: Code[20])
    var
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Create temporary Production Order Routing Lines based on Routing Version lines
        TempProdOrderRoutingLine.Reset();
        TempProdOrderRoutingLine.DeleteAll();

        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", VersionCode);
        if RoutingLine.FindSet() then
            repeat
                TempProdOrderRoutingLine.Init();
                TempProdOrderRoutingLine."Operation No." := RoutingLine."Operation No.";
                TempProdOrderRoutingLine.Type := RoutingLine.Type;
                TempProdOrderRoutingLine."No." := RoutingLine."No.";
                TempProdOrderRoutingLine.Description := RoutingLine.Description;
                TempProdOrderRoutingLine."Setup Time" := RoutingLine."Setup Time";
                TempProdOrderRoutingLine."Run Time" := RoutingLine."Run Time";
                TempProdOrderRoutingLine."Wait Time" := RoutingLine."Wait Time";
                TempProdOrderRoutingLine."Move Time" := RoutingLine."Move Time";
                TempProdOrderRoutingLine."Routing Link Code" := RoutingLine."Routing Link Code";

                // Set Work Center specific fields
                case RoutingLine.Type of
                    RoutingLine.Type::"Work Center":
                        if WorkCenter.Get(RoutingLine."No.") then begin
                            TempProdOrderRoutingLine."Work Center No." := WorkCenter."No.";
                            TempProdOrderRoutingLine."Work Center Group Code" := WorkCenter."Work Center Group Code";
                            TempProdOrderRoutingLine."Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
                            TempProdOrderRoutingLine."Direct Unit Cost" := WorkCenter."Direct Unit Cost";
                            TempProdOrderRoutingLine."Indirect Cost %" := WorkCenter."Indirect Cost %";
                            TempProdOrderRoutingLine."Overhead Rate" := WorkCenter."Overhead Rate";
                            TempProdOrderRoutingLine."Flushing Method" := WorkCenter."Flushing Method";
                        end;
                    RoutingLine.Type::"Machine Center":
                        if MachineCenter.Get(RoutingLine."No.") then begin
                            TempProdOrderRoutingLine."Work Center No." := MachineCenter."Work Center No.";
                            if WorkCenter.Get(MachineCenter."Work Center No.") then begin
                                TempProdOrderRoutingLine."Work Center Group Code" := WorkCenter."Work Center Group Code";
                                TempProdOrderRoutingLine."Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
                                TempProdOrderRoutingLine."Direct Unit Cost" := MachineCenter."Direct Unit Cost";
                                TempProdOrderRoutingLine."Indirect Cost %" := MachineCenter."Indirect Cost %";
                                TempProdOrderRoutingLine."Overhead Rate" := MachineCenter."Overhead Rate";
                                TempProdOrderRoutingLine."Flushing Method" := MachineCenter."Flushing Method";
                            end;
                        end;
                end;

                TempProdOrderRoutingLine.Insert();
            until RoutingLine.Next() = 0;
    end;

    procedure SetRefreshedProdOrder(RefreshProdOrder: Boolean)
    begin
        ProdOrderRefreshed := RefreshProdOrder;
    end;
}