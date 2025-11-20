// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Ledger;
using System.DataAdministration;
using System.Utilities;

report 98 "Date Compress General Ledger"
{
    Caption = 'Date Compress General Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "G/L - Item Ledger Relation" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("G/L Account No.", "Posting Date");

            trigger OnAfterGetRecord()
            var
                SummarizedGLEntryCount: Integer;
                SkippedEntryNos: Dictionary of [Integer, Boolean];
            begin
                GLEntry2 := "G/L Entry";
                GLEntry2.SetCurrentKey("G/L Account No.", "Posting Date");
                GLEntry2.CopyFilters("G/L Entry");
                GLEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(GLEntry2."Posting Date", EntrdDateComprReg, true));
                repeat
                    GLEntry2.SetRange("G/L Account No.", GLEntry2."G/L Account No.");
                    GLEntry2.SetRange("Gen. Posting Type", GLEntry2."Gen. Posting Type");
                    GLEntry2.SetRange("Gen. Bus. Posting Group", GLEntry2."Gen. Bus. Posting Group");
                    GLEntry2.SetRange("Gen. Prod. Posting Group", GLEntry2."Gen. Prod. Posting Group");

                    if DateComprRetainFields."Retain Document Type" then
                        GLEntry2.SetRange("Document Type", GLEntry2."Document Type");
                    if DateComprRetainFields."Retain Document No." then
                        GLEntry2.SetRange("Document No.", GLEntry2."Document No.");
                    if DateComprRetainFields."Retain Job No." then
                        GLEntry2.SetRange("Job No.", GLEntry2."Job No.");
                    if DateComprRetainFields."Retain Business Unit Code" then
                        GLEntry2.SetRange("Business Unit Code", GLEntry2."Business Unit Code");
                    if DateComprRetainFields."Retain Global Dimension 1" then
                        GLEntry2.SetRange("Global Dimension 1 Code", GLEntry2."Global Dimension 1 Code");
                    if DateComprRetainFields."Retain Global Dimension 2" then
                        GLEntry2.SetRange("Global Dimension 2 Code", GLEntry2."Global Dimension 2 Code");
                    if DateComprRetainFields."Retain Journal Template Name" then
                        GLEntry2.SetRange("Journal Templ. Name", GLEntry2."Journal Templ. Name");

                    if GLEntry2.Amount <> 0 then begin
                        if GLEntry2.Amount > 0 then
                            GLEntry2.SetFilter(Amount, '>0')
                        else
                            GLEntry2.SetFilter(Amount, '<0');
                    end else begin
                        GLEntry2.SetRange(Amount, 0);
                        if GLEntry2."Additional-Currency Amount" >= 0 then
                            GLEntry2.SetFilter("Additional-Currency Amount", '>=0')
                        else
                            GLEntry2.SetFilter("Additional-Currency Amount", '<0');
                    end;

                    OnGLEntryOnAfterGetRecordOnBeforeInitNewEntry(GLEntry2, "G/L Entry");

                    InitNewEntry(NewGLEntry);

                    SummarizedGLEntryCount := 0;
                    Clear(SkippedEntryNos);
                    DimBufMgt.CollectDimEntryNo(TempSelectedDim, GLEntry2."Dimension Set ID", GLEntry2."Entry No.", 0, false, DimEntryNo);
                    ComprDimEntryNo := DimEntryNo;
                    SummarizeEntry(NewGLEntry, GLEntry2, false, SummarizedGLEntryCount);
                    while GLEntry2.Next() <> 0 do begin
                        DimBufMgt.CollectDimEntryNo(TempSelectedDim, GLEntry2."Dimension Set ID", GLEntry2."Entry No.", ComprDimEntryNo, true, DimEntryNo);
                        if DimEntryNo = ComprDimEntryNo then
                            SummarizeEntry(NewGLEntry, GLEntry2, false, SummarizedGLEntryCount)
                        else
                            SkippedEntryNos.Add(GLEntry2."Entry No.", false);

                        GLEntry2.SetLoadFields(
                            Amount, "Additional-Currency Amount",
                            "Dimension Set ID", "Source Currency Amount", "VAT Amount", "Source Currency VAT Amount", "Debit Amount", "Credit Amount",
                            "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", Quantity);
                    end;

                    DeleteCompressedEntries(GLEntry2, SkippedEntryNos, SummarizedGLEntryCount);

                    InsertNewEntry(NewGLEntry, ComprDimEntryNo);

                    ComprCollectedEntries();

                    GLEntry2.CopyFilters("G/L Entry");
                    GLEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(GLEntry2."Posting Date", EntrdDateComprReg, true));
                    GLEntry2.SetLoadFields(
                        "Posting Date", "G/L Account No.", "Gen. Posting Type", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Document Type", "Document No.",
                        "Job No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Journal Templ. Name", Amount, "Additional-Currency Amount",
                        "Dimension Set ID", "Source Currency Amount", "VAT Amount", "Source Currency VAT Amount", "Debit Amount", "Credit Amount",
                        "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", Quantity, "User ID");
                until not GLEntry2.FindFirst();

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(GLReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(GLReg, DateComprReg);

                if AnalysisView.FindFirst() then
                    AnalysisView.UpdateLastEntryNo();

                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(EndDateMustBeSetErr, EntrdDateComprReg.FieldCaption("Ending Date"));

                if AnalysisView.FindFirst() then begin
                    AnalysisView.CheckDimensionsAreRetained(3, REPORT::"Date Compress General Ledger", false);
                    if not SkipAnalysisViewUpdateCheck then
                        AnalysisView.CheckViewsAreUpdated();
                    Commit();
                end;

                Window.Open(
                  DateCompressTxt +
                  CurrGLAccountNoTxt +
                  CurrPostingDateTxt +
                  NewEntriesCountTxt +
                  DelEntriesCountTxt);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress G/L");

                SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Date Compress General Ledger", '', TempSelectedDim);
                GLSetup.Get();
                DateComprRetainFields."Retain Global Dimension 1" :=
                    TempSelectedDim.Get(UserId, 3, REPORT::"Date Compress General Ledger", '', GLSetup."Global Dimension 1 Code");
                DateComprRetainFields."Retain Global Dimension 2" :=
                    TempSelectedDim.Get(UserId, 3, REPORT::"Date Compress General Ledger", '', GLSetup."Global Dimension 2 Code");

                NewGLEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();
                NewGLEntry.GetLastEntry(LastEntryNo, NextTransactionNo);
                NextTransactionNo := NextTransactionNo + 1;
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress General Ledger"));
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
                    field(EndingDate; EntrdDateComprReg."Ending Date")
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
                    field("EntrdGLEntry.Description"; EntrdGLEntry.Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that accompanies the entries that result from the compression. The default description is Date Compressed.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; DateComprRetainFields."Retain Document Type")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document Type';
                            ToolTip = 'Specifies the type of document that is processed by the report or batch job.';
                        }
                        field("Retain[2]"; DateComprRetainFields."Retain Document No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                        }
                        field("Retain[3]"; DateComprRetainFields."Retain Job No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Project No.';
                            ToolTip = 'Specifies the project number.';
                        }
                        field("Retain[4]"; DateComprRetainFields."Retain Business Unit Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                        }
                        field("Retain[7]"; DateComprRetainFields."Retain Journal Template Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Journal Template Name';
                            ToolTip = 'Specifies the name of the journal template that is used for the posting.';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress General Ledger", RetainDimText);
                        end;
                    }
                    group("Retain Totals")
                    {
                        Caption = 'Retain Totals';
                        field("Retain[8]"; DateComprRetainFields."Retain Totals")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the item quantity on the ledger entries that will be date compressed.';
                        }
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
        DimSelectionBuf.CompareDimText(3, REPORT::"Date Compress General Ledger", '', RetainDimText, DimTextFieldNameTxt);

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
        EntrdGLEntry: Record "G/L Entry";
        NewGLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        AnalysisView: Record "Analysis View";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        GLRegExists: Boolean;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;
        SkipAnalysisViewUpdateCheck: Boolean;

        EndDateMustBeSetErr: Label '%1 must be specified.', Comment = '%1 - Ending Date field caption';
        DateCompressTxt: Label 'Date compressing G/L entries...\\';
        CurrGLAccountNoTxt: Label 'G/L Account No.      #1##########\', Comment = '#1 - Current G/L Account No.';
        CurrPostingDateTxt: Label 'Date                 #2######\\', Comment = '#2 - Current Posting Date';
        NewEntriesCountTxt: Label 'No. of new entries   #3######\', Comment = '#3 - Number of new G/L entries';
        DelEntriesCountTxt: Label 'No. of entries del.  #4######', Comment = '#4 - Number of deleted G/L entries';
        PostingDescrTxt: Label 'Date Compressed';
        DimTextFieldNameTxt: Label 'Retain Dimensions';
        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;
        EntryCountMismatchErr: Label 'Count of filtered G/L Entries (%1) does not match the number of summarized entries (%2).', Comment = '%1 - number of filtered G/L Entries, %2 - number of summarized entries';
        PostingDateOutsideRangeErr: Label 'Posting Date filter (%1..%2) is outside the specified range (%3..%4).', Comment = '%1 - min posting date, %2 - max posting date, %3 - starting date, %4 - ending date';

    local procedure InitRegisters()
    begin
        OnBeforeInitRegisters("G/L Entry");

        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress G/L", '', '');

        DateComprReg.InitRegister(
          DATABASE::"G/L Entry", DateComprReg.GetLastEntryNo() + 1, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date",
          EntrdDateComprReg."Period Length", '', GLReg."No.", SourceCodeSetup."Compress G/L");

        if DateComprRetainFields."Retain Document Type" then
            AddFieldContent(NewGLEntry.FieldName("Document Type"));
        if DateComprRetainFields."Retain Document No." then
            AddFieldContent(NewGLEntry.FieldName("Document No."));
        if DateComprRetainFields."Retain Job No." then
            AddFieldContent(NewGLEntry.FieldName("Job No."));
        if DateComprRetainFields."Retain Business Unit Code" then
            AddFieldContent(NewGLEntry.FieldName("Business Unit Code"));
        if DateComprRetainFields."Retain Global Dimension 1" then
            AddFieldContent(NewGLEntry.FieldName("Global Dimension 1 Code"));
        if DateComprRetainFields."Retain Global Dimension 2" then
            AddFieldContent(NewGLEntry.FieldName("Global Dimension 2 Code"));
        if DateComprRetainFields."Retain Journal Template Name" then
            AddFieldContent(NewGLEntry.FieldName("Journal Templ. Name"));

        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        if DateComprRetainFields."Retain Quantity" then
            DateComprReg."Retain Totals" :=
              CopyStr(
                DateComprReg."Retain Totals" + ',' + NewGLEntry.FieldName(Quantity), 1,
                MaxStrLen(DateComprReg."Retain Totals"));

        DateComprReg."Retain Totals" := CopyStr(DateComprReg."Retain Totals", 2);

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
        GLReg."To Entry No." := NewGLEntry."Entry No.";

        if GLRegExists then begin
            GLReg.Modify();
            DateComprReg.Modify();
        end else begin
            GLReg.Insert();
            DateComprReg.Insert();
            GLRegExists := true;
        end;
        Commit();

        NewGLEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        NewGLEntry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        if LastEntryNo <> FoundLastEntryNo then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters();
        end;
    end;

    local procedure SummarizeEntry(var NewGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry"; DeleteGLEntry: Boolean; var SummarizedGLEntryCount: Integer)
    var
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        GLEntryVatEntrylink: Record "G/L Entry - VAT Entry Link";
        GLEntryVatEntrylink2: Record "G/L Entry - VAT Entry Link";
    begin
        NewGLEntry.Amount += GLEntry.Amount;
        NewGLEntry."Source Currency Amount" += GLEntry."Source Currency Amount";
        NewGLEntry."VAT Amount" += GLEntry."VAT Amount";
        NewGLEntry."Source Currency VAT Amount" += GLEntry."Source Currency VAT Amount";
        NewGLEntry."Debit Amount" += GLEntry."Debit Amount";
        NewGLEntry."Credit Amount" += GLEntry."Credit Amount";
        NewGLEntry."Additional-Currency Amount" += GLEntry."Additional-Currency Amount";
        NewGLEntry."Add.-Currency Debit Amount" += GLEntry."Add.-Currency Debit Amount";
        NewGLEntry."Add.-Currency Credit Amount" += GLEntry."Add.-Currency Credit Amount";
        if DateComprRetainFields."Retain Quantity" then
            NewGLEntry.Quantity += GLEntry.Quantity;

        OnSummarizeEntryOnBeforeGLEntryDelete(NewGLEntry, GLEntry);
        if DeleteGLEntry then
            GLEntry.Delete();
        SummarizedGLEntryCount += 1;

        GLItemLedgRelation.SetRange("G/L Entry No.", GLEntry."Entry No.");
        GLItemLedgRelation.DeleteAll();

        GLEntryVatEntrylink.SetRange("G/L Entry No.", GLEntry."Entry No.");
        if GLEntryVatEntrylink.FindSet() then
            repeat
                GLEntryVatEntrylink2 := GLEntryVatEntrylink;
                GLEntryVatEntrylink2.Delete();
                GLEntryVatEntrylink2."G/L Entry No." := NewGLEntry."Entry No.";
                if GLEntryVatEntrylink2.Insert() then;
            until GLEntryVatEntrylink.Next() = 0;
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(4, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(GLEntry);
    end;

    local procedure DeleteCompressedEntries(var GLEntry: Record "G/L Entry"; SkippedEntryNos: Dictionary of [Integer, Boolean]; SummarizedGLEntryCount: Integer)
    begin
        if SkippedEntryNos.Count() > 0 then begin
            // remove one by one if some entries were not summarized due to different non-global dimensions
            if GLEntry.FindSet() then
                repeat
                    if not SkippedEntryNos.ContainsKey(GLEntry."Entry No.") then
                        GLEntry.Delete();
                until GLEntry.Next() = 0;
        end else begin
            // remove all at once if all entries were summarized
            if GLEntry.Count() <> SummarizedGLEntryCount then
                Error(EntryCountMismatchErr, GLEntry.Count(), SummarizedGLEntryCount);
            if (GLEntry.GetRangeMin("Posting Date") < EntrdDateComprReg."Starting Date") or (GLEntry.GetRangeMax("Posting Date") > EntrdDateComprReg."Ending Date") then
                Error(PostingDateOutsideRangeErr,
                    Format(GLEntry.GetRangeMin("Posting Date")), Format(GLEntry.GetRangeMax("Posting Date")),
                    Format(EntrdDateComprReg."Starting Date"), Format(EntrdDateComprReg."Ending Date"));
            GLEntry.DeleteAll();
        end;
    end;

    procedure ComprCollectedEntries()
    var
        GLEntry: Record "G/L Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        GLEntryNo: Integer;
        DummyCount: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, GLEntryNo) then begin
            InitNewEntry(NewGLEntry);
            repeat
                GLEntry.Get(GLEntryNo);
                SummarizeEntry(NewGLEntry, GLEntry, true, DummyCount);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, GLEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewGLEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewGLEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewGLEntry: Record "G/L Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        NewGLEntry.Init();
        NewGLEntry."Entry No." := LastEntryNo;
        NewGLEntry."G/L Account No." := GLEntry2."G/L Account No.";
        NewGLEntry."Posting Date" := GLEntry2.GetRangeMin("Posting Date");
        NewGLEntry.Description := EntrdGLEntry.Description;
        NewGLEntry."Gen. Posting Type" := GLEntry2."Gen. Posting Type";
        NewGLEntry."Gen. Bus. Posting Group" := GLEntry2."Gen. Bus. Posting Group";
        NewGLEntry."Gen. Prod. Posting Group" := GLEntry2."Gen. Prod. Posting Group";
        NewGLEntry."System-Created Entry" := true;
        NewGLEntry."Prior-Year Entry" := true;
        NewGLEntry."Source Code" := SourceCodeSetup."Compress G/L";
        NewGLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLEntry2."User ID"));
        NewGLEntry."Transaction No." := NextTransactionNo;

        if DateComprRetainFields."Retain Document Type" then
            NewGLEntry."Document Type" := GLEntry2."Document Type";
        if DateComprRetainFields."Retain Document No." then
            NewGLEntry."Document No." := GLEntry2."Document No.";
        if DateComprRetainFields."Retain Job No." then
            NewGLEntry."Job No." := GLEntry2."Job No.";
        if DateComprRetainFields."Retain Business Unit Code" then
            NewGLEntry."Business Unit Code" := GLEntry2."Business Unit Code";
        if DateComprRetainFields."Retain Global Dimension 1" then
            NewGLEntry."Global Dimension 1 Code" := GLEntry2."Global Dimension 1 Code";
        if DateComprRetainFields."Retain Global Dimension 2" then
            NewGLEntry."Global Dimension 2 Code" := GLEntry2."Global Dimension 2 Code";
        if DateComprRetainFields."Retain Journal Template Name" then
            NewGLEntry."Journal Templ. Name" := GLEntry2."Journal Templ. Name";

        Window.Update(1, NewGLEntry."G/L Account No.");
        Window.Update(2, NewGLEntry."Posting Date");
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(3, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewGLEntry: Record "G/L Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewGLEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewGLEntry.Insert();
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        if EntrdGLEntry.Description = '' then
            EntrdGLEntry.Description := PostingDescrTxt;

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress General Ledger", '');
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; NewDateComprRetainFields: Record "Date Compr. Retain Fields"; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdGLEntry.Description := Description;
        DateComprRetainFields := NewDateComprRetainFields;
        RetainDimText := RetainDimensionText;
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
        TelemetryDimensions.Add('RetainDocumentType', Format(DateComprRetainFields."Retain Document Type", 0, 9));
        TelemetryDimensions.Add('RetainDocumentNo', Format(DateComprRetainFields."Retain Document No.", 0, 9));
        TelemetryDimensions.Add('RetainJobNo', Format(DateComprRetainFields."Retain Job No.", 0, 9));
        TelemetryDimensions.Add('RetainBusinessUnitCode', Format(DateComprRetainFields."Retain Business Unit Code", 0, 9));
        TelemetryDimensions.Add('RetainQuantity', Format(DateComprRetainFields."Retain Quantity", 0, 9));
        TelemetryDimensions.Add('RetainJnlTemplate', Format(DateComprRetainFields."Retain Journal Template Name", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4O', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4P', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRegisters(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLEntryOnAfterGetRecordOnBeforeInitNewEntry(var GLEntry2: Record "G/L Entry"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeEntryOnBeforeGLEntryDelete(var NewGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry")
    begin
    end;
}

