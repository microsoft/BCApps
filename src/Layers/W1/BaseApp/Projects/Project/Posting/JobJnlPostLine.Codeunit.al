// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Posting;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Posting;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Journal;
using Microsoft.Foundation.NoSeries;

codeunit 1012 "Job Jnl.-Post Line"
{
    Permissions = TableData "Job Ledger Entry" = rimd,
                  TableData "Job Register" = rimd,
                  TableData Job = rimd,
                  TableData "Value Entry" = rimd;
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        Cust: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        JobJnlLine2: Record "Job Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        JobReg: Record "Job Register";
        JobsSetup: Record "Jobs Setup";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        Location: Record Location;
        Item: Record Item;
        JobJnlCheckLine: Codeunit "Job Jnl.-Check Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        JobPostLine: Codeunit "Job Post-Line";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        AsmPost: Codeunit "Assembly-Post";
        GLSetupRead: Boolean;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromPurchase: Boolean;
        NextEntryNo: Integer;
        GLEntryNo: Integer;
        AssemblyPostProgressMsg: Label '#1#################################\\Posting Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        Format4Lbl: Label '%1 %2 %3 %4', Comment = '%1 = Job No., %2 = Job Task No., %3 = Job Planning Line No., %4 = Line No.';
        Format2Lbl: Label '%1 %2', Comment = 'Assemble %1 = Document Type, %2 = No.';

    procedure RunWithCheck(var JobJnlLine2: Record "Job Journal Line"): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        JobLedgEntryNo: Integer;
    begin
        OnBeforeRunWithCheck(JobJnlLine2);

        if JobReg."No." = 0 then
            SequenceNoMgt.ClearSequenceNoCheck();
        JobJnlLine.Copy(JobJnlLine2);
        JobLedgEntryNo := Code(true);
        JobJnlLine2 := JobJnlLine;
        exit(JobLedgEntryNo);
    end;

    local procedure "Code"(CheckLine: Boolean): Integer
    var
        JobLedgEntryNo: Integer;
        ShouldPostUsage: Boolean;
        xNextEntryNo: Integer;
    begin
        OnBeforeCode(JobJnlLine);

        GetGLSetup();

        if JobJnlLine.EmptyLine() then
            exit;

        OnCodeOnBeforeCheckLine(JobJnlLine, CalledFromInvtPutawayPick, CheckLine);
        if CheckLine then begin
            JobJnlCheckLine.SetCalledFromInvtPutawayPick(CalledFromInvtPutawayPick);
            JobJnlCheckLine.SetCalledFromPurchase(CalledFromPurchase);
            JobJnlCheckLine.RunCheck(JobJnlLine);
        end;

        GetNextEntryNo();

        if JobJnlLine."Document Date" = 0D then
            JobJnlLine."Document Date" := JobJnlLine."Posting Date";

        OnBeforeCreateJobRegister(JobJnlLine);

        GetAndCheckJob();

        JobJnlLine2 := JobJnlLine;

        OnAfterCopyJobJnlLine(JobJnlLine, JobJnlLine2);

        JobJnlLine2."Source Currency Total Cost" := 0;
        JobJnlLine2."Source Currency Total Price" := 0;
        JobJnlLine2."Source Currency Line Amount" := 0;

        GetGLSetup();
        if (GLSetup."Additional Reporting Currency" <> '') and
            (JobJnlLine2."Source Currency Code" <> GLSetup."Additional Reporting Currency")
        then
            UpdateJobJnlLineSourceCurrencyAmounts(JobJnlLine2);

        PostATO(JobJnlLine2);

        ShouldPostUsage := JobJnlLine2."Entry Type" = JobJnlLine2."Entry Type"::Usage;
        OnCodeOnAfterCalcShouldPostUsage(JobJnlLine2, ShouldPostUsage, JobLedgEntryNo);
        if ShouldPostUsage then
            case JobJnlLine.Type of
                JobJnlLine.Type::Resource:
                    JobLedgEntryNo := PostResource(JobJnlLine2);
                JobJnlLine.Type::Item:
                    JobLedgEntryNo := PostItem(JobJnlLine);
                JobJnlLine.Type::"G/L Account":
                    JobLedgEntryNo := CreateJobLedgEntry(JobJnlLine2);
            end
        else
            JobLedgEntryNo := CreateJobLedgEntry(JobJnlLine2);

        xNextEntryNo := NextEntryNo;
        OnAfterRunCode(JobJnlLine2, JobLedgEntryNo, JobReg, NextEntryNo);
        ValidateSequenceNo(NextEntryNo, xNextEntryNo, Database::"Job Ledger Entry");

        exit(JobLedgEntryNo);
    end;

    local procedure GetNextEntryNo()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextEntryNo(JobJnlLine, NextEntryNo, IsHandled, JobLedgerEntry);
        if not IsHandled then
            if (JobLedgerEntry."Entry No." = 0) and JobsSetup.UseLegacyPosting() then begin
                JobLedgerEntry.LockTable();
                NextEntryNo := JobLedgerEntry.GetLastEntryNo() + 1;
            end;
        OnAfterGetNextEntryNo(JobLedgerEntry, NextEntryNo);
    end;

    local procedure InsertRegister(JobLedgEntryNo: Integer)
    begin
        if JobReg."No." = 0 then begin
            JobReg."No." := JobReg.GetNextEntryNo(JobsSetup.UseLegacyPosting());
            JobReg.Init();
            JobReg."From Entry No." := NextEntryNo;
            JobReg."To Entry No." := NextEntryNo;
            JobReg."Creation Date" := Today;
            JobReg."Creation Time" := Time;
            JobReg."Source Code" := JobJnlLine."Source Code";
            JobReg."Journal Batch Name" := JobJnlLine."Journal Batch Name";
            JobReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobReg."User ID"));
            OnIsertJobRegisterOnBeforeInsert(JobJnlLine, JobReg);
            JobReg.Insert();
        end else begin
            if ((JobLedgEntryNo < JobReg."From Entry No.") and (JobLedgEntryNo <> 0)) or
               ((JobReg."From Entry No." = 0) and (JobLedgEntryNo > 0))
            then
                JobReg."From Entry No." := JobLedgEntryNo;
            if JobLedgEntryNo > JobReg."To Entry No." then
                JobReg."To Entry No." := JobLedgEntryNo;
            JobReg.Modify();
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Res. Ledger Entry", 'r')]
    local procedure ValidateSequenceNo(LedgEntryNo: Integer; xLedgEntryNo: Integer; TableNo: Integer)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if LedgEntryNo = xLedgEntryNo then
            exit;
        if JobsSetup.UseLegacyPosting() then
            exit;
        SequenceNoMgt.ValidateSeqNo(TableNo);
    end;

    local procedure GetAndCheckJob()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAndCheckJob(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        Job.Get(JobJnlLine."Job No.");
        CheckJob(JobJnlLine, Job);
    end;

    internal procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    internal procedure SetCalledFromPurchase(NewCalledFromPurchase: Boolean)
    begin
        CalledFromPurchase := NewCalledFromPurchase;
    end;

    local procedure CheckJob(var JobJnlLine: Record "Job Journal Line"; Job: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJob(JobJnlLine, Job, IsHandled, JobReg, NextEntryNo);
        if IsHandled then
            exit;

        Job.TestBlocked();
        Job.TestField("Bill-to Customer No.");
        Cust.Get(Job."Bill-to Customer No.");
        JobJnlLine.TestField("Currency Code", Job."Currency Code");
        IsHandled := false;
        OnCheckJobOnBeforeTestJobTaskType(JobJnlLine, IsHandled);
        if not IsHandled then begin
            JobTask.Get(JobJnlLine."Job No.", JobJnlLine."Job Task No.");
            JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure CreateJobLedgEntry(JobJnlLine2: Record "Job Journal Line"): Integer
    var
        ResLedgEntry: Record "Res. Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTransferLine: Codeunit "Job Transfer Line";
        JobLinkUsage: Codeunit "Job Link Usage";
        JobLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJobLedgEntry(JobJnlLine2, IsHandled, JobLedgEntryNo);
        if IsHandled then
            exit(JobLedgEntryNo);

        SetCurrency(JobJnlLine2);

        if not JobsSetup.UseLegacyPosting() then
            NextEntryNo := JobLedgEntry.GetNextEntryNo();

        JobLedgEntry.Init();
        JobTransferLine.FromJnlLineToLedgEntry(JobJnlLine2, JobLedgEntry);

        IsHandled := false;
        OnCreateJobLedgEntryOnBeforeAssignQtyCostPrice(JobLedgEntry, JobJnlLine2, IsHandled);
        if not IsHandled then
            if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Sale then begin
                JobLedgEntry.Quantity := -JobJnlLine2.Quantity;
                JobLedgEntry."Quantity (Base)" := -JobJnlLine2."Quantity (Base)";
                JobLedgEntry."Total Cost (LCY)" := -JobJnlLine2."Total Cost (LCY)";
                JobLedgEntry."Total Cost" := -JobJnlLine2."Total Cost";
                JobLedgEntry."Total Price (LCY)" := -JobJnlLine2."Total Price (LCY)";
                JobLedgEntry."Total Price" := -JobJnlLine2."Total Price";
                JobLedgEntry."Line Amount (LCY)" := -JobJnlLine2."Line Amount (LCY)";
                JobLedgEntry."Line Amount" := -JobJnlLine2."Line Amount";
                JobLedgEntry."Line Discount Amount (LCY)" := -JobJnlLine2."Line Discount Amount (LCY)";
                JobLedgEntry."Line Discount Amount" := -JobJnlLine2."Line Discount Amount";
            end else begin
                JobLedgEntry.Quantity := JobJnlLine2.Quantity;
                JobLedgEntry."Quantity (Base)" := JobJnlLine2."Quantity (Base)";
                JobLedgEntry."Total Cost (LCY)" := JobJnlLine2."Total Cost (LCY)";
                JobLedgEntry."Total Cost" := JobJnlLine2."Total Cost";
                JobLedgEntry."Total Price (LCY)" := JobJnlLine2."Total Price (LCY)";
                JobLedgEntry."Total Price" := JobJnlLine2."Total Price";
                JobLedgEntry."Line Amount (LCY)" := JobJnlLine2."Line Amount (LCY)";
                JobLedgEntry."Line Amount" := JobJnlLine2."Line Amount";
                JobLedgEntry."Line Discount Amount (LCY)" := JobJnlLine2."Line Discount Amount (LCY)";
                JobLedgEntry."Line Discount Amount" := JobJnlLine2."Line Discount Amount";
            end;

        JobLedgEntry."Additional-Currency Total Cost" := -JobLedgEntry."Additional-Currency Total Cost";
        JobLedgEntry."Add.-Currency Total Price" := -JobLedgEntry."Add.-Currency Total Price";
        JobLedgEntry."Add.-Currency Line Amount" := -JobLedgEntry."Add.-Currency Line Amount";

        JobLedgEntry."Entry No." := NextEntryNo;
        JobLedgEntry."No. Series" := JobJnlLine2."Posting No. Series";
        JobLedgEntry."Original Unit Cost (LCY)" := JobLedgEntry."Unit Cost (LCY)";
        JobLedgEntry."Original Total Cost (LCY)" := JobLedgEntry."Total Cost (LCY)";
        JobLedgEntry."Original Unit Cost" := JobLedgEntry."Unit Cost";
        JobLedgEntry."Original Total Cost" := JobLedgEntry."Total Cost";
        JobLedgEntry."Original Total Cost (ACY)" := JobLedgEntry."Additional-Currency Total Cost";
        JobLedgEntry."Dimension Set ID" := JobJnlLine2."Dimension Set ID";

        case JobJnlLine2.Type of
            JobJnlLine2.Type::Resource:
                if JobJnlLine2."Entry Type" = JobJnlLine2."Entry Type"::Usage then
                    if ResLedgEntry.FindLast() then begin
                        JobLedgEntry."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type"::Resource;
                        JobLedgEntry."Ledger Entry No." := ResLedgEntry."Entry No.";
                    end;
            JobJnlLine2.Type::Item:
                begin
                    JobLedgEntry."Ledger Entry Type" := JobJnlLine2."Ledger Entry Type"::Item;
                    JobLedgEntry."Ledger Entry No." := JobJnlLine2."Ledger Entry No.";
                    JobLedgEntry.CopyTrackingFromJobJnlLine(JobJnlLine2);
                end;
            JobJnlLine2.Type::"G/L Account":
                begin
                    JobLedgEntry."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type"::" ";
                    if GLEntryNo > 0 then begin
                        JobLedgEntry."Ledger Entry Type" := JobLedgEntry."Ledger Entry Type"::"G/L Account";
                        JobLedgEntry."Ledger Entry No." := GLEntryNo;
                        GLEntryNo := 0;
                    end;
                end;
        end;

        OnCreateJobLedgerEntryOnAfterAssignLedgerEntryTypeAndNo(JobLedgEntry, JobJnlLine2, GLEntryNo);

        if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Sale then
            JobLedgEntry.CopyTrackingFromJobJnlLine(JobJnlLine2);

        InsertRegister(JobLedgEntry."Entry No.");
        JobLedgEntry."Job Register No." := JobReg."No.";
        OnBeforeJobLedgEntryInsert(JobLedgEntry, JobJnlLine2);
        JobLedgEntry.Insert(true);
        OnAfterJobLedgEntryInsert(JobLedgEntry, JobJnlLine2);

        JobLedgEntryNo := JobLedgEntry."Entry No.";
        IsHandled := false;
        OnBeforeApplyUsageLink(JobLedgEntry, JobJnlLine2, IsHandled);
        if not IsHandled then
            if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Usage then begin
                // Usage Link should be applied if it is enabled for the job,
                // if a Job Planning Line number is defined or if it is enabled for a Job Planning Line.
                Job.Get(JobLedgEntry."Job No.");
                if Job."Apply Usage Link" or
                   (JobJnlLine2."Job Planning Line No." <> 0) or
                   JobLinkUsage.FindMatchingJobPlanningLine(JobPlanningLine, JobLedgEntry)
                then
                    JobLinkUsage.ApplyUsage(JobLedgEntry, JobJnlLine2, CalledFromInvtPutawayPick)
                else
                    JobPostLine.InsertPlLineFromLedgEntry(JobLedgEntry)
            end;

        if JobsSetup.UseLegacyPosting() then
            NextEntryNo := NextEntryNo + 1;
        OnAfterApplyUsageLink(JobLedgEntry);

        exit(JobLedgEntryNo);
    end;

    local procedure CreateJobLedgEntryFromPostItem(JobJournalLine: Record "Job Journal Line"; ValueEntry: Record "Value Entry"): Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJobLedgEntryFromPostItem(JobJournalLine, ValueEntry, IsHandled);
        if IsHandled then
            exit(0);

        exit(CreateJobLedgEntry(JobJournalLine))
    end;

    local procedure SetCurrency(JobJnlLine: Record "Job Journal Line")
    begin
        if JobJnlLine."Currency Code" = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision()
        end else begin
            Currency.Get(JobJnlLine."Currency Code");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
    end;

    local procedure PostItem(var JobJnlLine: Record "Job Journal Line") JobLedgEntryNo: Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        JobLedgEntry2: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemJnlLine2: Record "Item Journal Line";
        JobJnlLineReserve: Codeunit "Job Jnl. Line-Reserve";
        SkipJobLedgerEntry: Boolean;
        ApplyToJobContractEntryNo: Boolean;
        TempRemainingQty: Decimal;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        RemainingQtyToTrack: Decimal;
        IsHandled: Boolean;
    begin
        if not JobJnlLine."Job Posting Only" then begin
            IsHandled := false;
            OnBeforeItemPosting(JobJnlLine2, NextEntryNo, IsHandled);
            if not IsHandled then begin
                InitItemJnlLine();

                //Do not transfer remaining quantity when posting from Inventory Pick as the entry is created during posting process of Item through Item Jnl Line.
                JobJnlLineReserve.TransJobJnlLineToItemJnlLine(JobJnlLine2, ItemJnlLine, ItemJnlLine."Quantity (Base)", CalledFromInvtPutawayPick);

                ApplyToJobContractEntryNo := false;
                if JobPlanningLine.Get(JobJnlLine."Job No.", JobJnlLine."Job Task No.", JobJnlLine."Job Planning Line No.") then
                    ApplyToJobContractEntryNo := true
                else
                    if JobPlanningReservationExists(JobJnlLine2."No.", JobJnlLine2."Job No.") then
                        if ApplyToMatchingJobPlanningLine(JobJnlLine2, JobPlanningLine) then
                            ApplyToJobContractEntryNo := true;

                if ApplyToJobContractEntryNo then
                    ItemJnlLine."Job Contract Entry No." := JobPlanningLine."Job Contract Entry No.";

                OnPostItemOnBeforeAssignItemJnlLine(JobJnlLine, JobJnlLine2, ItemJnlLine, JobPlanningLine);

                ItemJnlLine2 := ItemJnlLine;
                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification);

                if JobJnlLine.IsInventoriableItem() then begin
                    PostWhseJnlLine(ItemJnlLine2, ItemJnlLine2.Quantity, ItemJnlLine2."Quantity (Base)", TempTrackingSpecification);
                    OnPostItemOnAfterPostWhseJnlLine(JobJnlLine2, ItemJnlPostLine);
                end;
            end;
        end;

        OnPostItemOnBeforeGetJobConsumptionValueEntry(JobJnlLine, NextEntryNo);
        if GetJobConsumptionValueEntry(ValueEntry, JobJnlLine) then begin
            RemainingAmount := JobJnlLine2."Line Amount";
            RemainingAmountLCY := JobJnlLine2."Line Amount (LCY)";
            RemainingQtyToTrack := JobJnlLine2.Quantity;
            repeat
                SkipJobLedgerEntry := false;
                if ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    JobLedgEntry2.SetRange("Ledger Entry Type", JobLedgEntry2."Ledger Entry Type"::Item);
                    JobLedgEntry2.SetRange("Ledger Entry No.", ItemLedgEntry."Entry No.");
                    // The following code is only to secure that JLEs created at receipt in version 6.0 or earlier,
                    // are not created again at point of invoice (6.0 SP1 and newer).
                    if JobLedgEntry2.FindFirst() and (JobLedgEntry2.Quantity = -ItemLedgEntry.Quantity) then
                        SkipJobLedgerEntry := true
                    else begin
                        JobJnlLine2.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                        OnPostItemOnAfterApplyItemTracking(JobJnlLine2, ItemLedgEntry, JobLedgEntry2, SkipJobLedgerEntry);
                    end;
                end;
                OnPostItemOnAfterSetSkipJobLedgerEntry(JobJnlLine2, ItemLedgEntry, SkipJobLedgerEntry);
                if not SkipJobLedgerEntry then begin
                    TempRemainingQty := JobJnlLine2."Remaining Qty.";
                    JobJnlLine2.Quantity := -ValueEntry."Invoiced Quantity" / JobJnlLine."Qty. per Unit of Measure";
                    JobJnlLine2."Quantity (Base)" :=
                        Round(JobJnlLine2.Quantity * JobJnlLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    Currency.Initialize(JobJnlLine."Currency Code");

                    OnPostItemOnBeforeUpdateTotalAmounts(JobJnlLine2, ItemLedgEntry, ValueEntry);

                    UpdateJobJnlLineTotalAmounts(JobJnlLine2, Currency."Amount Rounding Precision");
                    UpdateJobJnlLineAmount(
                        JobJnlLine2, RemainingAmount, RemainingAmountLCY, RemainingQtyToTrack, Currency."Amount Rounding Precision");

                    JobJnlLine2.Validate("Remaining Qty.", TempRemainingQty);
                    JobJnlLine2."Ledger Entry Type" := JobJnlLine."Ledger Entry Type"::Item;
                    JobJnlLine2."Ledger Entry No." := ValueEntry."Item Ledger Entry No.";
                    JobLedgEntryNo := CreateJobLedgEntryFromPostItem(JobJnlLine2, ValueEntry);
                    ValueEntry."Job Ledger Entry No." := JobLedgEntryNo;
                    ModifyValueEntry(ValueEntry);
                end;
            until ValueEntry.Next() = 0;
        end;

        OnAfterPostItem(JobJnlLine2, ItemJnlPostLine, JobLedgEntryNo);
    end;

    local procedure ModifyValueEntry(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyValueEntry(ValueEntry, JobJnlLine2, IsHandled);
        if IsHandled then
            exit;

        ValueEntry.Modify(true);
    end;

    local procedure PostResource(var JobJnlLine2: Record "Job Journal Line") EntryNo: Integer
    var
        ResJnlLine: Record "Res. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResource(JobJnlLine, JobJnlLine2, EntryNo, IsHandled);
        if IsHandled then
            exit(EntryNo);

        ResJnlLine.Init();
        ResJnlLine.CopyFromJobJnlLine(JobJnlLine2);
        ResJnlPostLine.RunWithCheck(ResJnlLine);
        UpdateJobJnlLineResourceGroupNo(JobJnlLine2, ResJnlLine);
        exit(CreateJobLedgEntry(JobJnlLine2));
    end;

    local procedure UpdateJobJnlLineResourceGroupNo(var JobJnlLine2: Record "Job Journal Line"; ResJnlLine: Record "Res. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobJnlLineResourceGroupNo(JobJnlLine2, ResJnlLine, IsHandled);
        if IsHandled then
            exit;

        JobJnlLine2."Resource Group No." := ResJnlLine."Resource Group No.";
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::Consumption, ItemJnlLine."Entry Type"::Output] then
            exit;

        ItemJnlLine.Quantity := OriginalQuantity;
        ItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(ItemJnlLine."Location Code");
        if Location."Bin Mandatory" then
            if WMSManagement.CreateWhseJnlLine(ItemJnlLine, 0, WarehouseJournalLine, false) then begin
                SetWhseDocForPicks(WarehouseJournalLine, Location.Code);
                TempTrackingSpecification.ModifyAll("Source Type", DATABASE::"Job Journal Line");
                ItemTrackingManagement.SplitWhseJnlLine(WarehouseJournalLine, TempWarehouseJournalLine, TempTrackingSpecification, false);
                if TempWarehouseJournalLine.Find('-') then
                    repeat
                        WMSManagement.CheckWhseJnlLine(TempWarehouseJournalLine, 1, 0, false);
                        WhseJnlRegisterLine.RegisterWhseJnlLine(TempWarehouseJournalLine);
                    until TempWarehouseJournalLine.Next() = 0;
            end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure SetGLEntryNo(GLEntryNo2: Integer)
    begin
        GLEntryNo := GLEntryNo2;
    end;

    local procedure InitItemJnlLine()
    begin
        ItemJnlLine.Init();
        ItemJnlLine.CopyFromJobJnlLine(JobJnlLine2);
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Customer;
        ItemJnlLine."Source No." := Job."Bill-to Customer No.";
        Item.Get(JobJnlLine2."No.");
        ItemJnlLine."Inventory Posting Group" := Item."Inventory Posting Group";
        ItemJnlLine."Item Category Code" := Item."Item Category Code";
    end;

    local procedure UpdateJobJnlLineTotalAmounts(var JobJnlLineToUpdate: Record "Job Journal Line"; AmtRoundingPrecision: Decimal)
    begin
        JobJnlLineToUpdate."Total Cost" := Round(JobJnlLineToUpdate."Unit Cost" * JobJnlLineToUpdate.Quantity, AmtRoundingPrecision);
        JobJnlLineToUpdate."Total Cost (LCY)" := Round(JobJnlLineToUpdate."Unit Cost (LCY)" * JobJnlLineToUpdate.Quantity, GLSetup."Amount Rounding Precision");
        JobJnlLineToUpdate."Total Price" := Round(JobJnlLineToUpdate."Unit Price" * JobJnlLineToUpdate.Quantity, AmtRoundingPrecision);
        JobJnlLineToUpdate."Total Price (LCY)" := Round(JobJnlLineToUpdate."Unit Price (LCY)" * JobJnlLineToUpdate.Quantity, GLSetup."Amount Rounding Precision");
        OnAfterUpdateJobJnlLineTotalAmounts(JobJnlLineToUpdate, AmtRoundingPrecision, GLSetup."Amount Rounding Precision");
    end;

    local procedure UpdateJobJnlLineAmount(var JobJnlLineToUpdate: Record "Job Journal Line"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal; var RemainingQtyToTrack: Decimal; AmtRoundingPrecision: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobJnlLineAmount(JobJnlLineToUpdate, RemainingAmount, RemainingAmountLCY, RemainingQtyToTrack, AmtRoundingPrecision, IsHandled);
        if IsHandled then
            exit;

        JobJnlLineToUpdate."Line Amount" := Round(RemainingAmount * JobJnlLineToUpdate.Quantity / RemainingQtyToTrack, AmtRoundingPrecision);
        JobJnlLineToUpdate."Line Amount (LCY)" := Round(RemainingAmountLCY * JobJnlLineToUpdate.Quantity / RemainingQtyToTrack, AmtRoundingPrecision);

        RemainingAmount -= JobJnlLineToUpdate."Line Amount";
        RemainingAmountLCY -= JobJnlLineToUpdate."Line Amount (LCY)";
        RemainingQtyToTrack -= JobJnlLineToUpdate.Quantity;
    end;

    local procedure UpdateJobJnlLineSourceCurrencyAmounts(var JobJnlLine: Record "Job Journal Line")
    begin
        Currency.Get(GLSetup."Additional Reporting Currency");
        Currency.TestField("Amount Rounding Precision");
        JobJnlLine."Source Currency Total Cost" :=
            Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
                JobJnlLine."Posting Date",
                GLSetup."Additional Reporting Currency", JobJnlLine."Total Cost (LCY)",
                CurrExchRate.ExchangeRate(
                JobJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
            Currency."Amount Rounding Precision");
        JobJnlLine."Source Currency Total Price" :=
            Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
                JobJnlLine."Posting Date",
                GLSetup."Additional Reporting Currency", JobJnlLine."Total Price (LCY)",
                CurrExchRate.ExchangeRate(
                JobJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
            Currency."Amount Rounding Precision");
        JobJnlLine."Source Currency Line Amount" :=
            Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
                JobJnlLine."Posting Date",
                GLSetup."Additional Reporting Currency", JobJnlLine."Line Amount (LCY)",
                CurrExchRate.ExchangeRate(
                JobJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
            Currency."Amount Rounding Precision");
    end;

    local procedure JobPlanningReservationExists(ItemNo: Code[20]; JobNo: Code[20]) Result: Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobPlanningReservationExists(ItemNo, JobNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", Job.Status::Open);
        ReservationEntry.SetRange("Source ID", JobNo);
        Result := not ReservationEntry.IsEmpty();
    end;

    local procedure GetJobConsumptionValueEntry(var ValueEntry: Record "Value Entry"; JobJournalLine: Record "Job Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJobConsumptionValueEntry(JobJournalLine, Result, IsHandled, ValueEntry);
        if IsHandled then
            exit(Result);

        ValueEntry.SetCurrentKey("Job No.", "Job Task No.", "Document No.");
        ValueEntry.SetRange("Item No.", JobJournalLine."No.");
        ValueEntry.SetRange("Job No.", JobJournalLine."Job No.");
        ValueEntry.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        ValueEntry.SetRange("Document No.", JobJournalLine."Document No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
        ValueEntry.SetRange("Job Ledger Entry No.", 0);
        OnGetJobConsumptionValueEntryFilter(ValueEntry, JobJnlLine, JobJournalLine);

        exit(ValueEntry.FindSet());
    end;

    local procedure ApplyToMatchingJobPlanningLine(var JobJnlLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        Job: Record Job;
        JobLedgEntry: Record "Job Ledger Entry";
        JobTransferLine: Codeunit "Job Transfer Line";
        JobLinkUsage: Codeunit "Job Link Usage";
    begin
        if JobLedgEntry."Entry Type" <> JobLedgEntry."Entry Type"::Usage then
            exit(false);

        Job.Get(JobJnlLine."Job No.");
        JobLedgEntry.Init();
        JobTransferLine.FromJnlLineToLedgEntry(JobJnlLine, JobLedgEntry);
        JobLedgEntry.Quantity := JobJnlLine.Quantity;
        JobLedgEntry."Quantity (Base)" := JobJnlLine."Quantity (Base)";

        if JobLinkUsage.FindMatchingJobPlanningLine(JobPlanningLine, JobLedgEntry) then begin
            JobJnlLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            JobJnlLine.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetWhseDocForPicks(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10])
    var
        WhseLocation: Record Location;
        RequireWhseHandling: Boolean;
    begin
        if LocationCode = '' then
            RequireWhseHandling := WhseLocation.RequirePicking(LocationCode)
        else
            RequireWhseHandling := WhseLocation.Get(LocationCode) and (WhseLocation."Job Consump. Whse. Handling" <> Enum::"Job Consump. Whse. Handling"::"No Warehouse Handling");

        if RequireWhseHandling then
            WarehouseJournalLine.SetWhseDocument(WarehouseJournalLine."Whse. Document Type"::Job, ItemJnlLine."Job No.", ItemJnlLine."Job Contract Entry No.");
    end;

    local procedure PostATO(JobJournalLine: Record "Job Journal Line")
    var
        AsmHeader: Record "Assembly Header";
        JobPlanningLine: Record "Job Planning Line";
        Window: Dialog;
    begin
        if not JobJournalLine."Assemble to Order" then
            exit;

        if not JobPlanningLine.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.") then
            exit;

        if JobPlanningLine.AsmToOrderExists(AsmHeader) then begin
            Window.Open(AssemblyPostProgressMsg);
            Window.Update(1,
                StrSubstNo(Format4Lbl,
                JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine.FieldCaption("Line No."), JobPlanningLine."Line No."));
            Window.Update(2, StrSubstNo(Format2Lbl, AsmHeader."Document Type", AsmHeader."No."));

            JobPlanningLine.CheckAsmToOrder(AsmHeader);
            if not HasQtyToAsm(JobPlanningLine, AsmHeader) then
                exit;
            if AsmHeader."Remaining Quantity (Base)" = 0 then
                exit;

            if JobJournalLine."Quantity (Base)" < AsmHeader."Remaining Quantity (Base)" then begin
                AsmHeader.Validate("Quantity to Assemble", JobJournalLine.Quantity);
                AsmHeader.Modify(true);
            end;

            AsmPost.SetPostingDate(true, JobJournalLine."Posting Date");
            AsmPost.InitPostATO(AsmHeader);
            CreatePosterATOLink(AsmHeader, JobPlanningLine);
            AsmPost.PostATO(AsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlPostLine);
            Window.Close();
        end;
    end;

    local procedure CreatePosterATOLink(var AsmHeader: Record "Assembly Header"; var JobPlanningLine: Record "Job Planning Line")
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        PostedATOLink.Init();
        PostedATOLink."Assembly Document Type" := PostedATOLink."Assembly Document Type"::Assembly;
        PostedATOLink."Assembly Document No." := AsmHeader."Posting No.";
        PostedATOLink."Document Type" := PostedATOLink."Document Type"::" ";
        PostedATOLink."Document Line No." := JobPlanningLine."Line No.";
        PostedATOLink."Assembly Order No." := AsmHeader."No.";
        PostedATOLink."Job No." := JobPlanningLine."Job No.";
        PostedATOLink."Job Task No." := JobPlanningLine."JOb Task No.";
        PostedATOLink."Assembled Quantity" := AsmHeader."Quantity to Assemble";
        PostedATOLink."Assembled Quantity (Base)" := AsmHeader."Quantity to Assemble (Base)";
        PostedATOLink.Insert();
    end;

    local procedure HasQtyToAsm(JobPlanningLine: Record "Job Planning Line"; AsmHeader: Record "Assembly Header"): Boolean
    begin
        if JobPlanningLine."Qty. to Assemble (Base)" = 0 then
            exit(false);
        if AsmHeader."Quantity to Assemble (Base)" = 0 then
            exit(false);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyUsageLink(var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobJnlLine(var JobJournalLine: Record "Job Journal Line"; var JobJournalLine2: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItem(var JobJournalLine2: Record "Job Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var JobLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunCode(var JobJournalLine: Record "Job Journal Line"; var JobLedgEntryNo: Integer; var JobRegister: Record "Job Register"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJob(var JobJournalLine: Record "Job Journal Line"; Job: Record Job; var IsHandled: Boolean; var JobRegister: Record "Job Register"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAndCheckJob(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyUsageLink(var JobLedgerEntry: Record "Job Ledger Entry"; var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobLedgEntry(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean; var JobLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobRegister(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJobConsumptionValueEntry(var JobJournalLine: Record "Job Journal Line"; var Result: Boolean; var IsHandled: Boolean; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningReservationExists(ItemNo: Code[20]; JobNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemPosting(var JobJournalLine: Record "Job Journal Line"; var NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyValueEntry(var ValueEntry: Record "Value Entry"; JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResource(var JobJournalLine: Record "Job Journal Line"; var JobJnlLine2: Record "Job Journal Line"; var EntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWithCheck(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobJnlLineAmount(var JobJnlLineToUpdate: Record "Job Journal Line"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal; var RemainingQtyToTrack: Decimal; AmtRoundingPrecision: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobJnlLineResourceGroupNo(var JobJnlLine2: Record "Job Journal Line"; ResJnlLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckJobOnBeforeTestJobTaskType(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldPostUsage(var JobJournalLine2: Record "Job Journal Line"; var ShouldPostUsage: Boolean; var JobLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobLedgEntryOnBeforeAssignQtyCostPrice(var JobLedgEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobLedgerEntryOnAfterAssignLedgerEntryTypeAndNo(var JobLedgEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line"; GLEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetJobConsumptionValueEntryFilter(var ValueEntry: Record "Value Entry"; JobJournalLine: Record "Job Journal Line"; LocalJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterApplyItemTracking(var JobJournalLine: Record "Job Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var JobLedgerEntry: Record "Job Ledger Entry"; var SkipJobLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterSetSkipJobLedgerEntry(var JobJnlLine2: Record "Job Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var SkipJobLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeGetJobConsumptionValueEntry(var JobJournalLine: Record "Job Journal Line"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeUpdateTotalAmounts(var JobJournalLine: Record "Job Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeAssignItemJnlLine(var JobJournalLine: Record "Job Journal Line"; var JobJournalLine2: Record "Job Journal Line"; var ItemJnlLine: Record "Item Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobLedgEntryFromPostItem(var JobJournalLine: Record "Job Journal Line"; var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterPostWhseJnlLine(var JobJournalLine2: Record "Job Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckLine(var JobJournalLine: Record "Job Journal Line"; CalledFromInvtPutawayPick: Boolean; var CheckLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextEntryNo(var JobJournalLine: Record "Job Journal Line"; var NextEntryNo: Integer; var IsHandled: Boolean; var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsertJobRegisterOnBeforeInsert(var JobJournalLine: Record "Job Journal Line"; var JobRegister: Record "Job Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNextEntryNo(var JobLedgerEntry: Record "Job Ledger Entry"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateJobJnlLineTotalAmounts(var JobJournalLine: Record "Job Journal Line"; AmtRoundingPrecision: Decimal; GLAmtRoundingPrecision: Decimal)
    begin
    end;
}

