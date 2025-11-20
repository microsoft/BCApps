// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Resources.Setup;

codeunit 212 "Res. Jnl.-Post Line"
{
    Permissions = TableData "Res. Ledger Entry" = rimd,
                  TableData "Resource Register" = rimd,
                  TableData "Time Sheet Line" = rm,
                  TableData "Time Sheet Detail" = rm;
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ResJournalLineGlobal: Record "Res. Journal Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        Resource: Record Resource;
        ResourceRegister: Record "Resource Register";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        ResourcesSetup: Record "Resources Setup";
        ResJnlCheckLine: Codeunit "Res. Jnl.-Check Line";
        NextEntryNo: Integer;
        GLSetupRead: Boolean;

    procedure RunWithCheck(var ResJournalLine: Record "Res. Journal Line")
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        ResJournalLineGlobal.Copy(ResJournalLine);
        SequenceNoMgt.ClearSequenceNoCheck();
        Code();
        ResJournalLine := ResJournalLineGlobal;
    end;

    local procedure "Code"()
    var
        xNextEntryNo: Integer;
        IsHandled: Boolean;
    begin
        xNextEntryNo := NextEntryNo;
        IsHandled := false;
        OnBeforePostResJnlLine(ResJournalLineGlobal, IsHandled, NextEntryNo);
        if not IsHandled then begin
            ValidateSequenceNo(NextEntryNo, xNextEntryNo, Database::"Res. Ledger Entry");
            if ResJournalLineGlobal.EmptyLine() then
                exit;

            ResJnlCheckLine.RunCheck(ResJournalLineGlobal);
            OnCodeOnAfterRunCheck(ResJournalLineGlobal);

            if (NextEntryNo = 0) and ResourcesSetup.UseLegacyPosting() then begin
                ResLedgerEntry.LockTable();
                NextEntryNo := ResLedgerEntry.GetLastEntryNo() + 1;
            end;

            if ResJournalLineGlobal."Document Date" = 0D then
                ResJournalLineGlobal."Document Date" := ResJournalLineGlobal."Posting Date";

            Resource.Get(ResJournalLineGlobal."Resource No.");
            Resource.CheckResourcePrivacyBlocked(true);

            IsHandled := false;
            OnBeforeCheckResourceBlocked(Resource, IsHandled);
            if not IsHandled then
                Resource.TestField(Blocked, false);

            UpdateResJnlLineResourceGroupNo();

            if not ResourcesSetup.UseLegacyPosting() then
                NextEntryNo := ResLedgerEntry.GetNextEntryNo();

            ResLedgerEntry.Init();
            ResLedgerEntry.CopyFromResJnlLine(ResJournalLineGlobal);

            GetGLSetup();
            ResLedgerEntry."Total Cost" := Round(ResLedgerEntry."Total Cost");
            ResLedgerEntry."Total Price" := Round(ResLedgerEntry."Total Price");
            if ResLedgerEntry."Entry Type" = ResLedgerEntry."Entry Type"::Sale then begin
                ResLedgerEntry.Quantity := -ResLedgerEntry.Quantity;
                ResLedgerEntry."Total Cost" := -ResLedgerEntry."Total Cost";
                ResLedgerEntry."Total Price" := -ResLedgerEntry."Total Price";
            end;
            ResLedgerEntry."Direct Unit Cost" := Round(ResLedgerEntry."Direct Unit Cost", GeneralLedgerSetup."Unit-Amount Rounding Precision");
            ResLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ResLedgerEntry."User ID"));
            ResLedgerEntry."Entry No." := NextEntryNo;
            ResourceUnitOfMeasure.Get(ResLedgerEntry."Resource No.", ResLedgerEntry."Unit of Measure Code");
            if ResourceUnitOfMeasure."Related to Base Unit of Meas." then
                ResLedgerEntry."Quantity (Base)" := ResLedgerEntry.Quantity * ResLedgerEntry."Qty. per Unit of Measure";

            if ResLedgerEntry."Entry Type" = ResLedgerEntry."Entry Type"::Usage then begin
                PostTimeSheetDetail(ResJournalLineGlobal, ResLedgerEntry."Quantity (Base)");
                ResLedgerEntry.Chargeable := IsChargable(ResJournalLineGlobal, ResLedgerEntry.Chargeable);
            end;

            OnBeforeResLedgEntryInsert(ResLedgerEntry, ResJournalLineGlobal);

            InsertRegister(ResLedgerEntry."Entry No.");
            ResLedgerEntry."Resource Register No." := ResourceRegister."No.";
            ResLedgerEntry.Insert(true);
            OnAfterResLedgEntryInsert(ResLedgerEntry, ResJournalLineGlobal);

            if ResourcesSetup.UseLegacyPosting() then
                NextEntryNo := NextEntryNo + 1;
        end;

        xNextEntryNo := NextEntryNo;
        OnAfterPostResJnlLine(ResJournalLineGlobal, ResLedgerEntry, NextEntryNo);
        ValidateSequenceNo(NextEntryNo, xNextEntryNo, Database::"Res. Ledger Entry");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GeneralLedgerSetup.Get();
        GLSetupRead := true;
    end;

    local procedure PostTimeSheetDetail(ResJournalLine: Record "Res. Journal Line"; QtyToPost: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetManagement: Codeunit "Time Sheet Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostTimeSheetDetail(ResJournalLine, QtyToPost, IsHandled);
        if IsHandled then
            exit;

        if ResJournalLine."Time Sheet No." <> '' then begin
            TimeSheetDetail.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.", ResJournalLine."Time Sheet Date");
            TimeSheetDetail."Posted Quantity" += QtyToPost;
            TimeSheetDetail.Posted := TimeSheetDetail.Quantity = TimeSheetDetail."Posted Quantity";
            TimeSheetDetail.Modify();
            TimeSheetLine.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.");
            TimeSheetManagement.CreateTSPostingEntry(TimeSheetDetail, ResJournalLine.Quantity, ResJournalLine."Posting Date", ResJournalLine."Document No.", TimeSheetLine.Description);

            TimeSheetDetail.SetRange("Time Sheet No.", ResJournalLine."Time Sheet No.");
            TimeSheetDetail.SetRange("Time Sheet Line No.", ResJournalLine."Time Sheet Line No.");
            TimeSheetDetail.SetRange(Posted, false);
            OnPostTimeSheetDetailOnAfterSetTimeSheetDetailFilters(TimeSheetDetail, ResJournalLine);
            if TimeSheetDetail.IsEmpty() then begin
                TimeSheetLine.Posted := true;
                TimeSheetLine.Modify();
            end;
        end;
    end;

    local procedure IsChargable(ResJournalLine: Record "Res. Journal Line"; Chargeable: Boolean): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if ResJournalLine."Time Sheet No." <> '' then begin
            TimeSheetLine.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.");
            exit(TimeSheetLine.Chargeable);
        end;
        exit(Chargeable);
    end;

    local procedure InsertRegister(ResLedgEntryNo: Integer)
    begin
        if ResourceRegister."No." = 0 then begin
            ResourceRegister."No." := ResourceRegister.GetNextEntryNo(ResourcesSetup.UseLegacyPosting());
            ResourceRegister.Init();
            ResourceRegister."From Entry No." := NextEntryNo;
            ResourceRegister."To Entry No." := NextEntryNo;
            ResourceRegister."Creation Date" := Today();
            ResourceRegister."Creation Time" := Time();
            ResourceRegister."Source Code" := ResJournalLineGlobal."Source Code";
            ResourceRegister."Journal Batch Name" := ResJournalLineGlobal."Journal Batch Name";
            ResourceRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(ResourceRegister."User ID"));
            OnBeforeResourceRegisterInsert(ResJournalLineGlobal, ResourceRegister);
            ResourceRegister.Insert();
        end else begin
            if ((ResLedgEntryNo < ResourceRegister."From Entry No.") and (ResLedgEntryNo <> 0)) or
               ((ResourceRegister."From Entry No." = 0) and (ResLedgEntryNo > 0))
            then
                ResourceRegister."From Entry No." := ResLedgEntryNo;
            if ResLedgEntryNo > ResourceRegister."To Entry No." then
                ResourceRegister."To Entry No." := ResLedgEntryNo;
            OnBeforeResourceRegisterModify(ResJournalLineGlobal, ResourceRegister);
            ResourceRegister.Modify();
        end;
    end;

    local procedure UpdateResJnlLineResourceGroupNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResJnlLineResourceGroupNo(ResJournalLineGlobal, Resource, IsHandled);
        if IsHandled then
            exit;

        ResJournalLineGlobal."Resource Group No." := Resource."Resource Group No.";
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Res. Ledger Entry", 'r')]
    local procedure ValidateSequenceNo(LedgEntryNo: Integer; xLedgEntryNo: Integer; TableNo: Integer)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if LedgEntryNo = xLedgEntryNo then
            exit;
        if ResourcesSetup.UseLegacyPosting() then
            exit;
        SequenceNoMgt.ValidateSeqNo(TableNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckResourceBlocked(Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostResJnlLine(var ResJournalLine: Record "Res. Journal Line"; var ResLedgEntry: Record "Res. Ledger Entry"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLine(var ResJournalLine: Record "Res. Journal Line"; var IsHandled: Boolean; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostTimeSheetDetail(var ResJournalLine: Record "Res. Journal Line"; QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResLedgEntryInsert(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostTimeSheetDetailOnAfterSetTimeSheetDetailFilters(var TimeSheetDetail: Record "Time Sheet Detail"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceRegisterInsert(var ResJournalLine: Record "Res. Journal Line"; var ResourceRegister: Record "Resource Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceRegisterModify(var ResJournalLine: Record "Res. Journal Line"; var ResourceRegister: Record "Resource Register")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnAfterRunCheck(var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResLedgEntryInsert(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateResJnlLineResourceGroupNo(var ResJournalLine: Record "Res. Journal Line"; Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;
}

