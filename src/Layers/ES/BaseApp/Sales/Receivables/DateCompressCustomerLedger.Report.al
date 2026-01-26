// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Sales.FinanceCharge;
using System.DataAdministration;
using System.Utilities;

report 198 "Date Compress Customer Ledger"
{
    Caption = 'Date Compress Customer Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Reminder/Fin. Charge Entry" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Customer No.", "Posting Date") where(Open = const(false));
            RequestFilterFields = "Customer No.", "Customer Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                if not CompressDetails("Cust. Ledger Entry") then
                    CurrReport.Skip();
                ReminderEntry.SetCurrentKey("Customer Entry No.");
                CustLedgEntry2 := "Cust. Ledger Entry";
                CustLedgEntry2.SetCurrentKey("Customer No.", "Posting Date");
                CustLedgEntry2.CopyFilters("Cust. Ledger Entry");
                CustLedgEntry2.SetRange("Customer No.", CustLedgEntry2."Customer No.");
                CustLedgEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(CustLedgEntry2."Posting Date", EntrdDateComprReg, true));
                CustLedgEntry2.SetRange("Customer Posting Group", CustLedgEntry2."Customer Posting Group");
                CustLedgEntry2.SetRange("Currency Code", CustLedgEntry2."Currency Code");
                CustLedgEntry2.SetRange("Document Type", CustLedgEntry2."Document Type");
                OnAfterCustLedgEntry2SetFilters(CustLedgEntry2, "Cust. Ledger Entry");

                if DateComprRetainFields."Retain Document No." then
                    CustLedgEntry2.SetRange("Document No.", CustLedgEntry2."Document No.");
                if DateComprRetainFields."Retain Sell-to Customer No." then
                    CustLedgEntry2.SetRange("Sell-to Customer No.", CustLedgEntry2."Sell-to Customer No.");
                if DateComprRetainFields."Retain Salesperson Code" then
                    CustLedgEntry2.SetRange("Salesperson Code", CustLedgEntry2."Salesperson Code");
                if DateComprRetainFields."Retain Global Dimension 1" then
                    CustLedgEntry2.SetRange("Global Dimension 1 Code", CustLedgEntry2."Global Dimension 1 Code");
                if DateComprRetainFields."Retain Global Dimension 2" then
                    CustLedgEntry2.SetRange("Global Dimension 2 Code", CustLedgEntry2."Global Dimension 2 Code");
                if DateComprRetainFields."Retain Journal Template Name" then
                    CustLedgEntry2.SetRange("Journal Templ. Name", CustLedgEntry2."Journal Templ. Name");
                CustLedgEntry2.CalcFields(Amount);
                if CustLedgEntry2.Amount >= 0 then
                    SummarizePositive := true
                else
                    SummarizePositive := false;

                InitNewEntry(NewCustLedgEntry);

                DimBufMgt.CollectDimEntryNo(
                  TempSelectedDim, CustLedgEntry2."Dimension Set ID", CustLedgEntry2."Entry No.",
                  0, false, DimEntryNo);
                ComprDimEntryNo := DimEntryNo;
                SummarizeEntry(NewCustLedgEntry, CustLedgEntry2);

                while CustLedgEntry2.Next() <> 0 do begin
                    CustLedgEntry2.CalcFields(Amount);
                    if ((CustLedgEntry2.Amount >= 0) and SummarizePositive) or
                       ((CustLedgEntry2.Amount < 0) and (not SummarizePositive))
                    then
                        if CompressDetails(CustLedgEntry2) then begin
                            DimBufMgt.CollectDimEntryNo(
                              TempSelectedDim, CustLedgEntry2."Dimension Set ID", CustLedgEntry2."Entry No.",
                              ComprDimEntryNo, true, DimEntryNo);
                            if DimEntryNo = ComprDimEntryNo then
                                SummarizeEntry(NewCustLedgEntry, CustLedgEntry2);
                        end;
                end;

                InsertNewEntry(NewCustLedgEntry, ComprDimEntryNo);

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
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Cust. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Customer Ledger", '', TempSelectedDim);
                GLSetup.Get();
                DateComprRetainFields."Retain Global Dimension 1" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Customer Ledger", '', GLSetup."Global Dimension 1 Code");
                DateComprRetainFields."Retain Global Dimension 2" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Customer Ledger", '', GLSetup."Global Dimension 2 Code");

                GLEntry.LockTable();
                ReminderEntry.LockTable();
                NewDtldCustLedgEntry.LockTable();
                NewCustLedgEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                LastDtldEntryNo := NewDtldCustLedgEntry.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Customer Ledger"));
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
                    field("EntrdCustLedgEntry.Description"; EntrdCustLedgEntry.Description)
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
                        field("Retain[2]"; DateComprRetainFields."Retain Sell-to Customer No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Sell-to Customer No.';
                            ToolTip = 'Specifies the customer for whom ledger entries are date compressed.';
                        }
                        field("Retain[3]"; DateComprRetainFields."Retain Salesperson Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Salesperson Code';
                            ToolTip = 'Specifies the salesperson for whom customer ledger entries are date compressed';
                        }
                        field("Retain[6]"; DateComprRetainFields."Retain Journal Template Name")
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Customer Ledger", RetainDimText);
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
          3, REPORT::"Date Compress Customer Ledger", '', RetainDimText, Text010);
        CustLedgEntryFilter := CopyStr("Cust. Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

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
        EntrdCustLedgEntry: Record "Cust. Ledger Entry";
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempDetailedCustLedgEntryBuffer: Record "Detailed Cust. Ledg. Entry" temporary;
        GLEntry: Record "G/L Entry";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        CustLedgEntryFilter: Text[250];
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        LastDtldEntryNo: Integer;
        LastTmpDtldEntryNo: Integer;
        GLRegExists: Boolean;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;
        SummarizePositive: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text004: Label 'Date compressing customer ledger entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Customer No.         #1##########\';
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
        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress Cust. Ledger", '', '');
        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Cust. Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          CustLedgEntryFilter, GLReg."No.", SourceCodeSetup."Compress Cust. Ledger");

        if DateComprRetainFields."Retain Document No." then
            AddFieldContent(NewCustLedgEntry.FieldName("Document No."));
        if DateComprRetainFields."Retain Sell-to Customer No." then
            AddFieldContent(NewCustLedgEntry.FieldName("Sell-to Customer No."));
        if DateComprRetainFields."Retain Salesperson Code" then
            AddFieldContent(NewCustLedgEntry.FieldName("Salesperson Code"));
        if DateComprRetainFields."Retain Global Dimension 1" then
            AddFieldContent(NewCustLedgEntry.FieldName("Global Dimension 1 Code"));
        if DateComprRetainFields."Retain Global Dimension 2" then
            AddFieldContent(NewCustLedgEntry.FieldName("Global Dimension 2 Code"));
        if DateComprRetainFields."Retain Journal Template Name" then
            AddFieldContent(NewCustLedgEntry.FieldName("Journal Templ. Name"));

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
        FoundLastLedgEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.Init();
        LastEntryNo := LastEntryNo + 1;
        GLEntry."Entry No." := LastEntryNo;
        GLEntry."Posting Date" := Today;
        GLEntry.Description := EntrdCustLedgEntry.Description;
        GLEntry."Source Code" := SourceCodeSetup."Compress Cust. Ledger";
        GLEntry."System-Created Entry" := true;
        GLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLEntry."User ID"));
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry.Insert();
        GLEntry.Consistent(GLEntry.Amount = 0);
        GLReg."To Entry No." := LastEntryNo;

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
        ReminderEntry.LockTable();
        NewDtldCustLedgEntry.LockTable();
        NewCustLedgEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLEntry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        FoundLastLedgEntryNo := NewCustLedgEntry.GetLastEntryNo();
        if (LastEntryNo <> FoundLastEntryNo) or
           (LastEntryNo <> FoundLastLedgEntryNo + 1)
        then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters();
        end;
        LastDtldEntryNo := NewDtldCustLedgEntry.GetLastEntryNo();
    end;

    local procedure SummarizeEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        NewCustLedgEntry."Sales (LCY)" := NewCustLedgEntry."Sales (LCY)" + CustLedgEntry."Sales (LCY)";
        NewCustLedgEntry."Profit (LCY)" := NewCustLedgEntry."Profit (LCY)" + CustLedgEntry."Profit (LCY)";
        NewCustLedgEntry."Inv. Discount (LCY)" := NewCustLedgEntry."Inv. Discount (LCY)" + CustLedgEntry."Inv. Discount (LCY)";
        NewCustLedgEntry."Original Pmt. Disc. Possible" :=
          NewCustLedgEntry."Original Pmt. Disc. Possible" + CustLedgEntry."Original Pmt. Disc. Possible";
        NewCustLedgEntry."Remaining Pmt. Disc. Possible" :=
          NewCustLedgEntry."Remaining Pmt. Disc. Possible" + CustLedgEntry."Remaining Pmt. Disc. Possible";
        NewCustLedgEntry."Closed by Amount (LCY)" :=
          NewCustLedgEntry."Closed by Amount (LCY)" + CustLedgEntry."Closed by Amount (LCY)";

        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        if DtldCustLedgEntry.Find('-') then begin
            repeat
                SummarizeDtldEntry(DtldCustLedgEntry, NewCustLedgEntry);
            until DtldCustLedgEntry.Next() = 0;
            DtldCustLedgEntry.DeleteAll();
        end;

        ReminderEntry.SetRange("Customer Entry No.", CustLedgEntry."Entry No.");
        ReminderEntry.DeleteAll();
        CustLedgEntry.Delete();
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(4, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(CustLedgEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        CustLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, CustLedgEntryNo) then begin
            InitNewEntry(NewCustLedgEntry);
            repeat
                CustLedgEntry.Get(CustLedgEntryNo);
                SummarizeEntry(NewCustLedgEntry, CustLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, CustLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewCustLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewCustLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        NewCustLedgEntry.Init();
        NewCustLedgEntry."Entry No." := LastEntryNo;
        NewCustLedgEntry."Customer No." := CustLedgEntry2."Customer No.";
        NewCustLedgEntry."Posting Date" := CustLedgEntry2.GetRangeMin("Posting Date");
        NewCustLedgEntry.Description := EntrdCustLedgEntry.Description;
        NewCustLedgEntry."Customer Posting Group" := CustLedgEntry2."Customer Posting Group";
        NewCustLedgEntry."Currency Code" := CustLedgEntry2."Currency Code";
        NewCustLedgEntry."Document Type" := CustLedgEntry2."Document Type";
        NewCustLedgEntry."Source Code" := SourceCodeSetup."Compress Cust. Ledger";
        NewCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(CustLedgEntry2."User ID"));
        NewCustLedgEntry."Transaction No." := NextTransactionNo;

        if DateComprRetainFields."Retain Document No." then
            NewCustLedgEntry."Document No." := CustLedgEntry2."Document No.";
        if DateComprRetainFields."Retain Sell-to Customer No." then
            NewCustLedgEntry."Sell-to Customer No." := CustLedgEntry2."Sell-to Customer No.";
        if DateComprRetainFields."Retain Salesperson Code" then
            NewCustLedgEntry."Salesperson Code" := CustLedgEntry2."Salesperson Code";
        if DateComprRetainFields."Retain Global Dimension 1" then
            NewCustLedgEntry."Global Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
        if DateComprRetainFields."Retain Global Dimension 2" then
            NewCustLedgEntry."Global Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
        if DateComprRetainFields."Retain Journal Template Name" then
            NewCustLedgEntry."Journal Templ. Name" := CustLedgEntry2."Journal Templ. Name";

        Window.Update(1, NewCustLedgEntry."Customer No.");
        Window.Update(2, NewCustLedgEntry."Posting Date");
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(3, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewCustLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewCustLedgEntry.Insert();
        InsertDtldEntries();
    end;

    local procedure CompressDetails(CustLedgEntry: Record "Cust. Ledger Entry"): Boolean
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        if EntrdDateComprReg."Starting Date" <> 0D then
            DtldCustLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '..%1|%2..',
                CalcDate('<-1D>', EntrdDateComprReg."Starting Date"),
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")))
        else
            DtldCustLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '%1..',
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")));

        exit(DtldCustLedgEntry.IsEmpty());
    end;

    local procedure SummarizeDtldEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var NewCustLedgEntry: Record "Cust. Ledger Entry")
    var
        NewEntry: Boolean;
        PostingDate: Date;
    begin
        if UseDataArchive then
            DataArchive.SaveRecord(DtldCustLedgEntry);
        TempDetailedCustLedgEntryBuffer.SetFilter(
          "Posting Date",
          DateComprMgt.GetDateFilter(DtldCustLedgEntry."Posting Date", EntrdDateComprReg, true));
        PostingDate := TempDetailedCustLedgEntryBuffer.GetRangeMin("Posting Date");
        TempDetailedCustLedgEntryBuffer.SetRange("Posting Date", PostingDate);
        TempDetailedCustLedgEntryBuffer.SetRange("Entry Type", DtldCustLedgEntry."Entry Type");
        if DateComprRetainFields."Retain Document No." then
            TempDetailedCustLedgEntryBuffer.SetRange("Document No.", "Cust. Ledger Entry"."Document No.");
        if DateComprRetainFields."Retain Sell-to Customer No." then
            TempDetailedCustLedgEntryBuffer.SetRange("Customer No.", "Cust. Ledger Entry"."Sell-to Customer No.");
        if DateComprRetainFields."Retain Global Dimension 1" then
            TempDetailedCustLedgEntryBuffer.SetRange("Initial Entry Global Dim. 1", "Cust. Ledger Entry"."Global Dimension 1 Code");
        if DateComprRetainFields."Retain Global Dimension 2" then
            TempDetailedCustLedgEntryBuffer.SetRange("Initial Entry Global Dim. 2", "Cust. Ledger Entry"."Global Dimension 2 Code");
        OnSummarizeDtldEntryOnAfterDtldCustLedgEntryBufferSetFilters(TempDetailedCustLedgEntryBuffer, DtldCustLedgEntry, "Cust. Ledger Entry", NewCustLedgEntry);

        if not TempDetailedCustLedgEntryBuffer.Find('-') then begin
            TempDetailedCustLedgEntryBuffer.Reset();
            Clear(TempDetailedCustLedgEntryBuffer);

            LastTmpDtldEntryNo := LastTmpDtldEntryNo + 1;
            TempDetailedCustLedgEntryBuffer."Entry No." := LastTmpDtldEntryNo;
            TempDetailedCustLedgEntryBuffer."Posting Date" := PostingDate;
            TempDetailedCustLedgEntryBuffer."Document Type" := NewCustLedgEntry."Document Type";
            TempDetailedCustLedgEntryBuffer."Initial Document Type" := NewCustLedgEntry."Document Type";
            TempDetailedCustLedgEntryBuffer."Document No." := NewCustLedgEntry."Document No.";
            TempDetailedCustLedgEntryBuffer."Entry Type" := DtldCustLedgEntry."Entry Type";
            TempDetailedCustLedgEntryBuffer."Cust. Ledger Entry No." := NewCustLedgEntry."Entry No.";
            TempDetailedCustLedgEntryBuffer."Customer No." := NewCustLedgEntry."Customer No.";
            TempDetailedCustLedgEntryBuffer."Currency Code" := NewCustLedgEntry."Currency Code";
            TempDetailedCustLedgEntryBuffer."User ID" := NewCustLedgEntry."User ID";
            TempDetailedCustLedgEntryBuffer."Source Code" := NewCustLedgEntry."Source Code";
            TempDetailedCustLedgEntryBuffer."Transaction No." := NewCustLedgEntry."Transaction No.";
            TempDetailedCustLedgEntryBuffer."Journal Batch Name" := NewCustLedgEntry."Journal Batch Name";
            TempDetailedCustLedgEntryBuffer."Reason Code" := NewCustLedgEntry."Reason Code";
            TempDetailedCustLedgEntryBuffer."Initial Entry Due Date" := NewCustLedgEntry."Due Date";
            TempDetailedCustLedgEntryBuffer."Initial Entry Global Dim. 1" := NewCustLedgEntry."Global Dimension 1 Code";
            TempDetailedCustLedgEntryBuffer."Initial Entry Global Dim. 2" := NewCustLedgEntry."Global Dimension 2 Code";
            TempDetailedCustLedgEntryBuffer."Excluded from calculation" := DtldCustLedgEntry."Excluded from calculation";
            OnSummarizeDtldEntryOnAfterInitDtldCustLedgEntryBuffer(TempDetailedCustLedgEntryBuffer, TempDetailedCustLedgEntryBuffer, "Cust. Ledger Entry", NewCustLedgEntry);

            NewEntry := true;
        end;

        TempDetailedCustLedgEntryBuffer.Amount :=
          TempDetailedCustLedgEntryBuffer.Amount + DtldCustLedgEntry.Amount;
        TempDetailedCustLedgEntryBuffer."Amount (LCY)" :=
          TempDetailedCustLedgEntryBuffer."Amount (LCY)" + DtldCustLedgEntry."Amount (LCY)";
        TempDetailedCustLedgEntryBuffer."Debit Amount" :=
          TempDetailedCustLedgEntryBuffer."Debit Amount" + DtldCustLedgEntry."Debit Amount";
        TempDetailedCustLedgEntryBuffer."Credit Amount" :=
          TempDetailedCustLedgEntryBuffer."Credit Amount" + DtldCustLedgEntry."Credit Amount";
        TempDetailedCustLedgEntryBuffer."Debit Amount (LCY)" :=
          TempDetailedCustLedgEntryBuffer."Debit Amount (LCY)" + DtldCustLedgEntry."Debit Amount (LCY)";
        TempDetailedCustLedgEntryBuffer."Credit Amount (LCY)" :=
          TempDetailedCustLedgEntryBuffer."Credit Amount (LCY)" + DtldCustLedgEntry."Credit Amount (LCY)";

        if NewEntry then
            TempDetailedCustLedgEntryBuffer.Insert()
        else
            TempDetailedCustLedgEntryBuffer.Modify();
    end;

    local procedure InsertDtldEntries()
    begin
        TempDetailedCustLedgEntryBuffer.Reset();
        if TempDetailedCustLedgEntryBuffer.Find('-') then
            repeat
                if ((TempDetailedCustLedgEntryBuffer.Amount <> 0) or
                    (TempDetailedCustLedgEntryBuffer."Amount (LCY)" <> 0) or
                    (TempDetailedCustLedgEntryBuffer."Debit Amount" <> 0) or
                    (TempDetailedCustLedgEntryBuffer."Credit Amount" <> 0) or
                    (TempDetailedCustLedgEntryBuffer."Debit Amount (LCY)" <> 0) or
                    (TempDetailedCustLedgEntryBuffer."Credit Amount (LCY)" <> 0))
                then begin
                    LastDtldEntryNo := LastDtldEntryNo + 1;

                    NewDtldCustLedgEntry := TempDetailedCustLedgEntryBuffer;
                    NewDtldCustLedgEntry."Entry No." := LastDtldEntryNo;
                    NewDtldCustLedgEntry.Insert(true);
                end;
            until TempDetailedCustLedgEntryBuffer.Next() = 0;
        TempDetailedCustLedgEntryBuffer.DeleteAll();
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        if EntrdCustLedgEntry.Description = '' then
            EntrdCustLedgEntry.Description := Text009;

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Customer Ledger", '');
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; NewDateComprRetainFields: Record "Date Compr. Retain Fields"; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdCustLedgEntry.Description := Description;
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
        TelemetryDimensions.Add('RetainSelltoCustomerNo', Format(DateComprRetainFields."Retain Sell-to Customer No.", 0, 9));
        TelemetryDimensions.Add('RetainSalespersonCode', Format(DateComprRetainFields."Retain Salesperson Code", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('RetainJnlTemplate', Format(DateComprRetainFields."Retain Journal Template Name", 0, 9));
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4K', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4L', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustLedgEntry2SetFilters(var ToCustLedgEntry: Record "Cust. Ledger Entry"; FromCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeDtldEntryOnAfterDtldCustLedgEntryBufferSetFilters(var DtldCustLedgEntryBuffer: Record "Detailed Cust. Ledg. Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var OriginCustLedgEntry: Record "Cust. Ledger Entry"; var NewCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeDtldEntryOnAfterInitDtldCustLedgEntryBuffer(var DtldCustLedgEntryBuffer: Record "Detailed Cust. Ledg. Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var OriginCustLedgEntry: Record "Cust. Ledger Entry"; var NewCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

