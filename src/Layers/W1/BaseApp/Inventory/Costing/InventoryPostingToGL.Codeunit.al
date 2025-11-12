// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;

codeunit 5802 "Inventory Posting To G/L"
{
    Permissions = TableData "G/L Account" = r,
                  TableData "Invt. Posting Buffer" = rimd,
                  TableData "Value Entry" = rm,
                  TableData "G/L - Item Ledger Relation" = rimd;
    TableNo = "Value Entry";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, GlobalPostPerPostGroup, IsHandled);
        if IsHandled then
            exit;

        if GlobalPostPerPostGroup then
            PostInvtPostBuf(Rec, Rec."Document No.", '', '', true)
        else
            PostInvtPostBuf(
              Rec,
              Rec."Document No.",
              Rec."External Document No.",
              CopyStr(
                StrSubstNo(Text000, Rec."Entry Type", Rec."Source No.", Rec."Posting Date"),
                1, MaxStrLen(GenJnlLine.Description)),
              false);

        OnAfterRun(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        Currency: Record Currency;
        SourceCodeSetup: Record "Source Code Setup";
        TempGlobalInvtPostingBuffer: Record "Invt. Posting Buffer" temporary;
        TempInvtPostBuf: array[20] of Record "Invt. Posting Buffer" temporary;
        TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary;
        TempGLItemLedgRelation: Record "G/L - Item Ledger Relation" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        DimMgt: Codeunit DimensionManagement;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        COGSAmt: Decimal;
        InvtAdjmtAmt: Decimal;
        DirCostAmt: Decimal;
        OvhdCostAmt: Decimal;
        VarPurchCostAmt: Decimal;
        VarMfgDirCostAmt: Decimal;
        VarMfgOvhdCostAmt: Decimal;
        WIPInvtAmt: Decimal;
        InvtAmt: Decimal;
        TotalCOGSAmt: Decimal;
        TotalInvtAdjmtAmt: Decimal;
        TotalDirCostAmt: Decimal;
        TotalOvhdCostAmt: Decimal;
        TotalVarPurchCostAmt: Decimal;
        TotalVarMfgDirCostAmt: Decimal;
        TotalVarMfgOvhdCostAmt: Decimal;
        TotalWIPInvtAmt: Decimal;
        TotalInvtAmt: Decimal;
        GlobalInvtPostBufEntryNo: Integer;
        PostBufDimNo: Integer;
        GLSetupRead: Boolean;
        SourceCodeSetupRead: Boolean;
        InvtSetupRead: Boolean;
        RunOnlyCheck: Boolean;
        RunOnlyCheckSaved: Boolean;
        CalledFromItemPosting: Boolean;
        CalledFromTestReport: Boolean;
        GlobalPostPerPostGroup: Boolean;
        GlobalJnlTemplName: Code[10];
        GlobalJnlBatchName: Code[10];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 on %3';
        Text001: Label '%1 - %2, %3,%4,%5,%6';
        Text002: Label 'The following combination %1 = %2, %3 = %4, and %5 = %6 is not allowed.';
        Text003: Label '%1 %2';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Initialize(PostPerPostGroup: Boolean)
    begin
        GlobalPostPerPostGroup := PostPerPostGroup;
        GlobalInvtPostBufEntryNo := 0;

        OnAfterInitialize(GlobalPostPerPostGroup);
    end;

    procedure SetGenJnlBatch(JnlTemplName: Code[10]; JnlBatchName: Code[10])
    begin
        GlobalJnlTemplName := JnlTemplName;
        GlobalJnlBatchName := JnlBatchName;

        OnAfterSetGenJnlBatch(GlobalJnlTemplName, GlobalJnlBatchName);
    end;

    procedure SetRunOnlyCheck(SetCalledFromItemPosting: Boolean; SetCheckOnly: Boolean; SetCalledFromTestReport: Boolean)
    begin
        CalledFromItemPosting := SetCalledFromItemPosting;
        RunOnlyCheck := SetCheckOnly;
        CalledFromTestReport := SetCalledFromTestReport;

        TempGLItemLedgRelation.Reset();
        TempGLItemLedgRelation.DeleteAll();

        OnAfterSetRunOnlyCheck(CalledFromItemPosting, RunOnlyCheck, CalledFromTestReport);
    end;

    procedure BufferInvtPosting(var ValueEntry: Record "Value Entry"): Boolean
    var
        CostToPost: Decimal;
        CostToPostACY: Decimal;
        ExpCostToPost: Decimal;
        ExpCostToPostACY: Decimal;
        PostToGL: Boolean;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferInvtPosting(ValueEntry, Result, IsHandled, RunOnlyCheck, CalledFromTestReport);
        if IsHandled then
            exit(Result);

        GetGLSetup();
        GetInvtSetup();
        if (not InvtSetup."Expected Cost Posting to G/L") and
           (ValueEntry."Expected Cost Posted to G/L" = 0) and
           ValueEntry."Expected Cost"
        then
            exit(false);

        if not (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) and
           not CalledFromTestReport
        then begin
            ValueEntry.TestField("Expected Cost", false);
            ValueEntry.TestField("Cost Amount (Expected)", 0);
            ValueEntry.TestField("Cost Amount (Expected) (ACY)", 0);
        end;

        if InvtSetup."Expected Cost Posting to G/L" then begin
            CalcCostToPost(ExpCostToPost, ValueEntry."Cost Amount (Expected)", ValueEntry."Expected Cost Posted to G/L", PostToGL);
            CalcCostToPost(ExpCostToPostACY, ValueEntry."Cost Amount (Expected) (ACY)", ValueEntry."Exp. Cost Posted to G/L (ACY)", PostToGL);
        end;
        CalcCostToPost(CostToPost, ValueEntry."Cost Amount (Actual)", ValueEntry."Cost Posted to G/L", PostToGL);
        CalcCostToPost(CostToPostACY, ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Cost Posted to G/L (ACY)", PostToGL);
        OnAfterCalcCostToPostFromBuffer(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, PostToGL);
        PostBufDimNo := 0;

        RunOnlyCheckSaved := RunOnlyCheck;
        if not PostToGL then
            exit(false);

        OnBeforeBufferPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);

        case ValueEntry."Item Ledger Entry Type" of
            ValueEntry."Item Ledger Entry Type"::Purchase:
                BufferPurchPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
            ValueEntry."Item Ledger Entry Type"::Sale:
                BufferSalesPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
            ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.",
            ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
            ValueEntry."Item Ledger Entry Type"::Transfer:
                BufferAdjmtPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
            ValueEntry."Item Ledger Entry Type"::Consumption:
                BufferConsumpPosting(ValueEntry, CostToPost, CostToPostACY);
            ValueEntry."Item Ledger Entry Type"::Output:
                BufferOutputPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
            ValueEntry."Item Ledger Entry Type"::"Assembly Consumption":
                BufferAsmConsumpPosting(ValueEntry, CostToPost, CostToPostACY);
            ValueEntry."Item Ledger Entry Type"::"Assembly Output":
                BufferAsmOutputPosting(ValueEntry, CostToPost, CostToPostACY);
            ValueEntry."Item Ledger Entry Type"::" ":
                BufferCapacityPosting(ValueEntry, CostToPost, CostToPostACY);
            else
                ErrorNonValidCombination(ValueEntry);
        end;

        OnAfterBufferPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);

        if UpdateGlobalInvtPostBuf(ValueEntry."Entry No.") then
            exit(true);
        exit(CalledFromTestReport);
    end;

    procedure AdjustPostedWIPForProduction(ValueEntry: Record "Value Entry"): Boolean
    begin
        AdjustWIPForProduction(ValueEntry, ValueEntry."Cost Posted to G/L", ValueEntry."Cost Posted to G/L (ACY)");
        if UpdateGlobalInvtPostBuf(ValueEntry."Entry No.") then
            exit(true);
    end;

    local procedure BufferPurchPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferPurchPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                begin
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"Invt. Accrual (Interim)",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied",
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::"Indirect Cost":
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                  CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::Variance:
                begin
                    ValueEntry.TestField(ValueEntry."Variance Type", ValueEntry."Variance Type"::Purchase);
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Purchase Variance",
                      CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::Revaluation:
                begin
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"Invt. Accrual (Interim)",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;

        OnAfterBufferPurchPosting(TempInvtPostBuf, ValueEntry, PostBufDimNo);
    end;

    local procedure BufferSalesPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferSalesPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                begin
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::COGS,
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::Revaluation:
                begin
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;

        OnAfterBufferSalesPosting(TempInvtPostBuf, ValueEntry, PostBufDimNo);
    end;

    local procedure BufferOutputPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferOutputPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                begin
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::"Direct Cost - Non Inventory":
                if (CostToPost <> 0) or (CostToPostACY <> 0) then
                    if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Non-Inventory Applied",
                          CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::"Indirect Cost":
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                  CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::Variance:
                case ValueEntry."Variance Type" of
                    ValueEntry."Variance Type"::Material:
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Material Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::"Material - Non Inventory":
                        if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Material - Non Inventory Variance",
                              CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::Capacity:
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Capacity Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::Subcontracted:
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Subcontracted Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::"Capacity Overhead":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Cap. Overhead Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::"Manufacturing Overhead":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Mfg. Overhead Variance",
                          CostToPost, CostToPostACY, false);
                    else
                        ErrorNonValidCombination(ValueEntry);
                end;
            ValueEntry."Entry Type"::Revaluation:
                begin
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;

        OnAfterBufferOutputPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
    end;

    local procedure BufferConsumpPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferConsumpPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                begin
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                      CostToPost, CostToPostACY, false);

                    AdjustWIPForProduction(ValueEntry, CostToPost, CostToPostACY);
                end;
            ValueEntry."Entry Type"::Revaluation,
              ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;

        OnAfterBufferConsumpPosting(TempInvtPostBuf, ValueEntry, PostBufDimNo, CostToPost, CostToPostACY);
    end;

    local procedure AdjustWIPForProduction(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustWIPForProduction(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Item Ledger Entry Type" of
            ValueEntry."Item Ledger Entry Type"::Consumption:
                InitInvtPostBuf(
                    ValueEntry,
                    TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                    TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                    CostToPost, CostToPostACY, false);
            ValueEntry."Item Ledger Entry Type"::" ":
                InitInvtPostBuf(
                    ValueEntry,
                    TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                    TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                    CostToPost, CostToPostACY, false);
        end;
    end;

    local procedure BufferCapacityPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferCapacityPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if not IsHandled then
            if ValueEntry."Order Type" = ValueEntry."Order Type"::Assembly then
                case ValueEntry."Entry Type" of
                    ValueEntry."Entry Type"::"Direct Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Entry Type"::"Indirect Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                          CostToPost, CostToPostACY, false);
                    else
                        ErrorNonValidCombination(ValueEntry);
                end
            else
                case ValueEntry."Entry Type" of
                    ValueEntry."Entry Type"::"Direct Cost":
                        begin
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                              TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied",
                              CostToPost, CostToPostACY, false);

                            AdjustWIPForProduction(ValueEntry, CostToPost, CostToPostACY);
                        end;
                    ValueEntry."Entry Type"::"Indirect Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                          TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                          CostToPost, CostToPostACY, false);
                    else
                        ErrorNonValidCombination(ValueEntry);
                end;

        OnAfterBufferCapacityPosting(ValueEntry, CostToPost, CostToPostACY);
    end;

    local procedure BufferAsmOutputPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferAsmOutputPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::"Indirect Cost":
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                  CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::Variance:
                case ValueEntry."Variance Type" of
                    ValueEntry."Variance Type"::Material:
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Material Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::Capacity:
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Capacity Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::Subcontracted:
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Subcontracted Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::"Capacity Overhead":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Cap. Overhead Variance",
                          CostToPost, CostToPostACY, false);
                    ValueEntry."Variance Type"::"Manufacturing Overhead":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Mfg. Overhead Variance",
                          CostToPost, CostToPostACY, false);
                    else
                        ErrorNonValidCombination(ValueEntry);
                end;
            ValueEntry."Entry Type"::Revaluation:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;
    end;

    local procedure BufferAsmConsumpPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferAsmConsumpPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            ValueEntry."Entry Type"::Revaluation,
              ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;
    end;

    local procedure BufferAdjmtPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferAdjmtPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                begin
                    // Posting adjustments to Interim accounts (Service)
                    if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                          TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)",
                          ExpCostToPost, ExpCostToPostACY, true);
                    if (CostToPost <> 0) or (CostToPostACY <> 0) then
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          CostToPost, CostToPostACY, false);
                end;
            ValueEntry."Entry Type"::Revaluation,
              ValueEntry."Entry Type"::Rounding:
                InitInvtPostBuf(
                  ValueEntry,
                  TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                  TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                  CostToPost, CostToPostACY, false);
            else
                ErrorNonValidCombination(ValueEntry);
        end;

        OnAfterBufferAdjmtPosting(TempInvtPostBuf, ValueEntry, PostBufDimNo);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" <> '' then
                Currency.Get(GLSetup."Additional Reporting Currency");
        end;
        GLSetupRead := true;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then
            InvtSetup.Get();
        InvtSetupRead := true;
    end;

    local procedure CalcCostToPost(var CostToPost: Decimal; AdjdCost: Decimal; var PostedCost: Decimal; var PostToGL: Boolean)
    begin
        CostToPost := AdjdCost - PostedCost;

        if CostToPost <> 0 then begin
            if not RunOnlyCheck then
                PostedCost := AdjdCost;
            PostToGL := true;
        end;
    end;

    procedure InitInvtPostBuf(ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean)
    begin
        OnBeforeInitInvtPostBuf(ValueEntry, AccType, BalAccType);

        InitInvtPostBufPerAccount(ValueEntry, AccType, BalAccType, CostToPost, CostToPostACY, InterimAccount, false);
        InitInvtPostBufPerAccount(ValueEntry, AccType, BalAccType, CostToPost, CostToPostACY, InterimAccount, true);

        OnAfterInitInvtPostBuf(ValueEntry);
    end;

    local procedure InitInvtPostBufPerAccount(var ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean; BalancingRecord: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitInvtPostBufPerAccount(ValueEntry, AccType, BalAccType, CostToPost, CostToPostACY, InterimAccount, BalancingRecord, IsHandled);
        if IsHandled then
            exit;

        PostBufDimNo := PostBufDimNo + 1;

        if BalancingRecord then begin
            SetAccNo(TempInvtPostBuf[PostBufDimNo], ValueEntry, BalAccType, AccType);
            SetPostBufAmounts(TempInvtPostBuf[PostBufDimNo], -CostToPost, -CostToPostACY, InterimAccount);
        end else begin
            SetAccNo(TempInvtPostBuf[PostBufDimNo], ValueEntry, AccType, BalAccType);
            SetPostBufAmounts(TempInvtPostBuf[PostBufDimNo], CostToPost, CostToPostACY, InterimAccount);
        end;

        TempInvtPostBuf[PostBufDimNo]."Dimension Set ID" := ValueEntry."Dimension Set ID";

        OnAfterInitTempInvtPostBuf(TempInvtPostBuf, ValueEntry, PostBufDimNo);
    end;

    local procedure CheckAccNo(var AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAcc(AccountNo, CalledFromItemPosting, IsHandled);
        if IsHandled then
            exit;

        if AccountNo = '' then
            exit;

        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then begin
            if CalledFromItemPosting then
                GLAccount.TestField(Blocked, false);
            if not CalledFromTestReport then
                AccountNo := '';
        end;
    end;

    local procedure SetAccNo(var InvtPostBuf: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type")
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
        IsHandled: Boolean;
    begin
        InvtPostBuf."Account No." := '';
        InvtPostBuf."Account Type" := AccType;
        InvtPostBuf."Bal. Account Type" := BalAccType;
        InvtPostBuf."Location Code" := ValueEntry."Location Code";
        InvtPostBuf."Inventory Posting Group" :=
            GetInvPostingGroupCode(ValueEntry, AccType = InvtPostBuf."Account Type"::"WIP Inventory", ValueEntry."Inventory Posting Group");
        InvtPostBuf."Gen. Bus. Posting Group" := ValueEntry."Gen. Bus. Posting Group";
        InvtPostBuf."Gen. Prod. Posting Group" := ValueEntry."Gen. Prod. Posting Group";
        InvtPostBuf."Posting Date" := ValueEntry."Posting Date";

        IsHandled := false;
        OnBeforeGetInvtPostSetup(InvtPostingSetup, InvtPostBuf."Location Code", InvtPostBuf."Inventory Posting Group", GenPostingSetup, IsHandled, InvtPostBuf);
        if not IsHandled then
            if InvtPostBuf.UseInvtPostSetup() then begin
                if CalledFromItemPosting then
                    InvtPostingSetup.Get(InvtPostBuf."Location Code", InvtPostBuf."Inventory Posting Group")
                else
                    if not InvtPostingSetup.Get(InvtPostBuf."Location Code", InvtPostBuf."Inventory Posting Group") then
                        exit;
            end else begin
                if CalledFromItemPosting then
                    GenPostingSetup.Get(InvtPostBuf."Gen. Bus. Posting Group", InvtPostBuf."Gen. Prod. Posting Group")
                else
                    if not GenPostingSetup.Get(InvtPostBuf."Gen. Bus. Posting Group", InvtPostBuf."Gen. Prod. Posting Group") then
                        exit;
                if not CalledFromTestReport then
                    GenPostingSetup.TestField(Blocked, false);
            end;

        OnSetAccNoOnAfterGetPostingSetup(InvtPostBuf, InvtPostingSetup, GenPostingSetup, ValueEntry, InvtPostBuf.UseInvtPostSetup());

        IsHandled := false;
        OnBeforeSetAccNo(InvtPostBuf, ValueEntry, AccType.AsInteger(), BalAccType.AsInteger(), CalledFromItemPosting, IsHandled);
        if not IsHandled then
            case InvtPostBuf."Account Type" of
                InvtPostBuf."Account Type"::Inventory:
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetInventoryAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Inventory Account";
                InvtPostBuf."Account Type"::"Inventory (Interim)":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetInventoryAccountInterim()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Inventory Account (Interim)";
                InvtPostBuf."Account Type"::"WIP Inventory":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetWIPAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."WIP Account";
                InvtPostBuf."Account Type"::"Material Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetMaterialVarianceAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Material Variance Account";
                InvtPostBuf."Account Type"::"Material - Non Inventory Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetMaterialNonInventoryVarianceAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Mat. Non-Inv. Variance Acc.";
                InvtPostBuf."Account Type"::"Capacity Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetCapacityVarianceAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Capacity Variance Account";
                InvtPostBuf."Account Type"::"Subcontracted Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetSubcontractedVarianceAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Subcontracted Variance Account";
                InvtPostBuf."Account Type"::"Cap. Overhead Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetCapOverheadVarianceAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Cap. Overhead Variance Account";
                InvtPostBuf."Account Type"::"Mfg. Overhead Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := InvtPostingSetup.GetMfgOverheadVarianceAccount()
                    else
                        InvtPostBuf."Account No." := InvtPostingSetup."Mfg. Overhead Variance Account";
                InvtPostBuf."Account Type"::"Inventory Adjmt.":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetInventoryAdjmtAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."Inventory Adjmt. Account";
                InvtPostBuf."Account Type"::"Direct Cost Applied":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetDirectCostAppliedAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."Direct Cost Applied Account";
                InvtPostBuf."Account Type"::"Direct Cost Non-Inventory Applied":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetDirectCostNonInvtAppliedAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."Direct Cost Non-Inv. App. Acc.";
                InvtPostBuf."Account Type"::"Overhead Applied":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetOverheadAppliedAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."Overhead Applied Account";
                InvtPostBuf."Account Type"::"Purchase Variance":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetPurchaseVarianceAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."Purchase Variance Account";
                InvtPostBuf."Account Type"::COGS:
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetCOGSAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."COGS Account";
                InvtPostBuf."Account Type"::"COGS (Interim)":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetCOGSInterimAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."COGS Account (Interim)";
                InvtPostBuf."Account Type"::"Invt. Accrual (Interim)":
                    if CalledFromItemPosting then
                        InvtPostBuf."Account No." := GenPostingSetup.GetInventoryAccrualAccount()
                    else
                        InvtPostBuf."Account No." := GenPostingSetup."Invt. Accrual Acc. (Interim)";
            end;


        OnSetAccNoOnBeforeCheckAccNo(InvtPostBuf, InvtPostingSetup, GenPostingSetup, CalledFromItemPosting, ValueEntry);
        CheckAccNo(InvtPostBuf."Account No.");

        OnAfterSetAccNo(InvtPostBuf, ValueEntry, CalledFromItemPosting);
    end;

    local procedure SetPostBufAmounts(var InvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean)
    begin
        InvtPostBuf."Interim Account" := InterimAccount;
        InvtPostBuf.Amount := CostToPost;
        InvtPostBuf."Amount (ACY)" := CostToPostACY;
    end;

    local procedure UpdateGlobalInvtPostBuf(ValueEntryNo: Integer) Result: Boolean
    var
        i: Integer;
        ShouldInsertTempGLItemLedgRelation: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateGlobalInvtPostBuf(ValueEntryNo, TempInvtPostBuf, RunOnlyCheck, CalledFromTestReport, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not CalledFromTestReport then
            for i := 1 to PostBufDimNo do
                if TempInvtPostBuf[i]."Account No." = '' then begin
                    Clear(TempInvtPostBuf);
                    exit(false);
                end;
        for i := 1 to PostBufDimNo do begin
            TempGlobalInvtPostingBuffer := TempInvtPostBuf[i];
            TempGlobalInvtPostingBuffer."Dimension Set ID" := TempInvtPostBuf[i]."Dimension Set ID";
            TempGlobalInvtPostingBuffer.Negative := (TempInvtPostBuf[i].Amount < 0) or (TempInvtPostBuf[i]."Amount (ACY)" < 0);

            UpdateReportAmounts();
            if TempGlobalInvtPostingBuffer.Find() then begin
                TempGlobalInvtPostingBuffer.Amount := TempGlobalInvtPostingBuffer.Amount + TempInvtPostBuf[i].Amount;
                TempGlobalInvtPostingBuffer."Amount (ACY)" := TempGlobalInvtPostingBuffer."Amount (ACY)" + TempInvtPostBuf[i]."Amount (ACY)";
                OnUpdateGlobalInvtPostBufOnBeforeModify(TempGlobalInvtPostingBuffer, TempInvtPostBuf[i]);
                TempGlobalInvtPostingBuffer.Modify();
            end else begin
                GlobalInvtPostBufEntryNo := GlobalInvtPostBufEntryNo + 1;
                TempGlobalInvtPostingBuffer."Entry No." := GlobalInvtPostBufEntryNo;
                TempGlobalInvtPostingBuffer.Insert();
            end;
            ShouldInsertTempGLItemLedgRelation := not (RunOnlyCheck or CalledFromTestReport);
            OnUpdateGlobalInvtPostBufOnAfterCalcShouldInsertTempGLItemLedgRelation(TempGLItemLedgRelation, TempGlobalInvtPostingBuffer, ValueEntryNo, RunOnlyCheck, CalledFromTestReport, ShouldInsertTempGLItemLedgRelation);
            if ShouldInsertTempGLItemLedgRelation then begin
                TempGLItemLedgRelation.Init();
                TempGLItemLedgRelation."G/L Entry No." := TempGlobalInvtPostingBuffer."Entry No.";
                TempGLItemLedgRelation."Value Entry No." := ValueEntryNo;
                TempGLItemLedgRelation.Insert();
                OnAfterBufferGLItemLedgRelation(TempGLItemLedgRelation, GlobalInvtPostBufEntryNo);
            end;
        end;
        Clear(TempInvtPostBuf);
        exit(true);
    end;

    local procedure UpdateReportAmounts()
    begin
        case TempGlobalInvtPostingBuffer."Account Type" of
            TempGlobalInvtPostingBuffer."Account Type"::Inventory, TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)":
                InvtAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory":
                WIPInvtAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.":
                InvtAdjmtAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Invt. Accrual (Interim)":
                InvtAdjmtAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied":
                DirCostAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied":
                OvhdCostAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Purchase Variance":
                VarPurchCostAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::COGS:
                COGSAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)":
                COGSAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Material Variance", TempGlobalInvtPostingBuffer."Account Type"::"Capacity Variance",
              TempGlobalInvtPostingBuffer."Account Type"::"Subcontracted Variance", TempGlobalInvtPostingBuffer."Account Type"::"Cap. Overhead Variance":
                VarMfgDirCostAmt += TempGlobalInvtPostingBuffer.Amount;
            TempGlobalInvtPostingBuffer."Account Type"::"Mfg. Overhead Variance":
                VarMfgOvhdCostAmt += TempGlobalInvtPostingBuffer.Amount;
        end;

        OnAfteUpdateReportAmounts(TempGlobalInvtPostingBuffer, InvtAmt, InvtAdjmtAmt, VarMfgDirCostAmt);
    end;

    local procedure ErrorNonValidCombination(ValueEntry: Record "Value Entry")
    begin
        if CalledFromTestReport then
            InsertTempInvtPostToGLTestBuf(ValueEntry)
        else
            Error(
              Text002,
              ValueEntry.FieldCaption("Item Ledger Entry Type"), ValueEntry."Item Ledger Entry Type",
              ValueEntry.FieldCaption("Entry Type"), ValueEntry."Entry Type",
              ValueEntry.FieldCaption("Expected Cost"), ValueEntry."Expected Cost")
    end;

    local procedure InsertTempInvtPostToGLTestBuf(ValueEntry: Record "Value Entry")
    begin
        TempInvtPostToGLTestBuf."Line No." := GetNextLineNo();
        TempInvtPostToGLTestBuf."Posting Date" := ValueEntry."Posting Date";
        TempInvtPostToGLTestBuf.Description := StrSubstNo(Text003, ValueEntry.TableCaption(), ValueEntry."Entry No.");
        TempInvtPostToGLTestBuf.Amount := ValueEntry."Cost Amount (Actual)";
        TempInvtPostToGLTestBuf."Value Entry No." := ValueEntry."Entry No.";
        TempInvtPostToGLTestBuf."Dimension Set ID" := ValueEntry."Dimension Set ID";
        OnInsertTempInvtPostToGLTestBufOnBeforeInsert(TempInvtPostToGLTestBuf, ValueEntry);
        TempInvtPostToGLTestBuf.Insert();
    end;

    local procedure GetNextLineNo(): Integer
    var
        InvtPostToGLTestBuffer: Record "Invt. Post to G/L Test Buffer";
        LastLineNo: Integer;
    begin
        InvtPostToGLTestBuffer := TempInvtPostToGLTestBuf;
        if TempInvtPostToGLTestBuf.FindLast() then
            LastLineNo := TempInvtPostToGLTestBuf."Line No." + 10000
        else
            LastLineNo := 10000;
        TempInvtPostToGLTestBuf := InvtPostToGLTestBuffer;
        exit(LastLineNo);
    end;

    procedure PostInvtPostBufPerEntry(var ValueEntry: Record "Value Entry")
    var
        DummyGenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostInvtPostBufPerEntry(ValueEntry, TempGlobalInvtPostingBuffer, RunOnlyCheckSaved, IsHandled);
        if IsHandled then
            exit;

        PostInvtPostBuf(
            ValueEntry,
            ValueEntry."Document No.",
            ValueEntry."External Document No.",
            CopyStr(
            StrSubstNo(Text000, ValueEntry."Entry Type", ValueEntry."Source No.", ValueEntry."Posting Date"),
            1, MaxStrLen(DummyGenJnlLine.Description)),
            false);
    end;

    procedure PostInvtPostBufPerPostGrp(DocNo: Code[20]; Desc: Text[50])
    var
        ValueEntry: Record "Value Entry";
    begin
        PostInvtPostBuf(ValueEntry, DocNo, '', Desc, true);
    end;

    local procedure PostInvtPostBuf(var ValueEntry: Record "Value Entry"; DocNo: Code[20]; ExternalDocNo: Code[35]; Desc: Text[100]; PostPerPostGrp: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TempGlobalInvtPostingBuffer.Reset();
        OnPostInvtPostBufferOnBeforeFind(TempGlobalInvtPostingBuffer, TempGLItemLedgRelation, ValueEntry);
        if not TempGlobalInvtPostingBuffer.FindSet() then
            exit;

        PostInvtPostBufInitGenJnlLine(GenJnlLine, ValueEntry, DocNo, ExternalDocNo, Desc);

        PostInvtPostBufProcessGlobalInvtPostBuf(GenJnlLine, ValueEntry, PostPerPostGrp);

        RunOnlyCheck := RunOnlyCheckSaved;
        OnPostInvtPostBufferOnAfterPostInvtPostBuf(TempGlobalInvtPostingBuffer, ValueEntry, CalledFromItemPosting, CalledFromTestReport, RunOnlyCheck, PostPerPostGrp);

        TempGlobalInvtPostingBuffer.DeleteAll();
    end;

    local procedure PostInvtPostBufInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; DocNo: Code[20]; ExternalDocNo: Code[35]; Desc: Text[100])
    begin
        GenJnlLine.Init();
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."External Document No." := ExternalDocNo;
        GenJnlLine.Description := Desc;
        GetSourceCodeSetup();
        GenJnlLine."Source Code" := SourceCodeSetup."Inventory Post Cost";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Job No." := ValueEntry."Job No.";
        GenJnlLine."Reason Code" := ValueEntry."Reason Code";
        GenJnlLine."Prod. Order No." := ValueEntry."Order No.";
        GetGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            if GlobalJnlTemplName <> '' then begin
                GenJnlLine."Journal Template Name" := GlobalJnlTemplName;
                GenJnlLine."Journal Batch Name" := GlobalJnlBatchName;
            end else begin
                GetInvtSetup();
                InvtSetup.TestField("Invt. Cost Jnl. Template Name");
                GenJnlLine."Journal Template Name" := InvtSetup."Invt. Cost Jnl. Template Name";
                GenJnlLine."Journal Batch Name" := InvtSetup."Invt. Cost Jnl. Batch Name";
            end;
        OnPostInvtPostBufOnAfterInitGenJnlLine(GenJnlLine, ValueEntry);
    end;

    local procedure PostInvtPostBufProcessGlobalInvtPostBuf(var GenJnlLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; PostPerPostGrp: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostInvtPostBufProcessGlobalInvtPostBuf(TempGlobalInvtPostingBuffer, GenJnlLine, ValueEntry, GenJnlPostLine, CalledFromItemPosting, PostPerPostGrp, IsHandled);
        if IsHandled then
            exit;

        repeat
            GenJnlLine.Validate("Posting Date", TempGlobalInvtPostingBuffer."Posting Date");
            GenJnlLine.Validate("VAT Reporting Date", ValueEntry."VAT Reporting Date");
            OnPostInvtPostBufOnBeforeSetAmt(GenJnlLine, ValueEntry, TempGlobalInvtPostingBuffer);
            if SetAmt(GenJnlLine, TempGlobalInvtPostingBuffer.Amount, TempGlobalInvtPostingBuffer."Amount (ACY)") then begin
                if PostPerPostGrp then
                    SetDesc(GenJnlLine, TempGlobalInvtPostingBuffer);
                OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetDesc(GenJnlLine, TempGlobalInvtPostingBuffer);
                GenJnlLine."Account No." := TempGlobalInvtPostingBuffer."Account No.";
                GenJnlLine."Dimension Set ID" := TempGlobalInvtPostingBuffer."Dimension Set ID";
                DimMgt.UpdateGlobalDimFromDimSetID(
                  TempGlobalInvtPostingBuffer."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code",
                  GenJnlLine."Shortcut Dimension 2 Code");
                OnPostInvtPostBufOnAfterUpdateGlobalDimFromDimSetID(GenJnlLine, TempGlobalInvtPostingBuffer);
                if not CalledFromTestReport then
                    if not RunOnlyCheck then begin
                        if not CalledFromItemPosting then
                            GenJnlPostLine.SetOverDimErr();
                        OnBeforePostInvtPostBuf(GenJnlLine, TempGlobalInvtPostingBuffer, ValueEntry, GenJnlPostLine);
                        PostGenJnlLine(GenJnlLine);
                        OnAfterPostInvtPostBuf(GenJnlLine, TempGlobalInvtPostingBuffer, ValueEntry, GenJnlPostLine);
                    end else begin
                        OnBeforeCheckInvtPostBuf(GenJnlLine, TempGlobalInvtPostingBuffer, ValueEntry, GenJnlPostLine, GenJnlCheckLine);
                        CheckGenJnlLine(GenJnlLine);
                    end
                else
                    InsertTempInvtPostToGLTestBuf(GenJnlLine, ValueEntry);
            end;
            OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetAmt(GenJnlLine);

            if not CalledFromTestReport and not RunOnlyCheck then
                CreateGLItemLedgerRelation(ValueEntry);
        until TempGlobalInvtPostingBuffer.Next() = 0;
    end;

    local procedure GetSourceCodeSetup()
    begin
        if not SourceCodeSetupRead then
            SourceCodeSetup.Get();
        SourceCodeSetupRead := true;
    end;

    local procedure SetAmt(var GenJnlLine: Record "Gen. Journal Line"; Amt: Decimal; AmtACY: Decimal) HasAmountToPost: Boolean
    begin
        GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::None;
        GenJnlLine.Validate(GenJnlLine.Amount, Amt);

        GetGLSetup();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            GenJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
            GenJnlLine."Source Currency Amount" := AmtACY;
            if (GenJnlLine.Amount = 0) and (GenJnlLine."Source Currency Amount" <> 0) then begin
                GenJnlLine."Additional-Currency Posting" :=
                  GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
                GenJnlLine.Validate(GenJnlLine.Amount, GenJnlLine."Source Currency Amount");
                GenJnlLine."Source Currency Amount" := 0;
            end;
        end;

        HasAmountToPost := (Amt <> 0) or (AmtACY <> 0);
        OnAfterSetAmt(GenJnlLine, Amt, AmtACY, HasAmountToPost);
    end;

    procedure SetDesc(var GenJnlLine: Record "Gen. Journal Line"; InvtPostBuf: Record "Invt. Posting Buffer")
    begin
        GenJnlLine.Description :=
            CopyStr(
            StrSubstNo(
                Text001,
                InvtPostBuf."Account Type", InvtPostBuf."Bal. Account Type",
                InvtPostBuf."Location Code", InvtPostBuf."Inventory Posting Group",
                InvtPostBuf."Gen. Bus. Posting Group", InvtPostBuf."Gen. Prod. Posting Group"),
            1, MaxStrLen(GenJnlLine.Description));

        OnAfterSetDesc(GenJnlLine, InvtPostBuf);
    end;

    local procedure InsertTempInvtPostToGLTestBuf(GenJnlLine: Record "Gen. Journal Line"; ValueEntry: Record "Value Entry")
    begin
        TempInvtPostToGLTestBuf.Init();
        TempInvtPostToGLTestBuf."Line No." := GetNextLineNo();
        TempInvtPostToGLTestBuf."Posting Date" := GenJnlLine."Posting Date";
        TempInvtPostToGLTestBuf."Document No." := GenJnlLine."Document No.";
        TempInvtPostToGLTestBuf.Description := GenJnlLine.Description;
        TempInvtPostToGLTestBuf."Account No." := GenJnlLine."Account No.";
        TempInvtPostToGLTestBuf.Amount := GenJnlLine.Amount;
        TempInvtPostToGLTestBuf."Source Code" := GenJnlLine."Source Code";
        TempInvtPostToGLTestBuf."System-Created Entry" := true;
        TempInvtPostToGLTestBuf."Value Entry No." := ValueEntry."Entry No.";
        TempInvtPostToGLTestBuf."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting";
        TempInvtPostToGLTestBuf."Source Currency Code" := GenJnlLine."Source Currency Code";
        TempInvtPostToGLTestBuf."Source Currency Amount" := GenJnlLine."Source Currency Amount";
        TempInvtPostToGLTestBuf."Inventory Account Type" := TempGlobalInvtPostingBuffer."Account Type";
        TempInvtPostToGLTestBuf."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        if TempGlobalInvtPostingBuffer.UseInvtPostSetup() then begin
            TempInvtPostToGLTestBuf."Location Code" := TempGlobalInvtPostingBuffer."Location Code";
            TempInvtPostToGLTestBuf."Invt. Posting Group Code" :=
              GetInvPostingGroupCode(
                ValueEntry,
                TempInvtPostToGLTestBuf."Inventory Account Type" = TempInvtPostToGLTestBuf."Inventory Account Type"::"WIP Inventory",
                TempGlobalInvtPostingBuffer."Inventory Posting Group")
        end else begin
            TempInvtPostToGLTestBuf."Gen. Bus. Posting Group" := TempGlobalInvtPostingBuffer."Gen. Bus. Posting Group";
            TempInvtPostToGLTestBuf."Gen. Prod. Posting Group" := TempGlobalInvtPostingBuffer."Gen. Prod. Posting Group";
        end;
        OnInsertTempInvtPostToGLTestBufOnBeforeTempInvtPostToGLTestBufInsert(TempInvtPostToGLTestBuf, GenJnlLine, ValueEntry);
        TempInvtPostToGLTestBuf.Insert();
    end;

    local procedure CreateGLItemLedgerRelation(var ValueEntry: Record "Value Entry")
    var
        GLRegister: Record "G/L Register";
    begin
        GenJnlPostLine.GetGLReg(GLRegister);
        if GlobalPostPerPostGroup then begin
            TempGLItemLedgRelation.Reset();
            TempGLItemLedgRelation.SetRange("G/L Entry No.", TempGlobalInvtPostingBuffer."Entry No.");
            TempGLItemLedgRelation.FindSet();
            repeat
                ValueEntry.Get(TempGLItemLedgRelation."Value Entry No.");
                UpdateValueEntry(ValueEntry);
                CreateGLItemLedgerRelationEntry(GLRegister);
            until TempGLItemLedgRelation.Next() = 0;
        end else begin
            UpdateValueEntry(ValueEntry);
            CreateGLItemLedgerRelationEntry(GLRegister);
        end;
    end;

    local procedure CreateGLItemLedgerRelationEntry(GLRegister: Record "G/L Register")
    var
        GLItemLedgerRelation: Record "G/L - Item Ledger Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateGLItemLedgerRelationEntry(GLRegister, IsHandled);
        if IsHandled then
            exit;

        GLItemLedgerRelation.Init();
        GLItemLedgerRelation."G/L Entry No." := GLRegister."To Entry No.";
        GLItemLedgerRelation."Value Entry No." := TempGLItemLedgRelation."Value Entry No.";
        GLItemLedgerRelation."G/L Register No." := GLRegister."No.";
        OnBeforeGLItemLedgRelationInsert(GLItemLedgerRelation, TempGlobalInvtPostingBuffer, GLRegister, TempGLItemLedgRelation);
        GLItemLedgerRelation.Insert();
        OnAfterGLItemLedgRelationInsert();
        TempGLItemLedgRelation."G/L Entry No." := TempGlobalInvtPostingBuffer."Entry No.";
        TempGLItemLedgRelation.Delete();
    end;

    local procedure UpdateValueEntry(var ValueEntry: Record "Value Entry")
    begin
        if TempGlobalInvtPostingBuffer."Interim Account" then begin
            ValueEntry."Expected Cost Posted to G/L" := ValueEntry."Cost Amount (Expected)";
            ValueEntry."Exp. Cost Posted to G/L (ACY)" := ValueEntry."Cost Amount (Expected) (ACY)";
        end else begin
            ValueEntry."Cost Posted to G/L" := ValueEntry."Cost Amount (Actual)";
            ValueEntry."Cost Posted to G/L (ACY)" := ValueEntry."Cost Amount (Actual) (ACY)";
        end;
        OnUpdateValueEntryOnBeforeModify(ValueEntry, TempGlobalInvtPostingBuffer);
        if not CalledFromItemPosting then
            ValueEntry.Modify();
    end;

    procedure GetTempInvtPostToGLTestBuf(var InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer")
    begin
        InvtPostToGLTestBuf.DeleteAll();
        if not TempInvtPostToGLTestBuf.FindSet() then
            exit;

        repeat
            InvtPostToGLTestBuf := TempInvtPostToGLTestBuf;
            InvtPostToGLTestBuf.Insert();
        until TempInvtPostToGLTestBuf.Next() = 0;
    end;

    procedure GetAmtToPost(var NewCOGSAmt: Decimal; var NewInvtAdjmtAmt: Decimal; var NewDirCostAmt: Decimal; var NewOvhdCostAmt: Decimal; var NewVarPurchCostAmt: Decimal; var NewVarMfgDirCostAmt: Decimal; var NewVarMfgOvhdCostAmt: Decimal; var NewWIPInvtAmt: Decimal; var NewInvtAmt: Decimal; GetTotal: Boolean)
    begin
        GetAmt(NewInvtAdjmtAmt, InvtAdjmtAmt, TotalInvtAdjmtAmt, GetTotal);
        GetAmt(NewDirCostAmt, DirCostAmt, TotalDirCostAmt, GetTotal);
        GetAmt(NewOvhdCostAmt, OvhdCostAmt, TotalOvhdCostAmt, GetTotal);
        GetAmt(NewVarPurchCostAmt, VarPurchCostAmt, TotalVarPurchCostAmt, GetTotal);
        GetAmt(NewVarMfgDirCostAmt, VarMfgDirCostAmt, TotalVarMfgDirCostAmt, GetTotal);
        GetAmt(NewVarMfgOvhdCostAmt, VarMfgOvhdCostAmt, TotalVarMfgOvhdCostAmt, GetTotal);
        GetAmt(NewWIPInvtAmt, WIPInvtAmt, TotalWIPInvtAmt, GetTotal);
        GetAmt(NewCOGSAmt, COGSAmt, TotalCOGSAmt, GetTotal);
        GetAmt(NewInvtAmt, InvtAmt, TotalInvtAmt, GetTotal);
    end;

    local procedure GetAmt(var NewAmt: Decimal; var Amt: Decimal; var TotalAmt: Decimal; GetTotal: Boolean)
    begin
        if GetTotal then
            NewAmt := TotalAmt
        else begin
            NewAmt := Amt;
            TotalAmt := TotalAmt + Amt;
            Amt := 0;
        end;
    end;

    procedure GetInvtPostBuf(var InvtPostBuf: Record "Invt. Posting Buffer")
    begin
        InvtPostBuf.DeleteAll();

        TempGlobalInvtPostingBuffer.Reset();
        if TempGlobalInvtPostingBuffer.FindSet() then
            repeat
                InvtPostBuf := TempGlobalInvtPostingBuffer;
                InvtPostBuf.Insert();
            until TempGlobalInvtPostingBuffer.Next() = 0;
    end;

    local procedure GetInvPostingGroupCode(ValueEntry: Record "Value Entry"; WIPInventory: Boolean; InvPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        if WIPInventory then begin
            OnBeforeGetInvPostingGroupCode(ValueEntry, InvPostingGroupCode, IsHandled);
            if IsHandled then
                exit(InvPostingGroupCode);
            if (ValueEntry."Source Type" = ValueEntry."Source Type"::Item) and (ValueEntry."Source No." <> ValueEntry."Item No.") then begin
                Item.SetLoadFields("Inventory Posting Group");
                if Item.Get(ValueEntry."Source No.") then
                    exit(Item."Inventory Posting Group");
            end;
        end;

        exit(InvPostingGroupCode);
    end;

    procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlCheckLine.RunCheck(GenJnlLine);
    end;

    procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBufferCapacityPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBufferConsumpPosting(var TempInvtPostingBuffer: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; var PostBufDimNo: Integer; var CostToPost: Decimal; var CostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBufferOutputPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferSalesPosting(var TempInvtPostingBuffer: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; var PostBufDimNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCostToPostFromBuffer(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal; var PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGLItemLedgRelationInsert()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitInvtPostBuf(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitTempInvtPostBuf(var TempInvtPostBuf: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; PostBufDimNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAccNo(var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; CalledFromItemPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDesc(var GenJnlLine: Record "Gen. Journal Line"; var InvtPostBuf: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmt(var GenJnlLine: Record "Gen. Journal Line"; Amt: Decimal; AmtACY: Decimal; var HasAmountToPost: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferAdjmtPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBufferInvtPosting(var ValueEntry: Record "Value Entry"; var Result: Boolean; var IsHandled: Boolean; RunOnlyCheck: Boolean; CalledFromTestReport: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferOutputPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBufferPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferPurchPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferSalesPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var AccountNo: Code[20]; CalledFromItemPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvPostingGroupCode(var ValueEntry: Record "Value Entry"; var InvPostingGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitInvtPostBuf(var ValueEntry: Record "Value Entry"; var AccType: Enum "Invt. Posting Buffer Account Type"; var BalAccType: Enum "Invt. Posting Buffer Account Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitInvtPostBufPerAccount(var ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean; BalancingRecord: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvtPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvtPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvtPostSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; var LocationCode: Code[10]; InventoryPostingGroup: Code[20]; var GenPostingSetup: Record "General Posting Setup"; var IsHandled: Boolean; var InvtPostingBuffer: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLItemLedgRelationInsert(var GLItemLedgerRelation: Record "G/L - Item Ledger Relation"; InvtPostingBuffer: Record "Invt. Posting Buffer"; GLRegister: Record "G/L Register"; TempGLItemLedgerRelation: Record "G/L - Item Ledger Relation" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvtPostBufProcessGlobalInvtPostBuf(var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var GenJnlLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CalledFromItemPosting: Boolean; PostPerPostGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAccNo(var InvtPostBuf: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; AccType: Option; BalAccType: Option; CalledFromItemPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ValueEntry: Record "Value Entry"; PostPerPostGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempInvtPostToGLTestBufOnBeforeInsert(var TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempInvtPostToGLTestBufOnBeforeTempInvtPostToGLTestBufInsert(var TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary; GenJournalLine: Record "Gen. Journal Line"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostInvtPostBufferOnBeforeFind(var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; var TempGLItemLedgRelation: Record "G/L - Item Ledger Relation"; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufferOnAfterPostInvtPostBuf(var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; var ValueEntry: Record "Value Entry"; CalledFromItemPosting: Boolean; CalledFromTestReport: Boolean; RunOnlyCheck: Boolean; PostPerPostGrp: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufOnAfterUpdateGlobalDimFromDimSetID(var GenJournalLine: Record "Gen. Journal Line"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufOnBeforeSetAmt(var GenJournalLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; var GlobalInvtPostingBuffer: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetAmt(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetDesc(var GenJournalLine: Record "Gen. Journal Line"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAccNoOnAfterGetPostingSetup(var InvtPostBuf: Record "Invt. Posting Buffer"; var InvtPostingSetup: Record "Inventory Posting Setup"; var GenPostingSetup: Record "General Posting Setup"; ValueEntry: Record "Value Entry"; UseInvtPostSetup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAccNoOnBeforeCheckAccNo(var InvtPostBuf: Record "Invt. Posting Buffer"; InvtPostingSetup: Record "Inventory Posting Setup"; GenPostingSetup: Record "General Posting Setup"; CalledFromItemPosting: Boolean; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGlobalInvtPostBufOnBeforeModify(var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; TempInvtPostBuf: Record "Invt. Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGlobalInvtPostBufOnAfterCalcShouldInsertTempGLItemLedgRelation(var TempGLItemLedgerRelation: Record "G/L - Item Ledger Relation" temporary; TempInvtPostingBuffer: Record "Invt. Posting Buffer" temporary; ValueEntryNo: Integer; RunOnlyCheck: Boolean; CalledFromTestReport: Boolean; var ShouldInsertTempGLItemLedgRelation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferGLItemLedgRelation(var TempGLItemLedgRelation: Record "G/L - Item Ledger Relation" temporary; GlobalInvtPostBufEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateValueEntryOnBeforeModify(var ValueEntry: Record "Value Entry"; InvtPostingBuffer: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferConsumpPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; CostToPost: Decimal; CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfteUpdateReportAmounts(var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var InvtAmt: Decimal; var InvtAdjmtAmt: Decimal; var VarMfgDirCostAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferAsmOutputPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var CostToPost: Decimal; var CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferAsmConsumpPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var CostToPost: Decimal; var CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvtPostBufPerEntry(var ValueEntry: Record "Value Entry"; var TempGlobalInvtPostingBuffer: Record "Invt. Posting Buffer" temporary; RunOnlyCheckSaved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlBatch(GlobalJnlTemplName: Code[10]; GlobalJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRunOnlyCheck(CalledFromItemPosting: Boolean; RunOnlyCheck: Boolean; CalledFromTestReport: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(GlobalPostPerPostGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferAdjmtPosting(var TempInvtPostingBuffer: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; var PostBufDimNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferPurchPosting(var TempInvtPostingBuffer: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; var PostBufDimNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferCapacityPosting(var ValueEntry: Record "Value Entry"; var TempGlobalInvtPostingBuffer: Record "Invt. Posting Buffer" temporary; CostToPost: Decimal; CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLItemLedgerRelationEntry(var GLRegister: Record "G/L Register"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAdjustWIPForProduction(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; CostToPost: Decimal; CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGlobalInvtPostBuf(ValueEntryNo: Integer; var TempInvtPostBuf: array[20] of Record "Invt. Posting Buffer" temporary; RunOnlyCheck: Boolean; CalledFromTestReport: Boolean; Result: Boolean; IsHandled: Boolean)
    begin
    end;
}

