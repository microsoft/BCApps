// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

/// <summary>
/// Date compression report for bank account ledger entries to optimize database storage.
/// Combines multiple closed bank account ledger entries within specified date ranges into single summarized entries,
/// preserving audit trails while reducing database size and improving query performance.
/// </summary>
report 1498 "Date Compress Bank Acc. Ledger"
{
    ApplicationArea = Suite;
    Caption = 'Date Compress Bank Account Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
        {
            DataItemTableView = sorting("Bank Account No.", "Posting Date") where(Open = const(false));
            RequestFilterFields = "Bank Account No.", "Bank Acc. Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                BankAccLedgEntry2 := "Bank Account Ledger Entry";
                BankAccLedgEntry2.SetCurrentKey("Bank Account No.", "Posting Date");
                BankAccLedgEntry2.CopyFilters("Bank Account Ledger Entry");
                BankAccLedgEntry2.SetRange("Bank Account No.", BankAccLedgEntry2."Bank Account No.");
                BankAccLedgEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(BankAccLedgEntry2."Posting Date", EntrdDateComprReg, true));
                BankAccLedgEntry2.SetRange("Bank Acc. Posting Group", BankAccLedgEntry2."Bank Acc. Posting Group");
                BankAccLedgEntry2.SetRange("Currency Code", BankAccLedgEntry2."Currency Code");
                BankAccLedgEntry2.SetRange("Document Type", BankAccLedgEntry2."Document Type");

                if DateComprRetainFields."Retain Document No." then
                    BankAccLedgEntry2.SetRange("Document No.", BankAccLedgEntry2."Document No.");
                if DateComprRetainFields."Retain Contact Code" then
                    BankAccLedgEntry2.SetRange("Our Contact Code", BankAccLedgEntry2."Our Contact Code");
                if DateComprRetainFields."Retain Global Dimension 1" then
                    BankAccLedgEntry2.SetRange("Global Dimension 1 Code", BankAccLedgEntry2."Global Dimension 1 Code");
                if DateComprRetainFields."Retain Global Dimension 2" then
                    BankAccLedgEntry2.SetRange("Global Dimension 2 Code", BankAccLedgEntry2."Global Dimension 2 Code");
                if BankAccLedgEntry2.Amount >= 0 then
                    BankAccLedgEntry2.SetFilter(Amount, '>=0')
                else
                    BankAccLedgEntry2.SetFilter(Amount, '<0');

                InitNewEntry(NewBankAccLedgEntry);

                DimBufMgt.CollectDimEntryNo(
                  TempSelectedDim, BankAccLedgEntry2."Dimension Set ID", BankAccLedgEntry2."Entry No.",
                  0, false, DimEntryNo);
                ComprDimEntryNo := DimEntryNo;
                SummarizeEntry(NewBankAccLedgEntry, BankAccLedgEntry2);
                while BankAccLedgEntry2.Next() <> 0 do begin
                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, BankAccLedgEntry2."Dimension Set ID", BankAccLedgEntry2."Entry No.",
                      ComprDimEntryNo, true, DimEntryNo);
                    if DimEntryNo = ComprDimEntryNo then
                        SummarizeEntry(NewBankAccLedgEntry, BankAccLedgEntry2);
                end;

                InsertNewEntry(NewBankAccLedgEntry, ComprDimEntryNo);

                ComprCollectedEntries();

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(GLReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(GLReg, DateComprReg);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                LastTransactionNo: Integer;
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(MustBeSpecifiedErr, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(DateCompressingEntriesMsg);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Bank Acc. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Bank Acc. Ledger", '', TempSelectedDim);
                GLSetup.Get();
                DateComprRetainFields."Retain Global Dimension 1" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Bank Acc. Ledger", '', GLSetup."Global Dimension 1 Code");
                DateComprRetainFields."Retain Global Dimension 2" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Bank Acc. Ledger", '', GLSetup."Global Dimension 2 Code");

                GLEntry.LockTable();
                NewBankAccLedgEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Bank Acc. Ledger"));
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
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Ending Date"""; EntrdDateComprReg."Ending Date")
#pragma warning restore AA0100
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
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field("EntrdBankAccLedgEntry.Description"; EntrdBankAccLedgEntry.Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that accompanies the entries that result from the compression. The default description is Date Compressed.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; DateComprRetainFields."Retain Document No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                        }
                        field("Retain[2]"; DateComprRetainFields."Retain Contact Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Our Contact Code';
                            ToolTip = 'Specifies the employee who is responsible for this bank account.';
                        }
                        field("Retain[5]"; DateComprRetainFields."Retain Journal Template Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Journal Template Name';
                            ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        }
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
                        DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Bank Acc. Ledger", RetainDimText);
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
          3, REPORT::"Date Compress Bank Acc. Ledger", '', RetainDimText, RetainDimensionsLbl);
        BankAccLedgEntryFilter := CopyStr("Bank Account Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

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
        GLReg: Record "G/L Register";
        EntrdBankAccLedgEntry: Record "Bank Account Ledger Entry";
        NewBankAccLedgEntry: Record "Bank Account Ledger Entry";
        BankAccLedgEntry2: Record "Bank Account Ledger Entry";
        GLEntry: Record "G/L Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        BankAccLedgEntryFilter: Text[250];
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        GLRegExists: Boolean;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0470
        MustBeSpecifiedErr: Label '%1 must be specified.';
        DateCompressingEntriesMsg: Label 'Date compressing bank account ledger entries...\\Bank Account No.       #1##########\Date                   #2######\\No. of new entries     #3######\No. of entries deleted #4######';
#pragma warning restore AA0470
        DateCompressedLbl: Label 'Date Compressed';
        RetainDimensionsLbl: Label 'Retain Dimensions';
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        if GLReg.Find('+') then;
        GLReg.Init();
        GLReg."No." := GLReg."No." + 1;
        GLReg."Source Code" := SourceCodeSetup."Compress Bank Acc. Ledger";
        GLReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLReg."User ID"));
        GLReg."From Entry No." := LastEntryNo + 1;

        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Bank Account Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          BankAccLedgEntryFilter, GLReg."No.", SourceCodeSetup."Compress Bank Acc. Ledger");

        if DateComprRetainFields."Retain Document No." then
            AddFieldContent(NewBankAccLedgEntry.FieldName("Document No."));
        if DateComprRetainFields."Retain Contact Code" then
            AddFieldContent(NewBankAccLedgEntry.FieldName("Our Contact Code"));

        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        GLRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure AddFieldContent(FieldName: Text)
    begin
        DateComprReg."Retain Field Contents" :=
            CopyStr(
                DateComprReg."Retain Field Contents" + ',' + FieldName, 1, MaxStrLen(DateComprReg."Retain Field Contents"));
    end;

    local procedure InsertRegisters(var GLReg: Record "G/L Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FoundLastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.Init();
        LastEntryNo := LastEntryNo + 1;
        GLEntry."Entry No." := LastEntryNo;
        GLEntry."Posting Date" := Today;
        GLEntry.Description := EntrdBankAccLedgEntry.Description;
        GLEntry."Source Code" := SourceCodeSetup."Compress Bank Acc. Ledger";
        GLEntry."System-Created Entry" := true;
        GLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLEntry."User ID"));
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry.Insert();
        GLEntry.Consistent(GLEntry.Amount = 0);
        GLReg."To Entry No." := GLEntry."Entry No.";

        if GLRegExists then begin
            GLReg.Modify();
            DateComprReg.Modify();
        end else begin
            GLReg.Insert();
            DateComprReg.Insert();
            GLRegExists := true;
        end;
        Commit();

        GLEntry.LockTable();
        NewBankAccLedgEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLEntry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        if NewBankAccLedgEntry.Find('+') then;
        if (LastEntryNo <> FoundLastEntryNo) or
           (LastEntryNo <> NewBankAccLedgEntry."Entry No." + 1)
        then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters();
        end;
    end;

    local procedure SummarizeEntry(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        NewBankAccLedgEntry.Amount := NewBankAccLedgEntry.Amount + BankAccLedgEntry.Amount;
        NewBankAccLedgEntry."Remaining Amount" := NewBankAccLedgEntry."Remaining Amount" + BankAccLedgEntry."Remaining Amount";
        NewBankAccLedgEntry."Amount (LCY)" := NewBankAccLedgEntry."Amount (LCY)" + BankAccLedgEntry."Amount (LCY)";
        NewBankAccLedgEntry."Debit Amount" := NewBankAccLedgEntry."Debit Amount" + BankAccLedgEntry."Debit Amount";
        NewBankAccLedgEntry."Credit Amount" := NewBankAccLedgEntry."Credit Amount" + BankAccLedgEntry."Credit Amount";
        NewBankAccLedgEntry."Debit Amount (LCY)" :=
          NewBankAccLedgEntry."Debit Amount (LCY)" + BankAccLedgEntry."Debit Amount (LCY)";
        NewBankAccLedgEntry."Credit Amount (LCY)" :=
          NewBankAccLedgEntry."Credit Amount (LCY)" + BankAccLedgEntry."Credit Amount (LCY)";
        BankAccLedgEntry.Delete();
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(4, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(BankAccLedgEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        BankAccLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, BankAccLedgEntryNo) then begin
            InitNewEntry(NewBankAccLedgEntry);
            repeat
                BankAccLedgEntry.Get(BankAccLedgEntryNo);
                SummarizeEntry(NewBankAccLedgEntry, BankAccLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, BankAccLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewBankAccLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewBankAccLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    /// <summary>
    /// Initializes a new compressed bank account ledger entry with default values and sequence numbering.
    /// Sets up the entry structure for combining multiple source entries during date compression.
    /// </summary>
    /// <param name="NewBankAccLedgEntry">New bank account ledger entry to initialize for compression.</param>
    procedure InitNewEntry(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        NewBankAccLedgEntry.Init();
        NewBankAccLedgEntry."Entry No." := LastEntryNo;
        NewBankAccLedgEntry."Bank Account No." := BankAccLedgEntry2."Bank Account No.";
        NewBankAccLedgEntry."Posting Date" := BankAccLedgEntry2.GetRangeMin(BankAccLedgEntry2."Posting Date");
        NewBankAccLedgEntry.Description := EntrdBankAccLedgEntry.Description;
        NewBankAccLedgEntry."Bank Acc. Posting Group" := BankAccLedgEntry2."Bank Acc. Posting Group";
        NewBankAccLedgEntry."Currency Code" := BankAccLedgEntry2."Currency Code";
        NewBankAccLedgEntry."Document Type" := BankAccLedgEntry2."Document Type";
        NewBankAccLedgEntry."Source Code" := SourceCodeSetup."Compress Bank Acc. Ledger";
        NewBankAccLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(BankAccLedgEntry2."User ID"));
        NewBankAccLedgEntry."Transaction No." := NextTransactionNo;

        if DateComprRetainFields."Retain Document No." then
            NewBankAccLedgEntry."Document No." := BankAccLedgEntry2."Document No.";
        if DateComprRetainFields."Retain Contact Code" then
            NewBankAccLedgEntry."Our Contact Code" := BankAccLedgEntry2."Our Contact Code";
        if DateComprRetainFields."Retain Global Dimension 1" then
            NewBankAccLedgEntry."Global Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        if DateComprRetainFields."Retain Global Dimension 2" then
            NewBankAccLedgEntry."Global Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        if DateComprRetainFields."Retain Journal Template Name" then
            NewBankAccLedgEntry."Journal Templ. Name" := BankAccLedgEntry2."Journal Templ. Name";

        Window.Update(1, NewBankAccLedgEntry."Bank Account No.");
        Window.Update(2, NewBankAccLedgEntry."Posting Date");
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(3, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewBankAccLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        OnInsertNewEntryOnBeforeInsert(NewBankAccLedgEntry, DimEntryNo);
        NewBankAccLedgEntry.Insert();
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        if EntrdBankAccLedgEntry.Description = '' then
            EntrdBankAccLedgEntry.Description := DateCompressedLbl;

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;
    end;

    /// <summary>
    /// Initializes date compression parameters and settings for the bank account ledger compression process.
    /// Configures date ranges, period length, field retention options, and data archiving preferences.
    /// </summary>
    /// <param name="StartingDate">Start date for the compression range.</param>
    /// <param name="EndingDate">End date for the compression range.</param>
    /// <param name="PeriodLength">Period length option for compression grouping.</param>
    /// <param name="Description">Description for the compressed entries.</param>
    /// <param name="NewDateComprRetainFields">Field retention configuration for compression.</param>
    /// <param name="RetainDimensionText">Dimension retention settings as text.</param>
    /// <param name="DoUseDataArchive">Whether to use data archive functionality during compression.</param>
    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; NewDateComprRetainFields: Record "Date Compr. Retain Fields"; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdBankAccLedgEntry.Description := Description;
        DateComprRetainFields := NewDateComprRetainFields;
        RetainDimText := RetainDimensionText;
        UseDataArchive := DoUseDataArchive and DataArchiveProviderExists;
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
        TelemetryDimensions.Add('RetainDocumentNo', Format(DateComprRetainFields."Retain Document No.", 0, 9));
        TelemetryDimensions.Add('RetainOurContactCode', Format(DateComprRetainFields."Retain Contact Code", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('RetainJnlTemplate', Format(DateComprRetainFields."Retain Journal Template Name", 0, 9));
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4I', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4J', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    /// <summary>
    /// Integration event raised before inserting a new compressed bank account ledger entry.
    /// Allows subscribers to modify the entry or add custom processing before database insertion.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry being inserted during compression.</param>
    /// <param name="DimEntryNo">Dimension entry number associated with the compressed entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertNewEntryOnBeforeInsert(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; DimEntryNo: Integer)
    begin
    end;
}
