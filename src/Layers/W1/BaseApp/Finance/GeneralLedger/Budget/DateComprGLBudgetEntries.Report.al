// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

report 97 "Date Compr. G/L Budget Entries"
{
    Caption = 'Date Compr. G/L Budget Entries';
    Permissions = TableData "Date Compr. Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Budget Entry"; "G/L Budget Entry")
        {
            DataItemTableView = sorting("Budget Name", "G/L Account No.", Date);
            RequestFilterFields = "Budget Name", "G/L Account No.";

            trigger OnAfterGetRecord()
            begin
                GLBudgetEntry2 := "G/L Budget Entry";
                GLBudgetEntry2.SetCurrentKey("Budget Name", "G/L Account No.", Date);
                GLBudgetEntry2.CopyFilters("G/L Budget Entry");
                GLBudgetEntry2.SetFilter(Date, DateComprMgt.GetDateFilter(GLBudgetEntry2.Date, EntrdDateComprReg, false));
                GLBudgetEntry2.SetRange("Budget Name", GLBudgetEntry2."Budget Name");
                GLBudgetEntry2.SetRange("G/L Account No.", GLBudgetEntry2."G/L Account No.");

                LastEntryNo := LastEntryNo + 1;

                if RetainNo(GLBudgetEntry2.FieldNo("Business Unit Code")) then
                    GLBudgetEntry2.SetRange("Business Unit Code", GLBudgetEntry2."Business Unit Code");
                if RetainNo(GLBudgetEntry2.FieldNo("Global Dimension 1 Code")) then
                    GLBudgetEntry2.SetRange("Global Dimension 1 Code", GLBudgetEntry2."Global Dimension 1 Code");
                if RetainNo(GLBudgetEntry2.FieldNo("Global Dimension 2 Code")) then
                    GLBudgetEntry2.SetRange("Global Dimension 2 Code", GLBudgetEntry2."Global Dimension 2 Code");
                if GLBudgetEntry2.Amount >= 0 then
                    GLBudgetEntry2.SetFilter(Amount, '>=0')
                else
                    GLBudgetEntry2.SetFilter(Amount, '<0');

                InitNewEntry(NewGLBudgetEntry);

                DimBufMgt.CollectDimEntryNo(
                  TempSelectedDim, GLBudgetEntry2."Dimension Set ID", GLBudgetEntry2."Entry No.", 0, false, DimEntryNo);
                ComprDimEntryNo := DimEntryNo;
                SummarizeEntry(NewGLBudgetEntry, GLBudgetEntry2);
                while GLBudgetEntry2.Next() <> 0 do begin
                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, GLBudgetEntry2."Dimension Set ID", GLBudgetEntry2."Entry No.", ComprDimEntryNo, true, DimEntryNo);
                    if DimEntryNo = ComprDimEntryNo then
                        SummarizeEntry(NewGLBudgetEntry, GLBudgetEntry2);
                end;

                InsertNewEntry(NewGLBudgetEntry, ComprDimEntryNo);

                ComprCollectedEntries();

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegister();
                    Commit();
                    GLBudgetEntry2.LockTable();
                    GLBudgetEntry2.Reset();
                    LastEntryNo := GLBudgetEntry2.GetLastEntryNo();
                end;
            end;

            trigger OnPostDataItem()
            var
                UpdateAnalysisView: Codeunit "Update Analysis View";
            begin
                InsertRegister();
                if AnalysisView.FindFirst() then
                    if LowestEntryNo < 2147483647 then
                        UpdateAnalysisView.SetLastBudgetEntryNo(LowestEntryNo - 1);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(
                      Text002,
                      EntrdDateComprReg.FieldCaption("Ending Date"));

                DateComprReg.Init();
                DateComprReg."Creation Date" := Today;
                DateComprReg."Starting Date" := EntrdDateComprReg."Starting Date";
                DateComprReg."Ending Date" := EntrdDateComprReg."Ending Date";
                DateComprReg."Period Length" := EntrdDateComprReg."Period Length";
                DateComprReg."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                DateComprReg."Table ID" := DATABASE::"G/L Budget Entry";
                DateComprReg.Filter := CopyStr(GetFilters, 1, MaxStrLen(DateComprReg.Filter));

                if AnalysisView.FindFirst() then begin
                    AnalysisView.CheckDimensionsAreRetained(3, REPORT::"Date Compr. G/L Budget Entries", true);
                    if not SkipAnalysisViewUpdateCheck then
                        AnalysisView.CheckViewsAreUpdated();
                    Commit();
                end;

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compr. G/L Budget Entries", '', TempSelectedDim);
                GLSetup.Get();
                Retain[2] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compr. G/L Budget Entries", '', GLSetup."Global Dimension 1 Code");
                Retain[3] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compr. G/L Budget Entries", '', GLSetup."Global Dimension 2 Code");

                GLBudgetEntry2.LockTable();
                LastEntryNo := GLBudgetEntry2.GetLastEntryNo();
                LowestEntryNo := 2147483647;

                Window.Open(
                  Text003 +
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                SetRange("Entry No.", 0, LastEntryNo);
                SetRange(Date, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compr. G/L Budget Entries"));
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
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Starting Date"""; EntrdDateComprReg."Starting Date")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Ending Date"""; EntrdDateComprReg."Ending Date")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ending Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
                    }
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field("EntrdGLBudgetEntry.Description"; EntrdGLBudgetEntry.Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that accompanies the entries that result from the compression. The default description is Date Compressed.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; Retain[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                        }
                    }
                    field(RetainDimText; RetainDimText)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retain Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies which dimension information you want to retain when the entries are compressed. The more dimension information that you choose to retain, the more detailed the compressed entries are.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compr. G/L Budget Entries", RetainDimText);
                        end;
                    }
                    field(UseDataArchiveCtrl; UseDataArchive)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Archive Deleted Entries';
                        ToolTip = 'Specifies whether the deleted (compressed) entries will be stored in the data archive for later inspection or export.';
                        Visible = DataArchiveProviderExists;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if CloseAction = Action::Cancel then
                exit;
            if not ConfirmManagement.GetResponseOrDefault(CompressEntriesQst, true) then
                CurrReport.Break();
        end;

        trigger OnOpenPage()
        begin
            InitializeParameter();
        end;

        trigger OnInit()
        begin
            DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Date Compr. G/L Budget Entries", '', RetainDimText, Text009);

        DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
        LogStartTelemetryMessage();
    end;

    trigger OnPostReport()
    begin
        LogEndTelemetryMessage();
    end;

    var
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        EntrdGLBudgetEntry: Record "G/L Budget Entry";
        NewGLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetEntry2: Record "G/L Budget Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        AnalysisView: Record "Analysis View";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        LastEntryNo: Integer;
        LowestEntryNo: Integer;
        NoOfDeleted: Integer;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;
        RegExists: Boolean;
        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        SkipAnalysisViewUpdateCheck: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text003: Label 'Date compressing G/L budget entries...\\';
