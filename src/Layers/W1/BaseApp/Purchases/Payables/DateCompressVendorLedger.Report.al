// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

report 398 "Date Compress Vendor Ledger"
{
    ApplicationArea = Suite;
    Caption = 'Date Compress Vendor Ledger';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Vendor No.", "Posting Date") where(Open = const(false));
            RequestFilterFields = "Vendor No.", "Vendor Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                VendLedgEntry2 := "Vendor Ledger Entry";
                if not CompressDetails("Vendor Ledger Entry") then
                    CurrReport.Skip();
                VendLedgEntry2.SetCurrentKey("Vendor No.", "Posting Date");
                VendLedgEntry2.CopyFilters("Vendor Ledger Entry");
                VendLedgEntry2.SetRange("Vendor No.", VendLedgEntry2."Vendor No.");
                VendLedgEntry2.SetFilter("Posting Date", DateComprMgt.GetDateFilter(VendLedgEntry2."Posting Date", EntrdDateComprReg, true));
                VendLedgEntry2.SetRange("Vendor Posting Group", VendLedgEntry2."Vendor Posting Group");
                VendLedgEntry2.SetRange("Currency Code", VendLedgEntry2."Currency Code");
                VendLedgEntry2.SetRange("Document Type", VendLedgEntry2."Document Type");

                if DateComprRetainFields."Retain Document No." then
                    VendLedgEntry2.SetRange("Document No.", VendLedgEntry2."Document No.");
                if DateComprRetainFields."Retain Buy-from Vendor No." then
                    VendLedgEntry2.SetRange("Buy-from Vendor No.", VendLedgEntry2."Buy-from Vendor No.");
                if DateComprRetainFields."Retain Purchaser Code" then
                    VendLedgEntry2.SetRange("Purchaser Code", VendLedgEntry2."Purchaser Code");
                if DateComprRetainFields."Retain Global Dimension 1" then
                    VendLedgEntry2.SetRange("Global Dimension 1 Code", VendLedgEntry2."Global Dimension 1 Code");
                if DateComprRetainFields."Retain Global Dimension 2" then
                    VendLedgEntry2.SetRange("Global Dimension 2 Code", VendLedgEntry2."Global Dimension 2 Code");
                if DateComprRetainFields."Retain Journal Template Name" then
                    VendLedgEntry2.SetRange("Journal Templ. Name", VendLedgEntry2."Journal Templ. Name");

                VendLedgEntry2.CalcFields(Amount);
                if VendLedgEntry2.Amount >= 0 then
                    SummarizePositive := true
                else
                    SummarizePositive := false;

                InitNewEntry(NewVendLedgEntry);

                DimBufMgt.CollectDimEntryNo(
                  TempSelectedDim, VendLedgEntry2."Dimension Set ID", VendLedgEntry2."Entry No.",
                  0, false, DimEntryNo);
                ComprDimEntryNo := DimEntryNo;
                SummarizeEntry(NewVendLedgEntry, VendLedgEntry2);
                while VendLedgEntry2.Next() <> 0 do begin
                    VendLedgEntry2.CalcFields(Amount);
                    if ((VendLedgEntry2.Amount >= 0) and SummarizePositive) or
                       ((VendLedgEntry2.Amount < 0) and (not SummarizePositive))
                    then
                        if CompressDetails(VendLedgEntry2) then begin
                            DimBufMgt.CollectDimEntryNo(
                              TempSelectedDim, VendLedgEntry2."Dimension Set ID", VendLedgEntry2."Entry No.",
                              ComprDimEntryNo, true, DimEntryNo);
                            if DimEntryNo = ComprDimEntryNo then
                                SummarizeEntry(NewVendLedgEntry, VendLedgEntry2);
                        end;
                end;

                InsertNewEntry(NewVendLedgEntry, ComprDimEntryNo);

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
                SourceCodeSetup.TestField("Compress Vend. Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress Vendor Ledger", '', TempSelectedDim);
                GLSetup.Get();
                DateComprRetainFields."Retain Global Dimension 1" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Vendor Ledger", '', GLSetup."Global Dimension 1 Code");
                DateComprRetainFields."Retain Global Dimension 2" :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress Vendor Ledger", '', GLSetup."Global Dimension 2 Code");

                GLentry.LockTable();
                NewDtldVendLedgEntry.LockTable();
                NewVendLedgEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLentry.GetLastEntry(LastEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                LastDtldEntryNo := NewDtldVendLedgEntry.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Vendor Ledger"));
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
                    field("EntrdVendLedgEntry.Description"; EntrdVendLedgEntry.Description)
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
                        field("Retain[2]"; DateComprRetainFields."Retain Buy-from Vendor No.")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Buy-from Vendor No.';
                            ToolTip = 'Specifies a filter for the vendor or vendors that you want to compress entries for.';
                        }
                        field("Retain[3]"; DateComprRetainFields."Retain Purchaser Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Purchaser Code';
                            ToolTip = 'Specifies the purchaser for whom vendor ledger entries are date compressed';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress Vendor Ledger", RetainDimText);
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
          3, REPORT::"Date Compress Vendor Ledger", '', RetainDimText, Text010);
        VendLedgEntryFilter := CopyStr("Vendor Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

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
        EntrdVendLedgEntry: Record "Vendor Ledger Entry";
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        GLentry: Record "G/L Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        VendLedgEntryFilter: Text[250];
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        LastDtldEntryNo: Integer;
        LastTmpDtldEntryNo: Integer;
        GLRegExists: Boolean;
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        SummarizePositive: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text004: Label 'Date compressing vendor ledger entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Vendor No.           #1##########\';
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
        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastEntryNo + 1, 0, SourceCodeSetup."Compress Vend. Ledger", '', '');
        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          DATABASE::"Vendor Ledger Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          VendLedgEntryFilter, GLReg."No.", SourceCodeSetup."Compress Vend. Ledger");

        if DateComprRetainFields."Retain Document No." then
            AddFieldContent(NewVendLedgEntry.FieldName("Document No."));
        if DateComprRetainFields."Retain Buy-from Vendor No." then
            AddFieldContent(NewVendLedgEntry.FieldName("Buy-from Vendor No."));
        if DateComprRetainFields."Retain Purchaser Code" then
            AddFieldContent(NewVendLedgEntry.FieldName("Purchaser Code"));
        if DateComprRetainFields."Retain Global Dimension 1" then
            AddFieldContent(NewVendLedgEntry.FieldName("Global Dimension 1 Code"));
        if DateComprRetainFields."Retain Global Dimension 2" then
            AddFieldContent(NewVendLedgEntry.FieldName("Global Dimension 2 Code"));
        if DateComprRetainFields."Retain Journal Template Name" then
            AddFieldContent(NewVendLedgEntry.FieldName("Journal Templ. Name"));

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
        GLentry.Init();
        LastEntryNo := LastEntryNo + 1;
        GLentry."Entry No." := LastEntryNo;
        GLentry."Posting Date" := Today;
        GLentry.Description := EntrdVendLedgEntry.Description;
        GLentry."Source Code" := SourceCodeSetup."Compress Vend. Ledger";
        GLentry."System-Created Entry" := true;
        GLentry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLentry."User ID"));
        GLentry."Transaction No." := NextTransactionNo;
        OnInsertRegistersOnBeforeGLentryInsert(GlEntry);
        GLentry.Insert();
        GLentry.Consistent(GLentry.Amount = 0);
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

        GLentry.LockTable();
        NewDtldVendLedgEntry.LockTable();
        NewVendLedgEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLentry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        FoundLastLedgEntryNo := NewVendLedgEntry.GetLastEntryNo();
        if (LastEntryNo <> FoundLastEntryNo) or
           (LastEntryNo <> FoundLastLedgEntryNo + 1)
        then begin
            LastEntryNo := FoundLastEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters();
        end;
        LastDtldEntryNo := NewDtldVendLedgEntry.GetLastEntryNo();
    end;

    local procedure SummarizeEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry")
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        NewVendLedgEntry."Purchase (LCY)" := NewVendLedgEntry."Purchase (LCY)" + VendLedgEntry."Purchase (LCY)";
        NewVendLedgEntry."Inv. Discount (LCY)" := NewVendLedgEntry."Inv. Discount (LCY)" + VendLedgEntry."Inv. Discount (LCY)";
        NewVendLedgEntry."Original Pmt. Disc. Possible" :=
          NewVendLedgEntry."Original Pmt. Disc. Possible" + VendLedgEntry."Original Pmt. Disc. Possible";
        NewVendLedgEntry."Remaining Pmt. Disc. Possible" :=
          NewVendLedgEntry."Remaining Pmt. Disc. Possible" + VendLedgEntry."Remaining Pmt. Disc. Possible";
        NewVendLedgEntry."Closed by Amount (LCY)" :=
          NewVendLedgEntry."Closed by Amount (LCY)" + VendLedgEntry."Closed by Amount (LCY)";

        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        if DtldVendLedgEntry.Find('-') then begin
            repeat
                SummarizeDtldEntry(DtldVendLedgEntry, NewVendLedgEntry);
            until DtldVendLedgEntry.Next() = 0;
            DtldVendLedgEntry.DeleteAll();
        end;

        VendLedgEntry.Delete();
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(4, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(VendLedgEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        VendLedgEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, VendLedgEntryNo) then begin
            InitNewEntry(NewVendLedgEntry);
            repeat
                VendLedgEntry.Get(VendLedgEntryNo);
                SummarizeEntry(NewVendLedgEntry, VendLedgEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, VendLedgEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewVendLedgEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewVendLedgEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        NewVendLedgEntry.Init();
        NewVendLedgEntry."Entry No." := LastEntryNo;
        NewVendLedgEntry."Vendor No." := VendLedgEntry2."Vendor No.";
        NewVendLedgEntry."Posting Date" := VendLedgEntry2.GetRangeMin("Posting Date");
        NewVendLedgEntry.Description := EntrdVendLedgEntry.Description;
        NewVendLedgEntry."Vendor Posting Group" := VendLedgEntry2."Vendor Posting Group";
        NewVendLedgEntry."Currency Code" := VendLedgEntry2."Currency Code";
        NewVendLedgEntry."Document Type" := VendLedgEntry2."Document Type";
        NewVendLedgEntry."Source Code" := SourceCodeSetup."Compress Vend. Ledger";
        NewVendLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(VendLedgEntry2."User ID"));
        NewVendLedgEntry."Transaction No." := NextTransactionNo;

        if DateComprRetainFields."Retain Document No." then
            NewVendLedgEntry."Document No." := VendLedgEntry2."Document No.";
        if DateComprRetainFields."Retain Buy-from Vendor No." then
            NewVendLedgEntry."Buy-from Vendor No." := VendLedgEntry2."Buy-from Vendor No.";
        if DateComprRetainFields."Retain Purchaser Code" then
            NewVendLedgEntry."Purchaser Code" := VendLedgEntry2."Purchaser Code";
        if DateComprRetainFields."Retain Global Dimension 1" then
            NewVendLedgEntry."Global Dimension 1 Code" := VendLedgEntry2."Global Dimension 1 Code";
        if DateComprRetainFields."Retain Global Dimension 2" then
            NewVendLedgEntry."Global Dimension 2 Code" := VendLedgEntry2."Global Dimension 2 Code";
        if DateComprRetainFields."Retain Journal Template Name" then
            NewVendLedgEntry."Journal Templ. Name" := VendLedgEntry2."Journal Templ. Name";

        Window.Update(1, NewVendLedgEntry."Vendor No.");
        Window.Update(2, NewVendLedgEntry."Posting Date");
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(3, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewVendLedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewVendLedgEntry.Insert();
        InsertDtldEntries();
    end;

    local procedure CompressDetails(VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Posting Date");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        if EntrdDateComprReg."Starting Date" <> 0D then
            DtldVendLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '..%1|%2..',
                CalcDate('<-1D>', EntrdDateComprReg."Starting Date"),
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")))
        else
            DtldVendLedgEntry.SetFilter(
              "Posting Date",
              StrSubstNo(
                '%1..',
                CalcDate('<+1D>', EntrdDateComprReg."Ending Date")));

        exit(DtldVendLedgEntry.IsEmpty());
    end;

    local procedure SummarizeDtldEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var NewVendLedgEntry: Record "Vendor Ledger Entry")
    var
        NewEntry: Boolean;
        PostingDate: Date;
    begin
        if UseDataArchive then
            DataArchive.SaveRecord(DtldVendLedgEntry);
        TempDetailedVendorLedgEntry.SetFilter(
          "Posting Date",
          DateComprMgt.GetDateFilter(DtldVendLedgEntry."Posting Date", EntrdDateComprReg, true));
        PostingDate := TempDetailedVendorLedgEntry.GetRangeMin("Posting Date");
        TempDetailedVendorLedgEntry.SetRange("Posting Date", PostingDate);
        TempDetailedVendorLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type");
        if DateComprRetainFields."Retain Document No." then
            TempDetailedVendorLedgEntry.SetRange("Document No.", "Vendor Ledger Entry"."Document No.");
        if DateComprRetainFields."Retain Buy-from Vendor No." then
            TempDetailedVendorLedgEntry.SetRange("Vendor No.", "Vendor Ledger Entry"."Buy-from Vendor No.");
        if DateComprRetainFields."Retain Global Dimension 1" then
            TempDetailedVendorLedgEntry.SetRange("Initial Entry Global Dim. 1", "Vendor Ledger Entry"."Global Dimension 1 Code");
        if DateComprRetainFields."Retain Global Dimension 2" then
            TempDetailedVendorLedgEntry.SetRange("Initial Entry Global Dim. 2", "Vendor Ledger Entry"."Global Dimension 2 Code");

        OnSummarizeDtldEntryOnAfterTempDetailedVendorLedgEntrySetFilters(TempDetailedVendorLedgEntry, DtldVendLedgEntry, NewVendLedgEntry, "Vendor Ledger Entry");
        if not TempDetailedVendorLedgEntry.Find('-') then begin
            TempDetailedVendorLedgEntry.Reset();
            Clear(TempDetailedVendorLedgEntry);

            LastTmpDtldEntryNo := LastTmpDtldEntryNo + 1;
            TempDetailedVendorLedgEntry."Entry No." := LastTmpDtldEntryNo;
            TempDetailedVendorLedgEntry."Posting Date" := PostingDate;
            TempDetailedVendorLedgEntry."Document Type" := NewVendLedgEntry."Document Type";
            TempDetailedVendorLedgEntry."Initial Document Type" := NewVendLedgEntry."Document Type";
            TempDetailedVendorLedgEntry."Document No." := NewVendLedgEntry."Document No.";
            TempDetailedVendorLedgEntry."Entry Type" := DtldVendLedgEntry."Entry Type";
            TempDetailedVendorLedgEntry."Vendor Ledger Entry No." := NewVendLedgEntry."Entry No.";
            TempDetailedVendorLedgEntry."Vendor No." := NewVendLedgEntry."Vendor No.";
            TempDetailedVendorLedgEntry."Currency Code" := NewVendLedgEntry."Currency Code";
            TempDetailedVendorLedgEntry."User ID" := NewVendLedgEntry."User ID";
            TempDetailedVendorLedgEntry."Source Code" := NewVendLedgEntry."Source Code";
            TempDetailedVendorLedgEntry."Transaction No." := NewVendLedgEntry."Transaction No.";
            TempDetailedVendorLedgEntry."Journal Batch Name" := NewVendLedgEntry."Journal Batch Name";
            TempDetailedVendorLedgEntry."Reason Code" := NewVendLedgEntry."Reason Code";
            TempDetailedVendorLedgEntry."Initial Entry Due Date" := NewVendLedgEntry."Due Date";
            TempDetailedVendorLedgEntry."Initial Entry Global Dim. 1" := NewVendLedgEntry."Global Dimension 1 Code";
            TempDetailedVendorLedgEntry."Initial Entry Global Dim. 2" := NewVendLedgEntry."Global Dimension 2 Code";

            NewEntry := true;
        end;

        TempDetailedVendorLedgEntry.Amount :=
          TempDetailedVendorLedgEntry.Amount + DtldVendLedgEntry.Amount;
        TempDetailedVendorLedgEntry."Amount (LCY)" :=
          TempDetailedVendorLedgEntry."Amount (LCY)" + DtldVendLedgEntry."Amount (LCY)";
        TempDetailedVendorLedgEntry."Debit Amount" :=
          TempDetailedVendorLedgEntry."Debit Amount" + DtldVendLedgEntry."Debit Amount";
        TempDetailedVendorLedgEntry."Credit Amount" :=
          TempDetailedVendorLedgEntry."Credit Amount" + DtldVendLedgEntry."Credit Amount";
        TempDetailedVendorLedgEntry."Debit Amount (LCY)" :=
          TempDetailedVendorLedgEntry."Debit Amount (LCY)" + DtldVendLedgEntry."Debit Amount (LCY)";
        TempDetailedVendorLedgEntry."Credit Amount (LCY)" :=
          TempDetailedVendorLedgEntry."Credit Amount (LCY)" + DtldVendLedgEntry."Credit Amount (LCY)";

        if NewEntry then
            TempDetailedVendorLedgEntry.Insert()
        else
            TempDetailedVendorLedgEntry.Modify();
    end;

    local procedure InsertDtldEntries()
    begin
        TempDetailedVendorLedgEntry.Reset();
        if TempDetailedVendorLedgEntry.Find('-') then
            repeat
                if ((TempDetailedVendorLedgEntry.Amount <> 0) or
                    (TempDetailedVendorLedgEntry."Amount (LCY)" <> 0) or
                    (TempDetailedVendorLedgEntry."Debit Amount" <> 0) or
                    (TempDetailedVendorLedgEntry."Credit Amount" <> 0) or
                    (TempDetailedVendorLedgEntry."Debit Amount (LCY)" <> 0) or
                    (TempDetailedVendorLedgEntry."Credit Amount (LCY)" <> 0))
                then begin
                    LastDtldEntryNo := LastDtldEntryNo + 1;

                    NewDtldVendLedgEntry := TempDetailedVendorLedgEntry;
                    NewDtldVendLedgEntry."Entry No." := LastDtldEntryNo;
                    NewDtldVendLedgEntry.Insert(true);
                end;
            until TempDetailedVendorLedgEntry.Next() = 0;
        TempDetailedVendorLedgEntry.DeleteAll();
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
        if EntrdVendLedgEntry.Description = '' then
            EntrdVendLedgEntry.Description := Text009;

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress Vendor Ledger", '');
        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; Description: Text[100]; NewDateComprRetainFields: Record "Date Compr. Retain Fields"; RetainDimensionText: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdVendLedgEntry.Description := Description;
        DateComprRetainFields := NewDateComprRetainFields;
        RetainDimText := RetainDimensionText;
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
        TelemetryDimensions.Add('RetainDocumentNo', Format(DateComprRetainFields."Retain Document No.", 0, 9));
        TelemetryDimensions.Add('RetainBuyFromVendorNo', Format(DateComprRetainFields."Retain Buy-from Vendor No.", 0, 9));
        TelemetryDimensions.Add('RetainPurchaserCode', Format(DateComprRetainFields."Retain Purchaser Code", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('RetainJnlTemplate', Format(DateComprRetainFields."Retain Journal Template Name", 0, 9));
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4Y', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4Z', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRegistersOnBeforeGLentryInsert(var GLentry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeDtldEntryOnAfterTempDetailedVendorLedgEntrySetFilters(var TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var NewVendorLedgerEntry: Record "Vendor Ledger Entry"; var OriginVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

