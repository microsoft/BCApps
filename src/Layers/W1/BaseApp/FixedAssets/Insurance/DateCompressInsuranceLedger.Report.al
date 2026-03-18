// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

report 5697 "Date Compress Insurance Ledger"
{
    Caption = 'Date Compress Insurance Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "Ins. Coverage Ledger Entry" = rimd,
                  TableData "Insurance Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Ins. Coverage Ledger Entry"; "Ins. Coverage Ledger Entry")
        {
            DataItemTableView = sorting("FA No.", "Insurance No.", "Disposed FA");
            RequestFilterFields = "Insurance No.", "FA No.";

            trigger OnAfterGetRecord()
            begin
                if ("Insurance No." <> '') and OnlyIndexEntries and not "Index Entry" then
                    CurrReport.Skip();
                InsCoverageLedgEntry2 := "Ins. Coverage Ledger Entry";
                InsCoverageLedgEntry2.SetCurrentKey("FA No.", "Insurance No.");
                InsCoverageLedgEntry2.CopyFilters("Ins. Coverage Ledger Entry");

                InsCoverageLedgEntry2.SetRange("Insurance No.", InsCoverageLedgEntry2."Insurance No.");
                InsCoverageLedgEntry2.SetRange("FA No.", InsCoverageLedgEntry2."FA No.");
                InsCoverageLedgEntry2.SetRange("Document Type", InsCoverageLedgEntry2."Document Type");
                InsCoverageLedgEntry2.SetRange("Index Entry", InsCoverageLedgEntry2."Index Entry");
                InsCoverageLedgEntry2.SetRange("Disposed FA", InsCoverageLedgEntry2."Disposed FA");
                InsCoverageLedgEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(InsCoverageLedgEntry2."Posting Date", EntrdDateComprReg, true));

                if RetainNo(InsCoverageLedgEntry2.FieldNo("Document No.")) then
                    InsCoverageLedgEntry2.SetRange("Document No.", InsCoverageLedgEntry2."Document No.");
                if RetainNo(InsCoverageLedgEntry2.FieldNo("Global Dimension 1 Code")) then
                    InsCoverageLedgEntry2.SetRange("Global Dimension 1 Code", InsCoverageLedgEntry2."Global Dimension 1 Code");
                if RetainNo(InsCoverageLedgEntry2.FieldNo("Global Dimension 2 Code")) then
                    InsCoverageLedgEntry2.SetRange("Global Dimension 2 Code", InsCoverageLedgEntry2."Global Dimension 2 Code");

                InitNewEntry(NewInsCoverageLedgEntry);

                DimBufMgt.CollectDimEntryNo(
                  TempSelectedDim, InsCoverageLedgEntry2."Dimension Set ID", InsCoverageLedgEntry2."Entry No.",
                  0, false, DimEntryNo);
                ComprDimEntryNo := DimEntryNo;
                SummarizeEntry(NewInsCoverageLedgEntry, InsCoverageLedgEntry2);
                while InsCoverageLedgEntry2.Next() <> 0 do begin
                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, InsCoverageLedgEntry2."Dimension Set ID", InsCoverageLedgEntry2."Entry No.",
                      ComprDimEntryNo, true, DimEntryNo);
                    if DimEntryNo = ComprDimEntryNo then
                        SummarizeEntry(NewInsCoverageLedgEntry, InsCoverageLedgEntry2);
                end;

                InsertNewEntry(NewInsCoverageLedgEntry, ComprDimEntryNo);

                ComprCollectedEntries();

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(InsuranceReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(InsuranceReg, DateComprReg);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Insurance Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Insurance Ledger", '', TempSelectedDim);
                GLSetup.Get();
                Retain[2] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Insurance Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[3] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Insurance Ledger", '', GLSetup."Global Dimension 2 Code");

                NewInsCoverageLedgEntry.LockTable();
                InsuranceReg.LockTable();
                DateComprReg.LockTable();

                LastEntryNo := InsCoverageLedgEntry2.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Insurance Ledger"));
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
                    field(StartingDate; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
                    }
                    field(PeriodLength; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(PostingDescription; EntrdInsCoverageLedgEntry.Description)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    field(OnlyIndexEntries; OnlyIndexEntries)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Only Index Entries';
                        ToolTip = 'Specifies if only index entries are date compressed. With the Index Fixed Assets batch job, you can index fixed assets that are linked to a specific depreciation book. The batch job creates entries in a journal based on the conditions that you specify. You can then post the journal or adjust the entries before posting, if necessary.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field(DocumentNo; Retain[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                        }
                    }
                    field(RetainDimensions; RetainDimText)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retain Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies which dimension information you want to retain when the entries are compressed. The more dimension information that you choose to retain, the more detailed the compressed entries are.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Insurance Ledger", RetainDimText);
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
        var
            DateCompression: Codeunit "Date Compression";
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
            if EntrdInsCoverageLedgEntry.Description = '' then
                EntrdInsCoverageLedgEntry.Description := Text009;

            InsertField("Ins. Coverage Ledger Entry".FieldNo("Document No."), "Ins. Coverage Ledger Entry".FieldCaption("Document No."));
            InsertField("Ins. Coverage Ledger Entry".FieldNo("Global Dimension 1 Code"), "Ins. Coverage Ledger Entry".FieldCaption("Global Dimension 1 Code"));
            InsertField("Ins. Coverage Ledger Entry".FieldNo("Global Dimension 2 Code"), "Ins. Coverage Ledger Entry".FieldCaption("Global Dimension 2 Code"));

            RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Insurance Ledger", '');

            DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
            UseDataArchive := DataArchiveProviderExists;
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
          3, REPORT::"Date Compress Insurance Ledger", '', RetainDimText, Text010);
        InsCoverageLedgEntryFilter := CopyStr("Ins. Coverage Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

        DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
        LogStartTelemetryMessage();
    end;

    trigger OnPostReport()
    begin
        LogEndTelemetryMessage();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        EntrdDateComprReg: Record "Date Compr. Register";
        InsuranceReg: Record "Insurance Register";
        EntrdInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsCoverageLedgEntry2: Record "Ins. Coverage Ledger Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        InsCoverageLedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        InsuranceRegExists: Boolean;
        OnlyIndexEntries: Boolean;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text004: Label 'Date compressing insurance ledger entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Insurance No.        #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of new entries   #3######\';
        Text008: Label 'No. of entries del.  #4######';
#pragma warning restore AA0470
        Text009: Label 'Date Compressed';
        Text010: Label 'Retain Dimensions';
#pragma warning restore AA0074
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        InsuranceReg.Init();
        InsuranceReg."No." := InsuranceReg.GetLastEntryNo() + 1;
        InsuranceReg."Creation Date" := Today;
        InsuranceReg."Creation Time" := Time;
        InsuranceReg."Source Code" := SourceCodeSetup."Compress Insurance Ledger";
        InsuranceReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(InsuranceReg."User ID"));
        InsuranceReg."From Entry No." := LastEntryNo + 1;

        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Ins. Coverage Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          InsCoverageLedgEntryFilter, InsuranceReg."No.", SourceCodeSetup."Compress Insurance Ledger");

        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        InsuranceRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var InsuranceReg: Record "Insurance Register"; var DateComprReg: Record "Date Compr. Register")
    var
        CurrLastEntryNo: Integer;
    begin
        InsuranceReg."To Entry No." := NewInsCoverageLedgEntry."Entry No.";

        if InsuranceRegExists then begin
            InsuranceReg.Modify();
            DateComprReg.Modify();
        end else begin
            InsuranceReg.Insert();
            DateComprReg.Insert();
            InsuranceRegExists := true;
        end;
        Commit();

        NewInsCoverageLedgEntry.LockTable();
        InsuranceReg.LockTable();
        DateComprReg.LockTable();

        InsCoverageLedgEntry2.Reset();
        CurrLastEntryNo := InsCoverageLedgEntry2.GetLastEntryNo();
        if LastEntryNo <> CurrLastEntryNo then begin
            LastEntryNo := CurrLastEntryNo;
            InitRegisters();
        end;
    end;

    local procedure InsertField(Number: Integer; Name: Text)
    begin
        NoOfFields := NoOfFields + 1;
        FieldNumber[NoOfFields] := Number;
        FieldNameArray[NoOfFields] := CopyStr(Name, 1, MaxStrLen(FieldNameArray[NoOfFields]));
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

    local procedure SummarizeEntry(var NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry")
    begin
        NewInsCoverageLedgEntry.Amount := NewInsCoverageLedgEntry.Amount + InsCoverageLedgEntry.Amount;
        InsCoverageLedgEntry.Delete();
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(4, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(InsCoverageLedgEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        InsCoverageLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, InsCoverageLedgEntryNo) then begin
            InitNewEntry(NewInsCoverageLedgEntry);
            repeat
                InsCoverageLedgEntry.Get(InsCoverageLedgEntryNo);
                SummarizeEntry(NewInsCoverageLedgEntry, InsCoverageLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, InsCoverageLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewInsCoverageLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewInsCoverageLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;
        NewInsCoverageLedgEntry.Init();
        NewInsCoverageLedgEntry."Entry No." := LastEntryNo;

        NewInsCoverageLedgEntry."Insurance No." := InsCoverageLedgEntry2."Insurance No.";
        NewInsCoverageLedgEntry."FA No." := InsCoverageLedgEntry2."FA No.";
        NewInsCoverageLedgEntry."Document Type" := InsCoverageLedgEntry2."Document Type";
        NewInsCoverageLedgEntry."Index Entry" := InsCoverageLedgEntry2."Index Entry";
        NewInsCoverageLedgEntry."Disposed FA" := InsCoverageLedgEntry2."Disposed FA";

        NewInsCoverageLedgEntry."Posting Date" := InsCoverageLedgEntry2.GetRangeMin("Posting Date");
        NewInsCoverageLedgEntry.Description := EntrdInsCoverageLedgEntry.Description;
        NewInsCoverageLedgEntry."Source Code" := SourceCodeSetup."Compress Insurance Ledger";
        NewInsCoverageLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(InsCoverageLedgEntry2."User ID"));
        if RetainNo(InsCoverageLedgEntry2.FieldNo("Document No.")) then
            NewInsCoverageLedgEntry."Document No." := InsCoverageLedgEntry2."Document No.";
        if RetainNo(InsCoverageLedgEntry2.FieldNo("Global Dimension 1 Code")) then
            NewInsCoverageLedgEntry."Global Dimension 1 Code" := InsCoverageLedgEntry2."Global Dimension 1 Code";
        if RetainNo(InsCoverageLedgEntry2.FieldNo("Global Dimension 2 Code")) then
            NewInsCoverageLedgEntry."Global Dimension 2 Code" := InsCoverageLedgEntry2."Global Dimension 2 Code";

        Window.Update(1, NewInsCoverageLedgEntry."Insurance No.");
        Window.Update(2, NewInsCoverageLedgEntry."Posting Date");
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(3, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewInsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewInsCoverageLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewInsCoverageLedgEntry.Insert();
    end;

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date; PeriodLengthFrom: Option; DescriptionFrom: Text[100]; OnlyIndexEntriesFrom: Boolean; RetainDocumentNo: Boolean; RetainDimTextFrom: Text[250])
    begin
        InitializeRequest(StartingDateFrom, EndingDateFrom, PeriodLengthFrom, DescriptionFrom, OnlyIndexEntriesFrom, RetainDocumentNo, RetainDimTextFrom, true);
    end;

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date; PeriodLengthFrom: Option; DescriptionFrom: Text[100]; OnlyIndexEntriesFrom: Boolean; RetainDocumentNo: Boolean; RetainDimTextFrom: Text[250]; DoUseDataArchive: Boolean)
    begin
        EntrdDateComprReg."Starting Date" := StartingDateFrom;
        EntrdDateComprReg."Ending Date" := EndingDateFrom;
        EntrdDateComprReg."Period Length" := PeriodLengthFrom;
        EntrdInsCoverageLedgEntry.Description := DescriptionFrom;
        RetainDimText := RetainDimTextFrom;
        OnlyIndexEntries := OnlyIndexEntriesFrom;
        Retain[1] := RetainDocumentNo;

        InsertField("Ins. Coverage Ledger Entry".FieldNo("Document No."), "Ins. Coverage Ledger Entry".FieldCaption("Document No."));
        InsertField("Ins. Coverage Ledger Entry".FieldNo("Global Dimension 1 Code"), "Ins. Coverage Ledger Entry".FieldCaption("Global Dimension 1 Code"));
        InsertField("Ins. Coverage Ledger Entry".FieldNo("Global Dimension 2 Code"), "Ins. Coverage Ledger Entry".FieldCaption("Global Dimension 2 Code"));

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
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
        TelemetryDimensions.Add('OnlyIndexEntriesFrom', Format(OnlyIndexEntries, 0, 9));
        TelemetryDimensions.Add('RetainDocumentNo', Format(Retain[1], 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4Q', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4R', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;
}

