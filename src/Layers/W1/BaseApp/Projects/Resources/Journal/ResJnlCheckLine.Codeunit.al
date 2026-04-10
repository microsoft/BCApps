// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using System.Security.User;

codeunit 211 "Res. Jnl.-Check Line"
{
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
        TimeSheetMgt: Codeunit "Time Sheet Management";

#pragma warning disable AA0074
        Text000: Label 'cannot be a closing date';
#pragma warning disable AA0470
        Text002: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text003: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure RunCheck(var ResJnlLine: Record "Res. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCheck(ResJnlLine, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();

        if ResJnlLine.EmptyLine() then
            exit;

        ResJnlLine.TestField("Resource No.", ErrorInfo.Create());
        ResJnlLine.TestField("Posting Date", ErrorInfo.Create());
        ResJnlLine.TestField("Gen. Prod. Posting Group", ErrorInfo.Create());

        CheckPostingDate(ResJnlLine);

        if ResJnlLine."Document Date" <> 0D then
            if ResJnlLine."Document Date" <> NormalDate(ResJnlLine."Document Date") then
                ResJnlLine.FieldError("Document Date", ErrorInfo.Create(Text000, true));

        if (ResJnlLine."Entry Type" = ResJnlLine."Entry Type"::Usage) and (ResJnlLine."Time Sheet No." <> '') then
            TimeSheetMgt.CheckResJnlLine(ResJnlLine);

        CheckDimensions(ResJnlLine);

        OnAfterRunCheck(ResJnlLine);
    end;

    local procedure CheckPostingDate(ResJnlLine: Record "Res. Journal Line")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        if ResJnlLine."Posting Date" <> NormalDate(ResJnlLine."Posting Date") then
            ResJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text000, true));

        IsHandled := false;
        OnCheckPostingDateOnBeforeCheckAllowedPostingDate(ResJnlLine."Posting Date", IsHandled);
        if IsHandled then
            exit;

        UserSetupManagement.CheckAllowedPostingDate(ResJnlLine."Posting Date");
    end;

    local procedure CheckDimensions(ResJnlLine: Record "Res. Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimensions(ResJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not DimMgt.CheckDimIDComb(ResJnlLine."Dimension Set ID") then
            Error(
                Text002,
                ResJnlLine.TableCaption(), ResJnlLine."Journal Template Name", ResJnlLine."Journal Batch Name", ResJnlLine."Line No.",
                DimMgt.GetDimCombErr());

        TableID[1] := DATABASE::Resource;
        No[1] := ResJnlLine."Resource No.";
        TableID[2] := DATABASE::"Resource Group";
        No[2] := ResJnlLine."Resource Group No.";
        TableID[3] := DATABASE::Job;
        No[3] := ResJnlLine."Job No.";
        OnCheckDimensionsOnAfterAssignDimTableIDs(ResJnlLine, TableID, No);
        if not DimMgt.CheckDimValuePosting(TableID, No, ResJnlLine."Dimension Set ID") then
            if ResJnlLine."Line No." <> 0 then
                Error(
                    Text003,
                    ResJnlLine.TableCaption(), ResJnlLine."Journal Template Name", ResJnlLine."Journal Batch Name", ResJnlLine."Line No.",
                    DimMgt.GetDimValuePostingErr())
            else
                Error(DimMgt.GetDimValuePostingErr());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCheck(var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var ResJournalLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCheck(var ResJournalLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPostingDateOnBeforeCheckAllowedPostingDate(PostingDate: Date; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimensionsOnAfterAssignDimTableIDs(var ResJnlLine: Record "Res. Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;
}