#pragma warning disable AA0470
        Text004: Label 'Budget Name          #1##########\';
        Text005: Label 'G/L Account No.      #2##########\';
        Text006: Label 'Date                 #3######\\';
        Text007: Label 'No. of new entries   #4######\';
        Text008: Label 'No. of entries del.  #5######';
#pragma warning restore AA0470
        Text009: Label 'Retain Dimensions';
#pragma warning restore AA0074
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InsertField(Number: Integer)
    begin
        NoOfFields := NoOfFields + 1;
        FieldNumber[NoOfFields] := Number;
    end;

    local procedure RetainNo(Number: Integer): Boolean
    begin
        exit(Retain[Index(Number)]);
    end;

    local procedure Index(Number: Integer): Integer
    begin
        for i := 1 to NoOfFields do
            if Number = FieldNumber[i] then
                exit(i);
    end;

    local procedure SummarizeEntry(var NewGLBudgetEntry: Record "G/L Budget Entry"; GLBudgetEntry: Record "G/L Budget Entry")
    begin
        NewGLBudgetEntry.Amount := NewGLBudgetEntry.Amount + GLBudgetEntry.Amount;
        GLBudgetEntry.Delete();
        if GLBudgetEntry."Entry No." < LowestEntryNo then
            LowestEntryNo := GLBudgetEntry."Entry No.";
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(5, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(GLBudgetEntry);
    end;

    procedure ComprCollectedEntries()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        GLBudgetEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, GLBudgetEntryNo) then begin
            InitNewEntry(NewGLBudgetEntry);
            repeat
                GLBudgetEntry.Get(GLBudgetEntryNo);
                SummarizeEntry(NewGLBudgetEntry, GLBudgetEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, GLBudgetEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewGLBudgetEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewGLBudgetEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewGLBudgetEntry: Record "G/L Budget Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        NewGLBudgetEntry.Init();
        NewGLBudgetEntry."Entry No." := LastEntryNo;
        NewGLBudgetEntry."Budget Name" := GLBudgetEntry2."Budget Name";
        NewGLBudgetEntry."G/L Account No." := GLBudgetEntry2."G/L Account No.";
        NewGLBudgetEntry.Date := GLBudgetEntry2.GetRangeMin(Date);
        NewGLBudgetEntry.Description := EntrdGLBudgetEntry.Description;
        NewGLBudgetEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLBudgetEntry2."User ID"));

        if RetainNo(GLBudgetEntry2.FieldNo("Business Unit Code")) then
            NewGLBudgetEntry."Business Unit Code" := GLBudgetEntry2."Business Unit Code";
        if RetainNo(GLBudgetEntry2.FieldNo("Global Dimension 1 Code")) then
            NewGLBudgetEntry."Global Dimension 1 Code" := GLBudgetEntry2."Global Dimension 1 Code";
        if RetainNo(GLBudgetEntry2.FieldNo("Global Dimension 2 Code")) then
            NewGLBudgetEntry."Global Dimension 2 Code" := GLBudgetEntry2."Global Dimension 2 Code";

        Window.Update(1, NewGLBudgetEntry."Budget Name");
        Window.Update(2, NewGLBudgetEntry."G/L Account No.");
        Window.Update(3, NewGLBudgetEntry.Date);
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(4, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewGLBudgetEntry: Record "G/L Budget Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewGLBudgetEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewGLBudgetEntry.Insert();
    end;

    local procedure InsertRegister()
    var
        DateComprReg2: Record "Date Compr. Register";
    begin
        if RegExists then
            DateComprReg.Modify()
        else begin
            DateComprReg2.LockTable();
            DateComprReg."No." := DateComprReg2.GetLastEntryNo() + 1;
            DateComprReg.Insert();
            RegExists := true;
        end;
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();

        InsertField("G/L Budget Entry".FieldNo("Business Unit Code"));
        InsertField("G/L Budget Entry".FieldNo("Global Dimension 1 Code"));
        InsertField("G/L Budget Entry".FieldNo("Global Dimension 2 Code"));

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compr. G/L Budget Entries", '');
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; RetainBusinessUnitCode: Boolean; RetainDimensionText: Text[250])
    begin
        InitializeRequest(StartingDate, EndingDate, PeriodLength, Description, RetainBusinessUnitCode, RetainDimensionText, true);
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; RetainBusinessUnitCode: Boolean; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdGLBudgetEntry.Description := Description;
        Retain[1] := RetainBusinessUnitCode;
        RetainDimText := RetainDimensionText;
        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    internal procedure SetSkipAnalysisViewUpdateCheck();
    begin
        SkipAnalysisViewUpdateCheck := true;
    end;

    local procedure LogStartTelemetryMessage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('UseRequestPage', Format(CurrReport.UseRequestPage()));
        TelemetryDimensions.Add('StartDate', Format(EntrdDateComprReg."Starting Date", 0, 9));
        TelemetryDimensions.Add('EndDate', Format(EntrdDateComprReg."Ending Date", 0, 9));
        TelemetryDimensions.Add('PeriodLength', Format(EntrdDateComprReg."Period Length", 0, 9));
        TelemetryDimensions.Add('RetainBusinessUnitCode', Format(Retain[1], 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4G', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure LogEndTelemetryMessage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('RegisterNo', Format(DateComprReg."Register No.", 0, 9));
        TelemetryDimensions.Add('TableID', Format(DateComprReg."Table ID", 0, 9));
        TelemetryDimensions.Add('NoRecordsDeleted', Format(DateComprReg."No. Records Deleted", 0, 9));
        TelemetryDimensions.Add('NoofNewRecords', Format(DateComprReg."No. of New Records", 0, 9));

        Session.LogMessage('0000F4H', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

}

