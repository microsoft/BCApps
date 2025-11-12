// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

report 5696 "Date Compress FA Ledger"
{
    Caption = 'Date Compress FA Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "FA Ledger Entry" = rimd,
                  TableData "FA Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Ledger Entry"; "FA Ledger Entry")
        {
            DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Date");
            RequestFilterFields = "FA No.", "Depreciation Book Code";

            trigger OnAfterGetRecord()
            begin
                if "FA No." <> '' then begin
                    if "FA Posting Category" <> "FA Posting Category"::" " then
                        CurrReport.Skip();
                    case "FA Posting Type" of
                        "FA Posting Type"::"Proceeds on Disposal",
                      "FA Posting Type"::"Gain/Loss":
                            CurrReport.Skip();
                    end;
                end;
                FALedgEntry2 := "FA Ledger Entry";
                FALedgEntry2.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                FALedgEntry2.CopyFilters("FA Ledger Entry");

                FALedgEntry2.SetRange("FA No.", FALedgEntry2."FA No.");
                FALedgEntry2.SetRange("Depreciation Book Code", FALedgEntry2."Depreciation Book Code");
                FALedgEntry2.SetRange("FA Posting Category", FALedgEntry2."FA Posting Category");
                FALedgEntry2.SetRange("FA Posting Type", FALedgEntry2."FA Posting Type");
                FALedgEntry2.SetRange("Part of Book Value", FALedgEntry2."Part of Book Value");
                FALedgEntry2.SetRange("Part of Depreciable Basis", FALedgEntry2."Part of Depreciable Basis");
                FALedgEntry2.SetRange("FA Posting Group", FALedgEntry2."FA Posting Group");
                FALedgEntry2.SetRange("Document Type", FALedgEntry2."Document Type");

                FALedgEntry2.SetFilter("FA Posting Date", DateComprMgt.GetDateFilter(FALedgEntry2."FA Posting Date", EntrdDateComprReg, true));

                LastEntryNo := LastEntryNo + 1;

                NewFALedgEntry.Init();
                NewFALedgEntry."Entry No." := LastEntryNo;
                NewFALedgEntry."FA No." := FALedgEntry2."FA No.";
                NewFALedgEntry."Depreciation Book Code" := FALedgEntry2."Depreciation Book Code";
                NewFALedgEntry."FA Posting Category" := FALedgEntry2."FA Posting Category";
                NewFALedgEntry."FA Posting Type" := FALedgEntry2."FA Posting Type";
                NewFALedgEntry."Part of Book Value" := FALedgEntry2."Part of Book Value";
                NewFALedgEntry."Part of Depreciable Basis" := FALedgEntry2."Part of Depreciable Basis";
                NewFALedgEntry."FA Posting Group" := FALedgEntry2."FA Posting Group";
                NewFALedgEntry."Document Type" := FALedgEntry2."Document Type";
                NewFALedgEntry."FA Posting Date" := FALedgEntry2.GetRangeMin("FA Posting Date");
                NewFALedgEntry."Posting Date" := FALedgEntry2.GetRangeMin("FA Posting Date");
                NewFALedgEntry.Description := EntrdFALedgEntry.Description;
                NewFALedgEntry."Source Code" := SourceCodeSetup."Compress FA Ledger";
                NewFALedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(FALedgEntry2."User ID"));
                Window.Update(1, NewFALedgEntry."FA No.");
                Window.Update(2, NewFALedgEntry."FA Posting Date");
                DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                Window.Update(3, DateComprReg."No. of New Records");

                if RetainNo(FALedgEntry2.FieldNo("Document No.")) then begin
                    FALedgEntry2.SetRange("Document No.", FALedgEntry2."Document No.");
                    NewFALedgEntry."Document No." := FALedgEntry2."Document No.";
                end;
                if RetainNo(FALedgEntry2.FieldNo("Reclassification Entry")) then begin
                    FALedgEntry2.SetRange("Reclassification Entry", FALedgEntry2."Reclassification Entry");
                    NewFALedgEntry."Reclassification Entry" := FALedgEntry2."Reclassification Entry";
                end;
                if RetainNo(FALedgEntry2.FieldNo("Index Entry")) then begin
                    FALedgEntry2.SetRange("Index Entry", FALedgEntry2."Index Entry");
                    NewFALedgEntry."Index Entry" := FALedgEntry2."Index Entry";
                end;
                if RetainNo(FALedgEntry2.FieldNo("Global Dimension 1 Code")) then begin
                    FALedgEntry2.SetRange("Global Dimension 1 Code", FALedgEntry2."Global Dimension 1 Code");
                    NewFALedgEntry."Global Dimension 1 Code" := FALedgEntry2."Global Dimension 1 Code";
                end;
                if RetainNo(FALedgEntry2.FieldNo("Global Dimension 2 Code")) then begin
                    FALedgEntry2.SetRange("Global Dimension 2 Code", FALedgEntry2."Global Dimension 2 Code");
                    NewFALedgEntry."Global Dimension 2 Code" := FALedgEntry2."Global Dimension 2 Code";
                end;
                if FALedgEntry2.Quantity >= 0 then
                    FALedgEntry2.SetFilter(Quantity, '>=0')
                else
                    FALedgEntry2.SetFilter(Quantity, '<0');
                FADimMgt.GetFALedgEntryDimID(0, FALedgEntry2."Dimension Set ID");

                if FALedgEntry2."FA No." <> '' then
                    FindEqualPostingType(FALedgEntry2);
                repeat
                    if TempFALedgEntry.Get(FALedgEntry2."Entry No.") or (FALedgEntry2."FA No." = '') then begin
                        EqualDim := FADimMgt.TestEqualFALedgEntryDimID(FALedgEntry2."Dimension Set ID");
                        if EqualDim then
                            SummarizeEntry(NewFALedgEntry, FALedgEntry2);
                    end else
                        EqualDim := false;
                until (FALedgEntry2.Next() = 0) or not EqualDim;
                InsertNewEntry(NewFALedgEntry);

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(FAReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(FAReg, DateComprReg);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text004, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008 +
                  Text009);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress FA Ledger");

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Compress FA Ledger", '', TempSelectedDim);
                FADimMgt.GetSelectedDim(TempSelectedDim);
                GLSetup.Get();
                Retain[4] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress FA Ledger", '', GLSetup."Global Dimension 1 Code");
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Compress FA Ledger", '', GLSetup."Global Dimension 2 Code");

                NewFALedgEntry.LockTable();
                FAReg.LockTable();
                DateComprReg.LockTable();

                LastEntryNo := FALedgEntry2.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("FA Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress FA Ledger"));
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
                        ToolTip = 'Specifies the first date to be included in the date compression. The compression affects all fixed asset ledger entries from this date to the Ending Date.';
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
                        ToolTip = 'Specifies the length of the period for which combined entries will be created. If you selected the period length Quarter, Month or Week, then only entries with a common accounting period are compressed.';
                    }
                    field("EntrdFALedgEntry.Description"; EntrdFALedgEntry.Description)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; Retain[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                        }
                        field("Retain[2]"; Retain[2])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Reclassification Entry';
                            ToolTip = 'Specifies which reclassification entry to date compress.';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Index Entry';
                            ToolTip = 'Specifies the index entry to be data compressed. With the Index Fixed Assets batch job, you can index fixed assets that are linked to a specific depreciation book. The batch job creates entries in a journal based on the conditions that you specify. You can then post the journal or adjust the entries before posting, if necessary.';
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
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Compress FA Ledger", RetainDimText);
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
            if EntrdFALedgEntry.Description = '' then
                EntrdFALedgEntry.Description := Text010;

            InsertField("FA Ledger Entry".FieldNo("Document No."), "FA Ledger Entry".FieldCaption("Document No."));
            InsertField("FA Ledger Entry".FieldNo("Reclassification Entry"), "FA Ledger Entry".FieldCaption("Reclassification Entry"));
            InsertField("FA Ledger Entry".FieldNo("Index Entry"), "FA Ledger Entry".FieldCaption("Index Entry"));
            InsertField("FA Ledger Entry".FieldNo("Global Dimension 1 Code"), "FA Ledger Entry".FieldCaption("Global Dimension 1 Code"));
            InsertField("FA Ledger Entry".FieldNo("Global Dimension 2 Code"), "FA Ledger Entry".FieldCaption("Global Dimension 2 Code"));

            RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Compress FA Ledger", '');
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
          3, REPORT::"Date Compress FA Ledger", '', RetainDimText, Text012);
        FALedgEntryFilter := CopyStr("FA Ledger Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

        FALedgEntry2.Copy("FA Ledger Entry");
        FALedgEntry2.SetRange("FA No.");
        FALedgEntry2.SetRange("Depreciation Book Code");
        if FALedgEntry2.GetFilters <> '' then
            Error(
              Text000,
              FALedgEntry2.FieldCaption("FA No."), FALedgEntry2.FieldCaption("Depreciation Book Code"));
        FALedgEntry2.Reset();
        Clear(FALedgEntry2);

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
        FAReg: Record "FA Register";
        EntrdFALedgEntry: Record "FA Ledger Entry";
        NewFALedgEntry: Record "FA Ledger Entry";
        FALedgEntry2: Record "FA Ledger Entry";
        TempFALedgEntry: Record "FA Ledger Entry" temporary;
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DateComprMgt: Codeunit DateComprMgt;
        DimMgt: Codeunit DimensionManagement;
        FACheckConsistency: Codeunit "FA Check Consistency";
        FADimMgt: Codeunit FADimensionManagement;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        FALedgEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        FARegExists: Boolean;
        i: Integer;
        RetainDimText: Text[250];
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;
        EqualDim: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You may set filters only on %1 and %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text005: Label 'Date compressing FA ledger entries...\\';
#pragma warning disable AA0470
        Text006: Label 'FA No.               #1##########\';
        Text007: Label 'Date                 #2######\\';
        Text008: Label 'No. of new entries   #3######\';
        Text009: Label 'No. of entries del.  #4######';
#pragma warning restore AA0470
        Text010: Label 'Date Compressed';
#pragma warning disable AA0470
        Text011: Label 'The date compression has been interrupted. Another user changed the table %1.';
#pragma warning restore AA0470
        Text012: Label 'Retain Dimensions';
#pragma warning restore AA0074
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    begin
        FAReg.Init();
        FAReg."No." := FAReg.GetLastEntryNo() + 1;
        FAReg."Journal Type" := FAReg."Journal Type"::"Fixed Asset";
        FAReg."Source Code" := SourceCodeSetup."Compress FA Ledger";
        FAReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(FAReg."User ID"));
        FAReg."From Entry No." := LastEntryNo + 1;

        DateComprReg.InitRegister(
          DATABASE::"FA Ledger Entry", DateComprReg.GetLastEntryNo() + 1, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date",
          EntrdDateComprReg."Period Length", FALedgEntryFilter, FAReg."No.", SourceCodeSetup."Compress FA Ledger");

        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        FARegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var FAReg: Record "FA Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FAReg2: Record "FA Register";
    begin
        FAReg."To Entry No." := NewFALedgEntry."Entry No.";

        if FARegExists then begin
            FAReg.Modify();
            DateComprReg.Modify();
        end else begin
            FAReg.Insert();
            DateComprReg.Insert();
            FARegExists := true;
        end;
        FALedgEntry2.Reset();
        LastEntryNo := FALedgEntry2.GetLastEntryNo();
        Commit();

        NewFALedgEntry.LockTable();
        FAReg.LockTable();
        DateComprReg.LockTable();

        if LastEntryNo <> FALedgEntry2.GetLastEntryNo() then
            Error(
              Text011, FALedgEntry2.TableCaption());

        if FAReg."No." <> FAReg2.GetLastEntryNo() then
            Error(
              Text011, FAReg.TableCaption());
    end;

    local procedure InsertField(Number: Integer; Name: Text[100])
    begin
        NoOfFields := NoOfFields + 1;
        FieldNumber[NoOfFields] := Number;
        FieldNameArray[NoOfFields] := Name;
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

    local procedure FindEqualPostingType(var FALedgEntry2: Record "FA Ledger Entry")
    var
        FALedgEntry: Record "FA Ledger Entry";
        EqualPostingType: Boolean;
    begin
        TempFALedgEntry.DeleteAll();
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", FALedgEntry2."FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", FALedgEntry2."Depreciation Book Code");
        FALedgEntry.SetRange("Entry No.", 0, "FA Ledger Entry".GetRangeMax("Entry No."));
        FALedgEntry.Get(FALedgEntry2."Entry No.");
        repeat
            EqualPostingType :=
              (FALedgEntry2."FA Posting Category" = FALedgEntry."FA Posting Category") and
              (FALedgEntry2."FA Posting Type" = FALedgEntry."FA Posting Type") and
              (FALedgEntry2."Part of Book Value" = FALedgEntry."Part of Book Value") and
              (FALedgEntry2."Part of Depreciable Basis" = FALedgEntry."Part of Depreciable Basis");
            if EqualPostingType then begin
                TempFALedgEntry."Entry No." := FALedgEntry."Entry No.";
                TempFALedgEntry.Insert();
            end;
        until (FALedgEntry.Next() = 0) or not EqualPostingType;
    end;

    local procedure SummarizeEntry(var NewFALedgEntry: Record "FA Ledger Entry"; FALedgEntry: Record "FA Ledger Entry")
    begin
        NewFALedgEntry.Quantity := NewFALedgEntry.Quantity + FALedgEntry.Quantity;
        NewFALedgEntry.Amount := NewFALedgEntry.Amount + FALedgEntry.Amount;
        FALedgEntry.Delete();
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(4, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(FALedgEntry);
    end;

    local procedure InsertNewEntry(var NewFALedgEntry: Record "FA Ledger Entry")
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        FADimMgt.GetDimensions(TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewFALedgEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewFALedgEntry.Insert();
        if NewFALedgEntry."FA No." <> '' then
            FACheckConsistency.SetFAPostingDate(NewFALedgEntry, false);
    end;

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date; PeriodLengthFrom: Option; DescriptionFrom: Text[100]; RetainDimTextFrom: Text[250])
    begin
        InitializeRequest(StartingDateFrom, EndingDateFrom, PeriodLengthFrom, DescriptionFrom, RetainDimTextFrom, true);
    end;

    procedure InitializeRequest(StartingDateFrom: Date; EndingDateFrom: Date; PeriodLengthFrom: Option; DescriptionFrom: Text[100]; RetainDimTextFrom: Text[250]; DoUseDataArchive: Boolean)
    begin
        EntrdDateComprReg."Starting Date" := StartingDateFrom;
        EntrdDateComprReg."Ending Date" := EndingDateFrom;
        EntrdDateComprReg."Period Length" := PeriodLengthFrom;
        EntrdFALedgEntry.Description := DescriptionFrom;
        RetainDimText := RetainDimTextFrom;

        InsertField("FA Ledger Entry".FieldNo("Reclassification Entry"), "FA Ledger Entry".FieldCaption("Reclassification Entry"));
        InsertField("FA Ledger Entry".FieldNo("Global Dimension 1 Code"), "FA Ledger Entry".FieldCaption("Global Dimension 1 Code"));
        InsertField("FA Ledger Entry".FieldNo("Global Dimension 2 Code"), "FA Ledger Entry".FieldCaption("Global Dimension 2 Code"));

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    procedure SetRetainDocumentNo(RetainValue: Boolean)
    begin
        Retain[1] := RetainValue;
        InsertField("FA Ledger Entry".FieldNo("Document No."), "FA Ledger Entry".FieldCaption("Document No."));
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
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4M', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4N', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    procedure SetRetainIndexEntry(RetainValue: Boolean)
    begin
        Retain[3] := RetainValue;
        InsertField("FA Ledger Entry".FieldNo("Index Entry"), "FA Ledger Entry".FieldCaption("Index Entry"));
    end;
}
