// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reconciliation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;

codeunit 5845 "Get Inventory Report"
{
    TableNo = "Inventory Report Entry";

    trigger OnRun()
    begin
        WindowUpdateDateTime := CurrentDateTime;
        WindowIsOpen := false;

        Rec.Reset();
        Rec.DeleteAll();
        Calculate(Rec);

        if WindowIsOpen then
            Window.Close();
    end;

    var
        InvtReportHeader: Record "Inventory Report Header";
        Item: Record Item;
        GLAcc: Record "G/L Account";
        ValueEntry: Record "Value Entry";
#pragma warning disable AA0074
        Text000: Label 'Calculating...\';
#pragma warning disable AA0470
        Text001: Label 'Type         #1######\';
        Text002: Label 'No.          #2######\';
        Text003: Label 'Posting Type #3######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Window: Dialog;
        WindowIsOpen: Boolean;
        WindowType: Text;
        WindowNo: Text[20];
        WindowPostingType: Text;
        WindowUpdateDateTime: DateTime;
#pragma warning disable AA0074
        Text004: Label 'Show Item Direct Costs,Show Assembly Direct Cost,Show Revaluations,Show Roundings';
        Text005: Label 'Show WIP Consumption,Show WIP Capacity,Show WIP Output';
        Text006: Label 'Show Item Direct Costs,Show Assembly Direct Costs';
        Text007: Label 'Show Item Indirect Costs,Show Assembly Indirect Costs';
#pragma warning restore AA0074

    local procedure Calculate(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        CalcGLPostings(InventoryReportLine);
        CalcInvtPostings(InventoryReportLine);
        InsertDiffReportEntry(InventoryReportLine);

        if InvtReportHeader."Show Warning" then
            DetermineDiffError(InventoryReportLine);
    end;

    local procedure CalcGLPostings(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        CalcGenPostingSetup(InventoryReportLine);
        CalcInvtPostingSetup(InventoryReportLine);
    end;

    local procedure CalcInvtPostings(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        ValueEntry.Reset();
        Clear(InventoryReportLine);
        ValueEntry.SetCurrentKey(
          "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type",
          "Item Charge No.", "Location Code", "Variant Code");
        ValueEntry.SetFilter("Item No.", InvtReportHeader.GetFilter("Item Filter"));
        if ValueEntry.Find('-') then
            repeat
                UpDateWindow(Item.TableCaption(), ValueEntry."Item No.", '');
                ValueEntry.SetRange("Item No.", ValueEntry."Item No.");
                if not Item.Get(ValueEntry."Item No.") then
                    Clear(Item);
                if Item.Type = Item.Type::Inventory then
                    InsertItemInvtReportEntry(InventoryReportLine);

                ValueEntry.SetFilter("Item No.", InvtReportHeader.GetFilter("Item Filter"));
            until ValueEntry.Next() = 0;
    end;

    local procedure InsertDiffReportEntry(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        InventoryReportLine.Init();
        CalcDiff(InventoryReportLine);
        InventoryReportLine.Type := InventoryReportLine.Type::" ";
        InventoryReportLine."No." := '';
        InventoryReportLine.Description := '';
        InventoryReportLine."Entry No." := InventoryReportLine."Entry No." + 1;
        InventoryReportLine.Insert();
    end;

    local procedure DetermineDiffError(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        InventoryReportLine.SetRange(Type, InventoryReportLine.Type::" ");
        if not InventoryReportLine.FindFirst() then
            exit;

        CheckExpectedCostPosting(InventoryReportLine);
        case true of
            CheckIfNoDifference(InventoryReportLine):
                ;
            CheckCostIsPostedToGL(InventoryReportLine):
                ;
            CheckValueGLCompression(InventoryReportLine):
                ;
            CheckGLClosingOverlaps(InventoryReportLine):
                ;
            CheckDeletedGLAcc(InventoryReportLine):
                ;
            CheckPostingDateToGLNotTheSame(InventoryReportLine):
                ;
            CheckDirectPostings(InventoryReportLine):
                ;
        end;
    end;

    local procedure CalcInvtPostingSetup(var InventoryReportLine: Record "Inventory Report Entry")
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
        TempInvtPostingSetup: Record "Inventory Posting Setup" temporary;
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
    begin
        if InvtPostingSetup.Find('-') then
            repeat
                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Inventory Account", InvtPostingSetup."Inventory Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Inventory Account"));
                    InsertGLInvtReportEntry(InventoryReportLine, InvtPostingSetup."Inventory Account", InventoryReportLine.Inventory);
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Inventory Account (Interim)", InvtPostingSetup."Inventory Account (Interim)");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Inventory Account (Interim)"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, InvtPostingSetup."Inventory Account (Interim)", InventoryReportLine."Inventory (Interim)");
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Material Variance Account", InvtPostingSetup."Material Variance Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Material Variance Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, InvtPostingSetup."Material Variance Account", InventoryReportLine."Material Variance");
                end;

                if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then begin
                    TempInvtPostingSetup.Reset();
                    TempInvtPostingSetup.SetRange("Mat. Non-Inv. Variance Acc.", InvtPostingSetup."Mat. Non-Inv. Variance Acc.");
                    if not TempInvtPostingSetup.FindFirst() then begin
                        UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Mat. Non-Inv. Variance Acc."));
                        InsertGLInvtReportEntry(
                          InventoryReportLine, InvtPostingSetup."Mat. Non-Inv. Variance Acc.", InventoryReportLine."Mat. Non-Inventory Variance");
                    end;
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Capacity Variance Account", InvtPostingSetup."Capacity Variance Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Capacity Variance Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, InvtPostingSetup."Capacity Variance Account", InventoryReportLine."Capacity Variance");
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Mfg. Overhead Variance Account", InvtPostingSetup."Mfg. Overhead Variance Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Mfg. Overhead Variance Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, InvtPostingSetup."Mfg. Overhead Variance Account", InventoryReportLine."Mfg. Overhead Variance");
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Cap. Overhead Variance Account", InvtPostingSetup."Cap. Overhead Variance Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Cap. Overhead Variance Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, InvtPostingSetup."Cap. Overhead Variance Account", InventoryReportLine."Capacity Overhead Variance");
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Subcontracted Variance Account", InvtPostingSetup."Subcontracted Variance Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."Subcontracted Variance Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, InvtPostingSetup."Subcontracted Variance Account", InventoryReportLine."Subcontracted Variance");
                end;

                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("WIP Account", InvtPostingSetup."WIP Account");
                if not TempInvtPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, InvtPostingSetup.FieldCaption(InvtPostingSetup."WIP Account"));
                    InsertGLInvtReportEntry(InventoryReportLine, InvtPostingSetup."WIP Account", InventoryReportLine."WIP Inventory");
                end;

                OnCalcInvtPostingSetupOnBeforeAssignTempInvtPostingSetup(InventoryReportLine, TempInvtPostingSetup, InvtReportHeader, InvtPostingSetup);
                TempInvtPostingSetup := InvtPostingSetup;
                TempInvtPostingSetup.Insert();
            until InvtPostingSetup.Next() = 0;
    end;

    local procedure CalcGenPostingSetup(var InventoryReportLine: Record "Inventory Report Entry")
    var
        GenPostingSetup: Record "General Posting Setup";
        TempGenPostingSetup: Record "General Posting Setup" temporary;
    begin
        if GenPostingSetup.Find('-') then
            repeat
                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("COGS Account", GenPostingSetup."COGS Account");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."COGS Account"));
                    InsertGLInvtReportEntry(InventoryReportLine, GenPostingSetup."COGS Account", InventoryReportLine.COGS);
                end;

                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("Inventory Adjmt. Account", GenPostingSetup."Inventory Adjmt. Account");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."Inventory Adjmt. Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, GenPostingSetup."Inventory Adjmt. Account", InventoryReportLine."Inventory Adjmt.");
                end;

                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("Invt. Accrual Acc. (Interim)", GenPostingSetup."Invt. Accrual Acc. (Interim)");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."Invt. Accrual Acc. (Interim)"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, GenPostingSetup."Invt. Accrual Acc. (Interim)", InventoryReportLine."Invt. Accrual (Interim)");
                end;

                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("COGS Account (Interim)", GenPostingSetup."COGS Account (Interim)");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."COGS Account (Interim)"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, GenPostingSetup."COGS Account (Interim)", InventoryReportLine."COGS (Interim)");
                end;

                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("Direct Cost Applied Account", GenPostingSetup."Direct Cost Applied Account");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."Direct Cost Applied Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, GenPostingSetup."Direct Cost Applied Account", InventoryReportLine."Direct Cost Applied");
                end;

                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("Overhead Applied Account", GenPostingSetup."Overhead Applied Account");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."Overhead Applied Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, GenPostingSetup."Overhead Applied Account", InventoryReportLine."Overhead Applied");
                end;

                TempGenPostingSetup.Reset();
                TempGenPostingSetup.SetRange("Purchase Variance Account", GenPostingSetup."Purchase Variance Account");
                if not TempGenPostingSetup.FindFirst() then begin
                    UpDateWindow(WindowType, WindowNo, GenPostingSetup.FieldCaption(GenPostingSetup."Purchase Variance Account"));
                    InsertGLInvtReportEntry(
                      InventoryReportLine, GenPostingSetup."Purchase Variance Account", InventoryReportLine."Purchase Variance");
                end;

                OnCalcGenPostingSetupOnBeforeAssignTempGenPostingSetup(InventoryReportLine, TempGenPostingSetup, InvtReportHeader, GenPostingSetup);
                TempGenPostingSetup := GenPostingSetup;
                TempGenPostingSetup.Insert();
            until GenPostingSetup.Next() = 0;

        OnAfterCalcGenPostingSetup(InventoryReportLine);
    end;

    local procedure InsertGLInvtReportEntry(var InventoryReportLine: Record "Inventory Report Entry"; GLAccNo: Code[20]; var CostAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        InventoryReportLine.Init();
        if not GLAcc.Get(GLAccNo) then
            exit;
        GLAcc.SetFilter("Date Filter", InvtReportHeader.GetFilter("Posting Date Filter"));
        IsHandled := false;
        OnInsertGLInvtReportEntryBeforeCalcGLAccount(InvtReportHeader, InventoryReportLine, GLAcc, IsHandled, CostAmount, WindowPostingType);
        if not IsHandled then
            CostAmount := CalcGLAccount(GLAcc);

        if CostAmount = 0 then
            exit;
        InventoryReportLine.Type := InventoryReportLine.Type::"G/L Account";
        InventoryReportLine."No." := GLAcc."No.";
        InventoryReportLine.Description := GLAcc.Name;
        InventoryReportLine."Entry No." := InventoryReportLine."Entry No." + 1;
        InventoryReportLine.Insert();
    end;

    local procedure InsertItemInvtReportEntry(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        InventoryReportLine.Init();
        CalcItem(InventoryReportLine);
        InventoryReportLine."No." := ValueEntry."Item No.";
        InventoryReportLine.Description := Item.Description;
        InventoryReportLine.Type := InventoryReportLine.Type::Item;
        InventoryReportLine."Entry No." := InventoryReportLine."Entry No." + 1;
        InventoryReportLine.Insert();
    end;

    local procedure CalcItem(var InventoryReportLine: Record "Inventory Report Entry")
    begin
        repeat
            ValueEntry.SetRange("Posting Date", ValueEntry."Posting Date");
            repeat
                if ValueEntryInFilteredSet(ValueEntry, InvtReportHeader, false) then begin
                    if Item."No." <> ValueEntry."Item No." then
                        if not Item.Get(ValueEntry."Item No.") then
                            Item.Init();
                    ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type");
                    ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type");
                    ValueEntry.SetRange("Location Code", ValueEntry."Location Code");
                    ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type");
                    ValueEntry.SetRange("Item Charge No.", ValueEntry."Item Charge No.");

                    if ValueEntryInFilteredSet(ValueEntry, InvtReportHeader, true) then
                        CalcValueEntries(InventoryReportLine);

                    ValueEntry.FindLast();
                    ValueEntry.SetRange("Entry Type");
                    ValueEntry.SetRange("Item Ledger Entry Type");
                    ValueEntry.SetRange("Location Code");
                    ValueEntry.SetRange("Variance Type");
                    ValueEntry.SetRange("Item Charge No.");
                end else
                    ValueEntry.FindLast();
            until ValueEntry.Next() = 0;

            ValueEntry.FindLast();
            ValueEntry.SetFilter("Posting Date", InvtReportHeader.GetFilter("Posting Date Filter"));
        until ValueEntry.Next() = 0;
    end;

    local procedure ValueEntryInFilteredSet(var ValueEntry: Record "Value Entry"; var InvtReportHeader: Record "Inventory Report Header"; Detailed: Boolean): Boolean
    var
        TempValueEntry: Record "Value Entry" temporary;
    begin
        TempValueEntry.SetFilter("Item No.", InvtReportHeader.GetFilter("Item Filter"));
        TempValueEntry.SetFilter("Posting Date", InvtReportHeader.GetFilter("Posting Date Filter"));
        if Detailed then
            TempValueEntry.SetFilter("Location Code", InvtReportHeader.GetFilter("Location Filter"));

        TempValueEntry := ValueEntry;
        TempValueEntry.Insert();
        exit(not TempValueEntry.IsEmpty);
    end;

    local procedure CalcValueEntries(var InventoryReportLine: Record "Inventory Report Entry")
    var
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
    begin
        UpDateWindow(WindowType, WindowNo, Format(ValueEntry."Entry Type"));
        InventoryReportLine."Direct Cost Applied Actual" := InventoryReportLine."Direct Cost Applied Actual" + CalcDirectCostAppliedActual(ValueEntry);
        InventoryReportLine."Overhead Applied Actual" := InventoryReportLine."Overhead Applied Actual" + CalcOverheadAppliedActual(ValueEntry);
        InventoryReportLine."Purchase Variance" := InventoryReportLine."Purchase Variance" + CalcPurchaseVariance(ValueEntry);
        InventoryReportLine."Inventory Adjmt." := InventoryReportLine."Inventory Adjmt." + CalcInventoryAdjmt(ValueEntry);
        InventoryReportLine."Invt. Accrual (Interim)" := InventoryReportLine."Invt. Accrual (Interim)" + CalcInvtAccrualInterim(ValueEntry);
        InventoryReportLine.COGS := InventoryReportLine.COGS + CalcCOGS(ValueEntry);
        InventoryReportLine."COGS (Interim)" := InventoryReportLine."COGS (Interim)" + CalcCOGSInterim(ValueEntry);
        InventoryReportLine."WIP Inventory" := InventoryReportLine."WIP Inventory" + CalcWIPInventory(ValueEntry);
        InventoryReportLine."Material Variance" := InventoryReportLine."Material Variance" + CalcMaterialVariance(ValueEntry);
        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then
            InventoryReportLine."Mat. Non-Inventory Variance" := InventoryReportLine."Mat. Non-Inventory Variance" + CalcMaterialNonInventoryVariance(ValueEntry);
        InventoryReportLine."Capacity Variance" := InventoryReportLine."Capacity Variance" + CalcCapVariance(ValueEntry);
        InventoryReportLine."Subcontracted Variance" := InventoryReportLine."Subcontracted Variance" + CalcSubcontractedVariance(ValueEntry);
        InventoryReportLine."Capacity Overhead Variance" := InventoryReportLine."Capacity Overhead Variance" + CalcCapOverheadVariance(ValueEntry);
        InventoryReportLine."Mfg. Overhead Variance" := InventoryReportLine."Mfg. Overhead Variance" + CalcMfgOverheadVariance(ValueEntry);
        InventoryReportLine."Inventory (Interim)" := InventoryReportLine."Inventory (Interim)" + CalcInventoryInterim(ValueEntry);
        InventoryReportLine."Direct Cost Applied WIP" := InventoryReportLine."Direct Cost Applied WIP" + CalcDirectCostAppliedToWIP(ValueEntry);
        InventoryReportLine."Overhead Applied WIP" := InventoryReportLine."Overhead Applied WIP" + CalcOverheadAppliedToWIP(ValueEntry);
        InventoryReportLine."Inventory To WIP" := InventoryReportLine."Inventory To WIP" + CalcInvtToWIP(ValueEntry);
        InventoryReportLine."WIP To Interim" := InventoryReportLine."WIP To Interim" + CalcWIPToInvtInterim(ValueEntry);
        InventoryReportLine.Inventory := InventoryReportLine.Inventory + CalcInventory(ValueEntry);
        InventoryReportLine."Direct Cost Applied" := InventoryReportLine."Direct Cost Applied" + CalcDirectCostApplied(ValueEntry);
        InventoryReportLine."Overhead Applied" := InventoryReportLine."Overhead Applied" + CalcOverheadApplied(ValueEntry);

        OnAfterCalcValueEntries(InventoryReportLine, ValueEntry);
    end;

    local procedure CalcGLAccount(var GLAcc: Record "G/L Account") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcGLAccount(GLAcc, Result, IsHandled);
        if IsHandled then
            exit(Result);

        UpDateWindow(GLAcc.TableCaption(), GLAcc."No.", WindowPostingType);
        GLAcc.CalcFields(GLAcc."Net Change");
        exit(GLAcc."Net Change");
    end;

    local procedure CalcDiff(var InventoryReportLine: Record "Inventory Report Entry")
    var
        CalcInventoryReportLine: Record "Inventory Report Entry";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
    begin
        CalcInventoryReportLine.Copy(InventoryReportLine);
        InventoryReportLine.Reset();

        InventoryReportLine.SetRange(Type, InventoryReportLine.Type::"G/L Account");
        InventoryReportLine.CalcSums(
          Inventory, "Inventory (Interim)", "WIP Inventory",
          "Direct Cost Applied Actual", "Overhead Applied Actual", "Purchase Variance",
          "Inventory Adjmt.", "Invt. Accrual (Interim)", COGS,
          "COGS (Interim)", "Material Variance", "Mat. Non-Inventory Variance");
        InventoryReportLine.CalcSums(
          "Capacity Variance", "Subcontracted Variance", "Capacity Overhead Variance",
          "Mfg. Overhead Variance", "Direct Cost Applied WIP", "Overhead Applied WIP",
          "Inventory To WIP", "WIP To Interim", "Direct Cost Applied", "Overhead Applied");

        OnCalcDiffOnAfterCalcSumsTypeGLAccount(InventoryReportLine);
        CalcInventoryReportLine := InventoryReportLine;

        InventoryReportLine.SetRange(Type, InventoryReportLine.Type::Item);
        InventoryReportLine.CalcSums(
          Inventory, "Inventory (Interim)", "WIP Inventory",
          "Direct Cost Applied Actual", "Overhead Applied Actual", "Purchase Variance",
          "Inventory Adjmt.", "Invt. Accrual (Interim)", COGS,
          "COGS (Interim)", "Material Variance", "Mat. Non-Inventory Variance");
        InventoryReportLine.CalcSums(
          "Capacity Variance", "Subcontracted Variance", "Capacity Overhead Variance",
          "Mfg. Overhead Variance", "Direct Cost Applied WIP", "Overhead Applied WIP",
          "Inventory To WIP", "WIP To Interim", "Direct Cost Applied", "Overhead Applied");

        OnCalcDiffOnAfterCalcSumsTypeItem(InventoryReportLine);

        CalcInventoryReportLine.Inventory := CalcInventoryReportLine.Inventory - InventoryReportLine.Inventory;
        CalcInventoryReportLine."Inventory (Interim)" := CalcInventoryReportLine."Inventory (Interim)" - InventoryReportLine."Inventory (Interim)";
        CalcInventoryReportLine."WIP Inventory" := CalcInventoryReportLine."WIP Inventory" - InventoryReportLine."WIP Inventory";
        CalcInventoryReportLine."Direct Cost Applied Actual" := CalcInventoryReportLine."Direct Cost Applied Actual" - InventoryReportLine."Direct Cost Applied Actual";
        CalcInventoryReportLine."Overhead Applied Actual" := CalcInventoryReportLine."Overhead Applied Actual" - InventoryReportLine."Overhead Applied Actual";
        CalcInventoryReportLine."Purchase Variance" := CalcInventoryReportLine."Purchase Variance" - InventoryReportLine."Purchase Variance";
        CalcInventoryReportLine."Inventory Adjmt." := CalcInventoryReportLine."Inventory Adjmt." - InventoryReportLine."Inventory Adjmt.";
        CalcInventoryReportLine."Invt. Accrual (Interim)" := CalcInventoryReportLine."Invt. Accrual (Interim)" - InventoryReportLine."Invt. Accrual (Interim)";
        CalcInventoryReportLine.COGS := CalcInventoryReportLine.COGS - InventoryReportLine.COGS;
        CalcInventoryReportLine."COGS (Interim)" := CalcInventoryReportLine."COGS (Interim)" - InventoryReportLine."COGS (Interim)";
        CalcInventoryReportLine."Material Variance" := CalcInventoryReportLine."Material Variance" - InventoryReportLine."Material Variance";
        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then
            CalcInventoryReportLine."Mat. Non-Inventory Variance" := CalcInventoryReportLine."Mat. Non-Inventory Variance" - InventoryReportLine."Mat. Non-Inventory Variance";
        CalcInventoryReportLine."Capacity Variance" := CalcInventoryReportLine."Capacity Variance" - InventoryReportLine."Capacity Variance";
        CalcInventoryReportLine."Subcontracted Variance" := CalcInventoryReportLine."Subcontracted Variance" - InventoryReportLine."Subcontracted Variance";
        CalcInventoryReportLine."Capacity Overhead Variance" := CalcInventoryReportLine."Capacity Overhead Variance" - InventoryReportLine."Capacity Overhead Variance";
        CalcInventoryReportLine."Mfg. Overhead Variance" := CalcInventoryReportLine."Mfg. Overhead Variance" - InventoryReportLine."Mfg. Overhead Variance";
        CalcInventoryReportLine."Direct Cost Applied WIP" := CalcInventoryReportLine."Direct Cost Applied WIP" - InventoryReportLine."Direct Cost Applied WIP";
        CalcInventoryReportLine."Overhead Applied WIP" := CalcInventoryReportLine."Overhead Applied WIP" - InventoryReportLine."Overhead Applied WIP";
        CalcInventoryReportLine."Inventory To WIP" := CalcInventoryReportLine."Inventory To WIP" - InventoryReportLine."Inventory To WIP";
        CalcInventoryReportLine."WIP To Interim" := CalcInventoryReportLine."WIP To Interim" - InventoryReportLine."WIP To Interim";
        CalcInventoryReportLine."Direct Cost Applied" := CalcInventoryReportLine."Direct Cost Applied" - InventoryReportLine."Direct Cost Applied";
        CalcInventoryReportLine."Overhead Applied" := CalcInventoryReportLine."Overhead Applied" - InventoryReportLine."Overhead Applied";

        OnCalcDiffOnBeforeCopytoInventoryReportEntry(CalcInventoryReportLine, InventoryReportLine);
        InventoryReportLine.Copy(CalcInventoryReportLine);
    end;

    local procedure DrillDownGL(var InvtReportEntry: Record "Inventory Report Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", InvtReportEntry."No.");
        GLEntry.SetFilter("Posting Date", InvtReportEntry.GetFilter("Posting Date Filter"));
        OnDrillDownGLBeforeRunPage(GLEntry, InvtReportEntry);
        PAGE.Run(0, GLEntry, GLEntry.Amount);
    end;

    local procedure CalcDirectCostAppliedActual(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then
            case ValueEntry."Item Ledger Entry Type" of
                ValueEntry."Item Ledger Entry Type"::Purchase:
                    begin
                        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
                ValueEntry."Item Ledger Entry Type"::" ":
                    if ValueEntry."Order Type" = ValueEntry."Order Type"::Assembly then begin
                        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
            end;
        exit(0);
    end;

    local procedure CalcOverheadAppliedActual(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Indirect Cost" then
            case ValueEntry."Item Ledger Entry Type" of
                ValueEntry."Item Ledger Entry Type"::Purchase,
                ValueEntry."Item Ledger Entry Type"::Output,
                ValueEntry."Item Ledger Entry Type"::"Assembly Output":
                    begin
                        ValueEntry.CalcSums("Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
                ValueEntry."Item Ledger Entry Type"::" ":
                    if ValueEntry."Order Type" = ValueEntry."Order Type"::Assembly then begin
                        ValueEntry.CalcSums("Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
            end;
        exit(0);
    end;

    local procedure CalcPurchaseVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Purchase)
        then begin
            ValueEntry.CalcSums("Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcInventoryAdjmt(var ValueEntry: Record "Value Entry"): Decimal
    begin
        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::Rounding,
            ValueEntry."Entry Type"::Revaluation:
                begin
                    ValueEntry.CalcSums("Cost Amount (Actual)");
                    exit(-ValueEntry."Cost Amount (Actual)");
                end;
            ValueEntry."Entry Type"::"Direct Cost":
                case ValueEntry."Item Ledger Entry Type" of
                    ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.",
                    ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
                    ValueEntry."Item Ledger Entry Type"::"Assembly Output",
                    ValueEntry."Item Ledger Entry Type"::"Assembly Consumption",
                    ValueEntry."Item Ledger Entry Type"::Transfer:
                        begin
                            ValueEntry.CalcSums("Cost Amount (Actual)");
                            exit(-ValueEntry."Cost Amount (Actual)");
                        end;
                    ValueEntry."Item Ledger Entry Type"::" ":
                        if ValueEntry."Order Type" = ValueEntry."Order Type"::Assembly then begin
                            ValueEntry.CalcSums("Cost Amount (Actual)");
                            exit(-ValueEntry."Cost Amount (Actual)");
                        end;
                end;
        end;
        exit(0);
    end;

    local procedure CalcInvtAccrualInterim(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) and
           (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Purchase)
        then begin
            ValueEntry.CalcSums("Cost Amount (Expected)");
            exit(-ValueEntry."Cost Amount (Expected)");
        end;
        exit(0);
    end;

    local procedure CalcCOGS(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
           (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Sale)
        then begin
            ValueEntry.CalcSums("Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcCOGSInterim(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) and
           (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Sale)
        then begin
            ValueEntry.CalcSums("Cost Amount (Expected)");
            exit(-ValueEntry."Cost Amount (Expected)");
        end;
        exit(0);
    end;

    local procedure CalcWIPInventory(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if ValueEntry."Order Type" = ValueEntry."Order Type"::Production then
            case ValueEntry."Item Ledger Entry Type" of
                ValueEntry."Item Ledger Entry Type"::Consumption:
                    if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then begin
                        ValueEntry.CalcSums("Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
                ValueEntry."Item Ledger Entry Type"::Output:
                    case ValueEntry."Entry Type" of
                        ValueEntry."Entry Type"::"Direct Cost":
                            begin
                                ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
                                exit(-ValueEntry."Cost Amount (Actual)" - ValueEntry."Cost Amount (Expected)");
                            end;
                        ValueEntry."Entry Type"::Revaluation:
                            begin
                                ValueEntry.CalcSums("Cost Amount (Expected)");
                                exit(-ValueEntry."Cost Amount (Expected)");
                            end;
                    end;
                ValueEntry."Item Ledger Entry Type"::" ":
                    if ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::"Indirect Cost"] then begin
                        ValueEntry.CalcSums("Cost Amount (Actual)");
                        exit(ValueEntry."Cost Amount (Actual)");
                    end;
            end;
    end;

    local procedure CalcMaterialVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Output,
                                                     ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
            (ValueEntry."Variance Type" = ValueEntry."Variance Type"::Material)
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcMaterialNonInventoryVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Output,
                                                     ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
            (ValueEntry."Variance Type" = ValueEntry."Variance Type"::"Material - Non Inventory")
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;

        exit(0);
    end;

    local procedure CalcCapVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Output,
                                                     ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
            (ValueEntry."Variance Type" = ValueEntry."Variance Type"::Capacity)
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcSubcontractedVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Output,
                                                     ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
            (ValueEntry."Variance Type" = ValueEntry."Variance Type"::Subcontracted)
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcCapOverheadVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" in ["Item Ledger Entry Type"::Output,
                                                     "Item Ledger Entry Type"::"Assembly Output"]) and
            (ValueEntry."Variance Type" = ValueEntry."Variance Type"::"Capacity Overhead")
        then begin
            ValueEntry.CalcSums("Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcMfgOverheadVariance(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
            (ValueEntry."Item Ledger Entry Type" in ["Item Ledger Entry Type"::Output,
                                                      "Item Ledger Entry Type"::"Assembly Output"]) and
            (ValueEntry."Variance Type" = ValueEntry."Variance Type"::"Manufacturing Overhead")
        then begin
            ValueEntry.CalcSums("Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcInventoryInterim(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) and
            (ValueEntry."Item Ledger Entry Type" in
                ["Item Ledger Entry Type"::Purchase,
                    "Item Ledger Entry Type"::Sale,
                    "Item Ledger Entry Type"::Output])
        then begin
            ValueEntry.CalcSums("Cost Amount (Expected)");
            exit(ValueEntry."Cost Amount (Expected)");
        end;
        exit(0);
    end;

    local procedure CalcOverheadAppliedToWIP(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Indirect Cost") and
           (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::" ") and
           (ValueEntry."Order Type" = ValueEntry."Order Type"::Production)
        then begin
            ValueEntry.CalcSums("Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcDirectCostAppliedToWIP(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
           (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::" ") and
           (ValueEntry."Order Type" = ValueEntry."Order Type"::Production)
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
            exit(-ValueEntry."Cost Amount (Actual)");
        end;
        exit(0);
    end;

    local procedure CalcWIPToInvtInterim(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) and
           (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Output)
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Expected)");
            exit(-ValueEntry."Cost Amount (Expected)");
        end;
        exit(0);
    end;

    local procedure CalcInvtToWIP(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
            (ValueEntry."Item Ledger Entry Type" in
            [ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Item Ledger Entry Type"::Consumption])
        then begin
            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
            exit(ValueEntry."Cost Amount (Actual)");
        end;
    end;

    local procedure CalcInventory(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::" " then
            exit(0);
        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Actual)");
    end;

    local procedure CalcDirectCostApplied(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then
            case ValueEntry."Item Ledger Entry Type" of
                ValueEntry."Item Ledger Entry Type"::Purchase:
                    begin
                        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
                ValueEntry."Item Ledger Entry Type"::" ":
                    begin
                        if ValueEntry."Order Type" = ValueEntry."Order Type"::Assembly then begin
                            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                            exit(-ValueEntry."Cost Amount (Actual)");
                        end;
                        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
            end;
        exit(0);
    end;

    local procedure CalcOverheadApplied(var ValueEntry: Record "Value Entry"): Decimal
    begin
        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Indirect Cost" then
            case ValueEntry."Item Ledger Entry Type" of
                ValueEntry."Item Ledger Entry Type"::Purchase,
                ValueEntry."Item Ledger Entry Type"::Output,
                ValueEntry."Item Ledger Entry Type"::"Assembly Output":
                    begin
                        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
                ValueEntry."Item Ledger Entry Type"::" ":
                    begin
                        if ValueEntry."Order Type" = ValueEntry."Order Type"::Assembly then begin
                            ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                            exit(-ValueEntry."Cost Amount (Actual)");
                        end;
                        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
                        exit(-ValueEntry."Cost Amount (Actual)");
                    end;
            end;
        exit(0);
    end;

    local procedure CopyFiltersFronInventoryReportLine(var ValueEntry: Record "Value Entry"; var InventoryReportEntry: Record "Inventory Report Entry")
    begin
        ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type");
        ValueEntry.SetRange("Item No.", InventoryReportEntry."No.");
        ValueEntry.SetFilter("Posting Date", InventoryReportEntry.GetFilter("Posting Date Filter"));
        ValueEntry.SetFilter("Location Code", InventoryReportEntry.GetFilter("Location Filter"));
    end;

    procedure DrillDownDirectCostApplActual(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Direct Cost Applied Actual"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersDirectCostApplActual(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Text006, 2);
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Variance Type");
        case Selection of
            1:
                ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
            2:
                begin
                    ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
                    ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Assembly);
                end;
        end;
    end;

    procedure DrillDownOverheadAppliedActual(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Overhead Applied Actual"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersOverheadAppliedActual(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Text007, 2);

        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
        ValueEntry.SetRange("Variance Type");
        case Selection of
            1:
                ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2|%3',
                    "Item Ledger Entry Type"::Purchase,
                    "Item Ledger Entry Type"::Output,
                    "Item Ledger Entry Type"::"Assembly Output");
            2:
                begin
                    ValueEntry.SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::" ");
                    ValueEntry.SetRange("Order Type", "Inventory Order Type"::Assembly);
                end;
        end;

        OnAfterSetFiltersOverheadAppliedActual(ValueEntry);
    end;

    procedure DrillDownPurchaseVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Purchase Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersPurchaseVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
    end;

    procedure DrillDownInventoryAdjmt(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Inventory Adjmt."), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersInventoryAdjmt(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Text004, 3);
        if Selection = 0 then
            exit;

        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);

        case Selection of
            1:
                begin
                    ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
                    ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2|%3|%4|%5',
                      ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.",
                      ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
                      ValueEntry."Item Ledger Entry Type"::"Assembly Output",
                      ValueEntry."Item Ledger Entry Type"::"Assembly Consumption",
                      ValueEntry."Item Ledger Entry Type"::Transfer);
                end;
            2:
                begin
                    ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
                    ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Assembly);
                    ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
                end;
            3:
                ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
            4:
                ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        end;
    end;

    procedure DrillDownInvtAccrualInterim(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Invt. Accrual (Interim)"), ValueEntry.FieldNo("Cost Amount (Expected)"));
    end;

    local procedure SetFiltersInvtAccrualInterim(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownCOGS(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(InvtReportEntry, InvtReportEntry.FieldNo(COGS), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersCOGS(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownCOGSInterim(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("COGS (Interim)"), ValueEntry.FieldNo("Cost Amount (Expected)"));
    end;

    local procedure SetFiltersCOGSInterim(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetFilter("Entry Type", '%1|%2', ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownWIPInventory(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("WIP Inventory"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersWIPInventory(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Text005, 3);
        if Selection = 0 then
            exit;

        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Order Type", "Inventory Order Type"::Production);

        case Selection of
            1:
                begin
                    ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
                    ValueEntry.SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Consumption);
                end;
            2:
                begin
                    ValueEntry.SetFilter("Entry Type", '%1|%2', ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::"Indirect Cost");
                    ValueEntry.SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::" ");
                end;
            3:
                begin
                    ValueEntry.SetFilter("Entry Type", '%1|%2', ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation);
                    ValueEntry.SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Output);
                end;
        end;

        OnAfterSetFiltersWIPInventory(ValueEntry, Selection);
    end;

    procedure DrillDownMaterialVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Material Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    procedure DrillDownMaterialNonInventoryVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Mat. Non-Inventory Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersMaterialVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::Material);
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output");
    end;

    local procedure SetFiltersMaterialNonInventoryVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::"Material - Non Inventory");
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output");
    end;

    procedure DrillDownCapVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Capacity Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersCapVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::Capacity);
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output");
    end;

    procedure DrillDownSubcontractedVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Subcontracted Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersSubcontractedVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::Subcontracted);
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output");
    end;

    procedure DrillDownCapOverheadVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Capacity Overhead Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersCapOverheadVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::"Capacity Overhead");
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output");
    end;

    procedure DrillDownMfgOverheadVariance(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Mfg. Overhead Variance"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersMfgOverheadVariance(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::"Manufacturing Overhead");
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output");
    end;

    procedure DrillDownInventoryInterim(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Inventory (Interim)"), ValueEntry.FieldNo("Cost Amount (Expected)"));
    end;

    local procedure SetFiltersInventoryInterim(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetFilter("Entry Type", '%1|%2', ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2|%3',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::Purchase,
          ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownOverheadAppliedToWIP(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Overhead Applied WIP"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersOverheadAppliedToWIP(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownDirectCostApplToWIP(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Direct Cost Applied WIP"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersDirectCostApplToWIP(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownWIPToInvtInterim(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("WIP To Interim"), ValueEntry.FieldNo("Cost Amount (Expected)"));
    end;

    local procedure SetFiltersWIPToInvtInterim(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetFilter("Entry Type", '%1|%2', ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownInvtToWIP(var InvtReportEntry: Record "Inventory Report Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownInvtToWIP(InvtReportEntry, IsHandled);
        if IsHandled then
            exit;

        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Inventory To WIP"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersInvtToWIP(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::Consumption);
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownInventory(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo(Inventory), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersInventory(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type");
        ValueEntry.SetFilter("Item Ledger Entry Type", '<>%1', ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.SetRange("Variance Type");
        ValueEntry.SetFilter("Item Ledger Entry Type", '<>%1', ValueEntry."Item Ledger Entry Type"::" ");
    end;

    procedure DrillDownDirectCostApplied(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Direct Cost Applied"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersDirectCostApplied(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntry."Item Ledger Entry Type"::Purchase,
          ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.SetRange("Variance Type");
    end;

    procedure DrillDownOverheadApplied(var InvtReportEntry: Record "Inventory Report Entry")
    begin
        DrillDownInventoryReportEntryAmount(
          InvtReportEntry, InvtReportEntry.FieldNo("Overhead Applied"), ValueEntry.FieldNo("Cost Amount (Actual)"));
    end;

    local procedure SetFiltersOverheadApplied(var ValueEntry: Record "Value Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
        CopyFiltersFronInventoryReportLine(ValueEntry, InvtReportEntry);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2|%3|%4',
          ValueEntry."Item Ledger Entry Type"::Purchase,
          ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output",
          ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.SetRange("Variance Type");
    end;

    local procedure DrillDownInventoryReportEntryAmount(var InvtReportEntry: Record "Inventory Report Entry"; DrillDownFieldNo: Integer; ActiveFieldNo: Integer)
    begin
        if InvtReportEntry.Type = InvtReportEntry.Type::"G/L Account" then
            DrillDownGL(InvtReportEntry)
        else
            DrillDownInventoryReportValueEntry(InvtReportEntry, DrillDownFieldNo, ActiveFieldNo);
    end;

    local procedure DrillDownInventoryReportValueEntry(var InvtReportEntry: Record "Inventory Report Entry"; DrillDownFieldNo: Integer; ActiveFieldNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        case DrillDownFieldNo of
            InvtReportEntry.FieldNo("Direct Cost Applied Actual"):
                SetFiltersDirectCostApplActual(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Overhead Applied Actual"):
                SetFiltersOverheadAppliedActual(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Purchase Variance"):
                SetFiltersPurchaseVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Inventory Adjmt."):
                SetFiltersInventoryAdjmt(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Invt. Accrual (Interim)"):
                SetFiltersInvtAccrualInterim(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo(COGS):
                SetFiltersCOGS(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("COGS (Interim)"):
                SetFiltersCOGSInterim(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("WIP Inventory"):
                SetFiltersWIPInventory(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Material Variance"):
                SetFiltersMaterialVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Mat. Non-Inventory Variance"):
                SetFiltersMaterialNonInventoryVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Capacity Variance"):
                SetFiltersCapVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Subcontracted Variance"):
                SetFiltersSubcontractedVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Capacity Overhead Variance"):
                SetFiltersCapOverheadVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Mfg. Overhead Variance"):
                SetFiltersMfgOverheadVariance(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Inventory (Interim)"):
                SetFiltersInventoryInterim(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Overhead Applied WIP"):
                SetFiltersOverheadAppliedToWIP(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Direct Cost Applied WIP"):
                SetFiltersDirectCostApplToWIP(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("WIP To Interim"):
                SetFiltersWIPToInvtInterim(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Inventory To WIP"):
                SetFiltersInvtToWIP(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo(Inventory):
                SetFiltersInventory(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Direct Cost Applied"):
                SetFiltersDirectCostApplied(ValueEntry, InvtReportEntry);
            InvtReportEntry.FieldNo("Overhead Applied"):
                SetFiltersOverheadApplied(ValueEntry, InvtReportEntry);
        end;

        PAGE.Run(0, ValueEntry, ActiveFieldNo);
    end;

    procedure SetReportHeader(var InvtReportHeader2: Record "Inventory Report Header")
    begin
        InvtReportHeader.Copy(InvtReportHeader2);
    end;

    local procedure OpenWindow()
    begin
        Window.Open(
          Text000 +
          Text001 +
          Text002 +
          Text003);
        WindowIsOpen := true;
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure UpDateWindow(NewWindowType: Text; NewWindowNo: Code[20]; NewWindowPostingType: Text)
    begin
        WindowType := NewWindowType;
        WindowNo := NewWindowNo;
        WindowPostingType := NewWindowPostingType;

        if IsTimeForUpdate() then begin
            if not WindowIsOpen then
                OpenWindow();
            Window.Update(1, WindowType);
            Window.Update(2, WindowNo);
            Window.Update(3, WindowPostingType);
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckExpectedCostPosting(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        InvtSetup: Record "Inventory Setup";
    begin
        if (InventoryReportLine."Inventory (Interim)" <> 0) or
            (InventoryReportLine."WIP Inventory" <> 0) or
            (InventoryReportLine."Invt. Accrual (Interim)" <> 0) or
            (InventoryReportLine."COGS (Interim)" <> 0)
        then begin
            InvtSetup.Get();
            InventoryReportLine."Expected Cost Posting Warning" := not InvtSetup."Expected Cost Posting to G/L";
            InventoryReportLine.Modify();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckIfNoDifference(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        NoDifference: Boolean;
    begin
        NoDifference :=
            (InventoryReportLine.Inventory = 0) and
            (InventoryReportLine."WIP Inventory" = 0) and
            (InventoryReportLine."Direct Cost Applied Actual" = 0) and
            (InventoryReportLine."Overhead Applied Actual" = 0) and
            (InventoryReportLine."Purchase Variance" = 0) and
            (InventoryReportLine."Inventory Adjmt." = 0) and
            (InventoryReportLine."Invt. Accrual (Interim)" = 0) and
            (InventoryReportLine.COGS = 0) and
            (InventoryReportLine."COGS (Interim)" = 0) and
            (InventoryReportLine."Material Variance" = 0) and
            (InventoryReportLine."Mat. Non-Inventory Variance" = 0) and
            (InventoryReportLine."Capacity Variance" = 0) and
            (InventoryReportLine."Subcontracted Variance" = 0) and
            (InventoryReportLine."Capacity Overhead Variance" = 0) and
            (InventoryReportLine."Mfg. Overhead Variance" = 0) and
            (InventoryReportLine."Direct Cost Applied WIP" = 0) and
            (InventoryReportLine."Overhead Applied WIP" = 0) and
            (InventoryReportLine."Inventory To WIP" = 0) and
            (InventoryReportLine."WIP To Interim" = 0) and
            (InventoryReportLine."Direct Cost Applied" = 0) and
            (InventoryReportLine."Overhead Applied" = 0);

        OnBeforeCheckIfNoDifference(InventoryReportLine, NoDifference);

        exit(NoDifference);
    end;

    local procedure CheckCostIsPostedToGL(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        if ValueEntry.FindFirst() then
            repeat
                ValueEntry.SetRange("Item No.", ValueEntry."Item No.");
                ValueEntry.SetRange("Posting Date", ValueEntry."Posting Date");
                if ValueEntryInFilteredSet(ValueEntry, InvtReportHeader, false) then
                    repeat
                        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type");
                        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type");
                        ValueEntry.SetRange("Location Code", ValueEntry."Location Code");
                        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type");

                        if ValueEntryInFilteredSet(ValueEntry, InvtReportHeader, true) then begin
                            ValueEntry.SetRange("Cost Posted to G/L", 0);
                            ValueEntry.SetFilter("Cost Amount (Actual)", '<>%1', 0);
                            if ValueEntry.FindLast() then begin
                                InventoryReportLine."Cost is Posted to G/L Warning" := true;
                                InventoryReportLine.Modify();
                                exit(true);
                            end;
                            ValueEntry.SetRange("Cost Posted to G/L");
                            ValueEntry.SetRange("Cost Amount (Actual)");
                        end;
                        ValueEntry.FindLast();
                        ValueEntry.SetRange("Entry Type");
                        ValueEntry.SetRange("Item Ledger Entry Type");
                        ValueEntry.SetRange("Location Code");
                        ValueEntry.SetRange("Variance Type");
                    until ValueEntry.Next() = 0;

                if ValueEntry.FindLast() then;
                ValueEntry.SetRange("Item No.");
                ValueEntry.SetRange("Posting Date");
            until ValueEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckValueGLCompression(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        DateComprRegister: Record "Date Compr. Register";
        InStartDateCompr: Boolean;
        InEndDateCompr: Boolean;
    begin
        DateComprRegister.SetCurrentKey("Table ID");
        DateComprRegister.SetFilter("Table ID", '%1|%2', DATABASE::"Value Entry", DATABASE::"G/L Entry");
        DateComprRegister.SetFilter("Starting Date", InvtReportHeader.GetFilter("Posting Date Filter"));
        InStartDateCompr := DateComprRegister.FindFirst();
        DateComprRegister.SetFilter("Ending Date", InvtReportHeader.GetFilter("Posting Date Filter"));
        InEndDateCompr := DateComprRegister.FindFirst();
        if InEndDateCompr or InStartDateCompr then begin
            InventoryReportLine."Compression Warning" := true;
            InventoryReportLine.Modify();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckGLClosingOverlaps(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        GLEntry: Record "G/L Entry";
        MinDate: Date;
        Found: Boolean;
        ShouldExit: Boolean;
    begin
        if ((InventoryReportLine."Direct Cost Applied Actual" = 0) and
            (InventoryReportLine."Overhead Applied Actual" = 0) and
            (InventoryReportLine."Purchase Variance" = 0) and
            (InventoryReportLine."Inventory Adjmt." = 0) and
            (InventoryReportLine.COGS = 0) and
            (InventoryReportLine."Material Variance" = 0) and
            (InventoryReportLine."Mat. Non-Inventory Variance" = 0) and
            (InventoryReportLine."Capacity Variance" = 0) and
            (InventoryReportLine."Subcontracted Variance" = 0) and
            (InventoryReportLine."Capacity Overhead Variance" = 0) and
            (InventoryReportLine."Mfg. Overhead Variance" = 0) and
            (InventoryReportLine."Direct Cost Applied WIP" = 0) and
            (InventoryReportLine."Overhead Applied WIP" = 0) and
            (InventoryReportLine."Inventory To WIP" = 0) and
            (InventoryReportLine."Direct Cost Applied" = 0) and
            (InventoryReportLine."Overhead Applied" = 0))
        then
            exit(false);

        ShouldExit := AccountingPeriod.IsEmpty();
        OnCheckGLClosingOverlapsOnAfterEmptyAccountingPeriodBeforeExit(InventoryReportLine, ShouldExit);
        if ShouldExit then
            exit(false);

        AccountingPeriod.SetFilter("Starting Date", InvtReportHeader.GetFilter("Posting Date Filter"));
        if InvtReportHeader.GetFilter("Posting Date Filter") <> '' then
            MinDate := InvtReportHeader.GetRangeMin("Posting Date Filter")
        else
            MinDate := 0D;

        Found :=
            AccountingPeriod.Find('-') and AccountingPeriod.Closed and
            (AccountingPeriod."Starting Date" <= MinDate);
        if AccountingPeriod."Starting Date" > MinDate then begin
            AccountingPeriod.SetRange("Starting Date");
            if not Found then
                Found :=
                    AccountingPeriod.Next(-1) <> 0;
            if not Found then
                Found := AccountingPeriod.Closed;
        end;
        if Found then
            repeat
                repeat
                until (AccountingPeriod.Next() = 0) or AccountingPeriod."New Fiscal Year";
                if AccountingPeriod."New Fiscal Year" then
                    AccountingPeriod."Starting Date" := ClosingDate(CalcDate('<-1D>', AccountingPeriod."Starting Date"))
                else
                    AccountingPeriod."Starting Date" := ClosingDate(AccountingPeriod."Starting Date");
                AccountingPeriod.SetFilter("Starting Date", InvtReportHeader.GetFilter("Posting Date Filter"));
                GLEntry.SetRange("Posting Date", AccountingPeriod."Starting Date");
                if not GLEntry.IsEmpty() then begin
                    InventoryReportLine."Closing Period Overlap Warning" := true;
                    InventoryReportLine.Modify();
                    exit(true);
                end;
                AccountingPeriod.SetRange(Closed, true);
            until AccountingPeriod.Next() = 0;

        exit(false);
    end;

    local procedure CheckDeletedGLAcc(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry.SetRange("G/L Account No.", '');
        GLEntry.SetFilter("Posting Date", InvtReportHeader.GetFilter("Posting Date Filter"));
        if GLEntry.FindFirst() then begin
            InventoryReportLine."Deleted G/L Accounts Warning" := true;
            InventoryReportLine.Modify();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckPostingDateToGLNotTheSame(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        ValueEntry: Record "Value Entry";
        InvtPostingSetup: Record "Inventory Posting Setup";
        TempInvtPostingSetup: Record "Inventory Posting Setup" temporary;
        TotalInventory: Decimal;
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.");
        if ValueEntry.FindFirst() then
            repeat
                ValueEntry.SetRange("Item No.", ValueEntry."Item No.");
                if ValueEntry."Item No." <> '' then
                    TotalInventory := TotalInventory + CalcInventory(ValueEntry);
                ValueEntry.FindLast();
                ValueEntry.SetRange("Item No.");
            until ValueEntry.Next() = 0;

        if InvtPostingSetup.Find('-') then
            repeat
                TempInvtPostingSetup.Reset();
                TempInvtPostingSetup.SetRange("Inventory Account", InvtPostingSetup."Inventory Account");
                if not IsGLNotTheSameHandled(InventoryReportLine, InvtPostingSetup, TempInvtPostingSetup, TotalInventory) then
                    if not TempInvtPostingSetup.FindFirst() then
                        if GLAcc.Get(InvtPostingSetup."Inventory Account") then
                            TotalInventory := TotalInventory - CalcGLAccount(GLAcc);
                TempInvtPostingSetup := InvtPostingSetup;
                TempInvtPostingSetup.Insert();
            until InvtPostingSetup.Next() = 0;
        if TotalInventory = 0 then begin
            InventoryReportLine."Posting Date Warning" := true;
            InventoryReportLine.Modify();
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckDirectPostings(var InventoryReportLine: Record "Inventory Report Entry"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDirectPostings(InventoryReportLine, IsHandled);
        if IsHandled then
            exit(isHandled);

        if InventoryReportLine.Inventory +
            InventoryReportLine."Inventory (Interim)" +
            InventoryReportLine."WIP Inventory" +
            InventoryReportLine."Direct Cost Applied Actual" +
            InventoryReportLine."Overhead Applied Actual" +
            InventoryReportLine."Purchase Variance" +
            InventoryReportLine."Inventory Adjmt." +
            InventoryReportLine."Invt. Accrual (Interim)" +
            InventoryReportLine.COGS +
            InventoryReportLine."COGS (Interim)" +
            InventoryReportLine."Material Variance" +
            InventoryReportLine."Mat. Non-Inventory Variance" +
            InventoryReportLine."Capacity Variance" +
            InventoryReportLine."Subcontracted Variance" +
            InventoryReportLine."Capacity Overhead Variance" +
            InventoryReportLine."Mfg. Overhead Variance" +
            InventoryReportLine."Direct Cost Applied WIP" +
            InventoryReportLine."Overhead Applied WIP" +
            InventoryReportLine."Direct Cost Applied" +
            InventoryReportLine."Overhead Applied" <> 0
        then begin
            InventoryReportLine."Direct Postings Warning" := true;
            InventoryReportLine.Modify();
            exit(true);
        end;
        exit(false);
    end;

    local procedure IsGLNotTheSameHandled(var InventoryReportLine: Record "Inventory Report Entry"; var InvtPostingSetup: Record "Inventory Posting Setup"; var TempInvtPostingSetup: Record "Inventory Posting Setup" temporary; var TotalInventory: Decimal) IsHandled: Boolean
    begin
        OnBeforeIsGLNotTheSameHandled(TempInvtPostingSetup, InvtPostingSetup, InvtReportHeader, InventoryReportLine, IsHandled, TotalInventory, WindowPostingType)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsGLNotTheSameHandled(var TempInvtentoryPostingSetup: Record "Inventory Posting Setup" temporary; var InvtentoryPostingSetup: Record "Inventory Posting Setup"; var InvtentoryReportHeader: Record "Inventory Report Header"; var InventoryReportLine: Record "Inventory Report Entry"; var IsHandled: Boolean; var TotalInventory: Decimal; WindowPostingType: Text[80])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvtPostingSetupOnBeforeAssignTempInvtPostingSetup(var InventoryReportEntry: Record "Inventory Report Entry"; var TempInventoryPostingSetup: Record "Inventory Posting Setup" temporary; var InventoryReportHeader: Record "Inventory Report Header"; InventoryPostingSetup: Record "Inventory Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGenPostingSetupOnBeforeAssignTempGenPostingSetup(var InventoryReportEntry: Record "Inventory Report Entry"; var TempGeneralPostingSetup: Record "General Posting Setup" temporary; var InventoryReportHeader: Record "Inventory Report Header"; GeneralPostingSetup: Record "General Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcValueEntries(var InventoryReportEntry: Record "Inventory Report Entry"; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDiffOnAfterCalcSumsTypeGLAccount(var InventoryReportEntry: Record "Inventory Report Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDiffOnAfterCalcSumsTypeItem(var InventoryReportEntry: Record "Inventory Report Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDiffOnBeforeCopytoInventoryReportEntry(var CalcInventoryReportEntry: Record "Inventory Report Entry"; var InventoryReportEntry: Record "Inventory Report Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownGLBeforeRunPage(var GLEntry: Record "G/L Entry"; var InvtReportEntry: Record "Inventory Report Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLInvtReportEntryBeforeCalcGLAccount(var InvtReportHeader: Record "Inventory Report Header"; var InventoryReportLine: Record "Inventory Report Entry"; var GLAcc: Record "G/L Account"; var IsHandled: Boolean; var CostAmount: Decimal; WindowPostingType: Text[80])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersOverheadAppliedActual(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersWIPInventory(var ValueEntry: Record "Value Entry"; Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownInvtToWIP(var InvtReportEntry: Record "Inventory Report Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcGLAccount(var GLAccount: Record "G/L Account"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfNoDifference(var InventoryReportLine: Record "Inventory Report Entry"; var NoDifference: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckGLClosingOverlapsOnAfterEmptyAccountingPeriodBeforeExit(var InventoryReportLine: Record "Inventory Report Entry"; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectPostings(var InventoryReportLine: Record "Inventory Report Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcGenPostingSetup(var InventoryReportEntry: Record "Inventory Report Entry")
    begin
    end;
}

