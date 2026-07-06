// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

report 7139 "Date Comp. Item Budget Entries"
{
    Caption = 'Date Compr. Item Budget Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Budget Entry"; "Item Budget Entry")
        {
            DataItemTableView = sorting("Analysis Area", "Budget Name", "Item No.", Date);
            RequestFilterFields = "Budget Name", "Item No.";

            trigger OnAfterGetRecord()
            var
                ItemBudgetName: Record "Item Budget Name";
            begin
                ItemBudgetName.Get("Analysis Area", "Budget Name");
                Retain[3] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Comp. Item Budget Entries", '', ItemBudgetName."Budget Dimension 1 Code");
                Retain[4] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Comp. Item Budget Entries", '', ItemBudgetName."Budget Dimension 2 Code");
                Retain[5] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Comp. Item Budget Entries", '', ItemBudgetName."Budget Dimension 3 Code");
                ItemBudgetEntry2 := "Item Budget Entry";
                ItemBudgetEntry2.SetCurrentKey("Analysis Area", "Budget Name", "Item No.", Date);
                ItemBudgetEntry2.CopyFilters("Item Budget Entry");
                ItemBudgetEntry2.SetFilter(Date, DateComprMgt.GetDateFilter(ItemBudgetEntry2.Date, EntrdDateComprReg, false));
                ItemBudgetEntry2.SetRange("Analysis Area", ItemBudgetEntry2."Analysis Area");
                ItemBudgetEntry2.SetRange("Budget Name", ItemBudgetEntry2."Budget Name");
                ItemBudgetEntry2.SetRange("Item No.", ItemBudgetEntry2."Item No.");

                LastEntryNo := LastEntryNo + 1;

                if RetainNo(ItemBudgetEntry2.FieldNo("Global Dimension 1 Code")) then
                    ItemBudgetEntry2.SetRange(ItemBudgetEntry2."Global Dimension 1 Code", ItemBudgetEntry2."Global Dimension 1 Code");
                if RetainNo(ItemBudgetEntry2.FieldNo("Global Dimension 2 Code")) then
                    ItemBudgetEntry2.SetRange(ItemBudgetEntry2."Global Dimension 2 Code", ItemBudgetEntry2."Global Dimension 2 Code");
                if ItemBudgetEntry2.Quantity >= 0 then
                    ItemBudgetEntry2.SetFilter(Quantity, '>=0')
                else
                    ItemBudgetEntry2.SetFilter(Quantity, '<0');
                if ItemBudgetEntry2."Cost Amount" >= 0 then
                    ItemBudgetEntry2.SetFilter("Cost Amount", '>=0')
                else
                    ItemBudgetEntry2.SetFilter("Cost Amount", '<0');
                if ItemBudgetEntry2."Sales Amount" >= 0 then
                    ItemBudgetEntry2.SetFilter("Sales Amount", '>=0')
                else
                    ItemBudgetEntry2.SetFilter("Sales Amount", '<0');

                InitNewEntry(NewItemBudgetEntry);

                DimBufMgt.CollectDimEntryNo(
                  TempSelectedDim, ItemBudgetEntry2."Dimension Set ID", ItemBudgetEntry2."Entry No.", 0, false, DimEntryNo);
                ComprDimEntryNo := DimEntryNo;
                SummarizeEntry(NewItemBudgetEntry, ItemBudgetEntry2);
                while ItemBudgetEntry2.Next() <> 0 do begin
                    DimBufMgt.CollectDimEntryNo(
                      TempSelectedDim, ItemBudgetEntry2."Dimension Set ID", ItemBudgetEntry2."Entry No.", ComprDimEntryNo, true, DimEntryNo);
                    if DimEntryNo = ComprDimEntryNo then
                        SummarizeEntry(NewItemBudgetEntry, ItemBudgetEntry2);
                end;

                InsertNewEntry(NewItemBudgetEntry, ComprDimEntryNo);

                ComprCollectedEntries();

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(DateComprReg);
                    Commit();
                    ItemBudgetEntry2.LockTable();
                    LastEntryNo := ItemBudgetEntry2.GetLastEntryNo();
                end;
            end;

            trigger OnPostDataItem()
            var
                UpdateAnalysisView: Codeunit "Update Analysis View";
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(DateComprReg);

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
                DateComprReg."Starting Date" := EntrdDateComprReg."Starting Date";
                DateComprReg."Ending Date" := EntrdDateComprReg."Ending Date";
                DateComprReg."Period Length" := EntrdDateComprReg."Period Length";

                if AnalysisView.FindFirst() then begin
                    AnalysisView.CheckDimensionsAreRetained(3, REPORT::"Date Comp. Item Budget Entries", true);
                    if not SkipAnalysisViewUpdateCheck then
                        AnalysisView.CheckViewsAreUpdated();
                    Commit();
                end;

                SelectedDim.GetSelectedDim(
                  UserId, 3, REPORT::"Date Comp. Item Budget Entries", '', TempSelectedDim);
                GLSetup.Get();
                Retain[1] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Comp. Item Budget Entries", '', GLSetup."Global Dimension 1 Code");
                Retain[2] :=
                  TempSelectedDim.Get(
                    UserId, 3, REPORT::"Date Comp. Item Budget Entries", '', GLSetup."Global Dimension 2 Code");

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Item Budget");

                ItemBudgetEntry2.LockTable();
                LastEntryNo := ItemBudgetEntry2.GetLastEntryNo();
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
                SetRange("Analysis Area", AnalysisAreaSelection);

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Comp. Item Budget Entries"));
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
                    field(AnalysisArea; AnalysisAreaSelection)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Analysis Area';
                        ToolTip = 'Specifies the analysis area of the date component item budget entry.';
                    }
                    field(StartingDate; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Starting Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the first date to be included in the date compression.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Ending Date';
                        ClosingDates = true;
                        ToolTip = 'Specifies the end date.';

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
                    }
                    field(PeriodLength; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the length of the period whose entries will be combined. Choose the field to see the options.';
                    }
                    field(PostingDescription; EntrdItemBudgetEntry.Description)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a text that will accompany the entries resulting from the compression. The default description is "Date Compressed."';
                    }
                    field(RetainDimensions; RetainDimText)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retain Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the fields you want to retain the contents of even though the entries will be compressed. The more fields you select, the more detailed the compressed entries will be.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Date Comp. Item Budget Entries", RetainDimText);
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
            InitializeVariables();
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
          3, REPORT::"Date Comp. Item Budget Entries", '', RetainDimText, Text009);
        ItemBudgetEntryFilter := "Item Budget Entry".GetFilters();

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
        EntrdItemBudgetEntry: Record "Item Budget Entry";
        NewItemBudgetEntry: Record "Item Budget Entry";
        ItemBudgetEntry2: Record "Item Budget Entry";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        AnalysisView: Record "Item Analysis View";
        DateComprMgt: Codeunit DateComprMgt;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        DataArchive: Codeunit "Data Archive";
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;
        Window: Dialog;
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastEntryNo: Integer;
        LowestEntryNo: Integer;
        NoOfDeleted: Integer;
        i: Integer;
        ComprDimEntryNo: Integer;
        DimEntryNo: Integer;
        RetainDimText: Text[250];
        AnalysisAreaSelection: Enum "Analysis Area Type";
        ItemBudgetEntryFilter: Text;
        SkipAnalysisViewUpdateCheck: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text003: Label 'Date compressing Item budget entries...\\';
#pragma warning disable AA0470
        Text004: Label 'Budget Name          #1##########\';
        Text005: Label 'Item No.             #2##########\';
        Text006: Label 'Date                 #3######\\';
        Text007: Label 'No. of new entries   #4######\';
        Text008: Label 'No. of entries del.  #5######';
#pragma warning restore AA0470
        Text009: Label 'Retain Dimensions';
#pragma warning restore AA0074
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    begin
        DateComprReg.Init();
        DateComprReg."No." := DateComprReg.GetLastEntryNo() + 1;
        DateComprReg."Table ID" := DATABASE::"Item Budget Entry";
        DateComprReg."Creation Date" := Today;
        DateComprReg."Starting Date" := EntrdDateComprReg."Starting Date";
        DateComprReg."Ending Date" := EntrdDateComprReg."Ending Date";
        DateComprReg."Period Length" := EntrdDateComprReg."Period Length";
        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);
        DateComprReg.Filter := CopyStr(ItemBudgetEntryFilter, 1, MaxStrLen(DateComprReg.Filter));
        DateComprReg."Register No." := "Item Budget Entry"."Entry No.";
        DateComprReg."Source Code" := SourceCodeSetup."Compress Item Budget";
        DateComprReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(DateComprReg."User ID"));

        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var DateComprReg: Record "Date Compr. Register")
    var
        CurrLastEntryNo: Integer;
    begin
        DateComprReg.Insert();

        NewItemBudgetEntry.LockTable();
        DateComprReg.LockTable();

        ItemBudgetEntry2.Reset();
        CurrLastEntryNo := ItemBudgetEntry2.GetLastEntryNo();
        if LastEntryNo <> CurrLastEntryNo then begin
            LastEntryNo := CurrLastEntryNo;
            InitRegisters();
        end;
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

    local procedure SummarizeEntry(var NewItemBudgetEntry: Record "Item Budget Entry"; ItemBudgetEntry: Record "Item Budget Entry")
    begin
        NewItemBudgetEntry.Quantity := NewItemBudgetEntry.Quantity + ItemBudgetEntry.Quantity;
        NewItemBudgetEntry."Cost Amount" := NewItemBudgetEntry."Cost Amount" + ItemBudgetEntry."Cost Amount";
        NewItemBudgetEntry."Sales Amount" := NewItemBudgetEntry."Sales Amount" + ItemBudgetEntry."Sales Amount";
        ItemBudgetEntry.Delete();
        if ItemBudgetEntry."Entry No." < LowestEntryNo then
            LowestEntryNo := ItemBudgetEntry."Entry No.";
        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
        Window.Update(5, DateComprReg."No. Records Deleted");
        if UseDataArchive then
            DataArchive.SaveRecord(ItemBudgetEntry);
    end;

    local procedure ComprCollectedEntries()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        OldDimEntryNo: Integer;
        Found: Boolean;
        ItemBudgetEntryNo: Integer;
    begin
        OldDimEntryNo := 0;
        if DimBufMgt.FindFirstDimEntryNo(DimEntryNo, ItemBudgetEntryNo) then begin
            InitNewEntry(NewItemBudgetEntry);
            repeat
                ItemBudgetEntry.Get(ItemBudgetEntryNo);
                SummarizeEntry(ItemBudgetEntry, ItemBudgetEntry);
                OldDimEntryNo := DimEntryNo;
                Found := DimBufMgt.NextDimEntryNo(DimEntryNo, ItemBudgetEntryNo);
                if (OldDimEntryNo <> DimEntryNo) or not Found then begin
                    InsertNewEntry(NewItemBudgetEntry, OldDimEntryNo);
                    if Found then
                        InitNewEntry(NewItemBudgetEntry);
                end;
                OldDimEntryNo := DimEntryNo;
            until not Found;
        end;
        DimBufMgt.DeleteAllDimEntryNo();
    end;

    procedure InitNewEntry(var NewItemBudgetEntry: Record "Item Budget Entry")
    begin
        LastEntryNo := LastEntryNo + 1;

        NewItemBudgetEntry.Init();
        NewItemBudgetEntry."Entry No." := LastEntryNo;
        NewItemBudgetEntry."Analysis Area" := AnalysisAreaSelection;
        NewItemBudgetEntry."Budget Name" := ItemBudgetEntry2."Budget Name";
        NewItemBudgetEntry."Item No." := ItemBudgetEntry2."Item No.";
        NewItemBudgetEntry.Date := ItemBudgetEntry2.GetRangeMin(ItemBudgetEntry2.Date);
        NewItemBudgetEntry.Description := EntrdItemBudgetEntry.Description;
        NewItemBudgetEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ItemBudgetEntry2."User ID"));

        if RetainNo(ItemBudgetEntry2.FieldNo("Global Dimension 1 Code")) then
            NewItemBudgetEntry."Global Dimension 1 Code" := ItemBudgetEntry2."Global Dimension 1 Code";
        if RetainNo(ItemBudgetEntry2.FieldNo("Global Dimension 2 Code")) then
            NewItemBudgetEntry."Global Dimension 2 Code" := ItemBudgetEntry2."Global Dimension 2 Code";
        if RetainNo(ItemBudgetEntry2.FieldNo("Budget Dimension 1 Code")) then
            NewItemBudgetEntry."Budget Dimension 1 Code" := ItemBudgetEntry2."Budget Dimension 1 Code";
        if RetainNo(ItemBudgetEntry2.FieldNo("Budget Dimension 2 Code")) then
            NewItemBudgetEntry."Budget Dimension 2 Code" := ItemBudgetEntry2."Budget Dimension 2 Code";
        if RetainNo(ItemBudgetEntry2.FieldNo("Budget Dimension 3 Code")) then
            NewItemBudgetEntry."Budget Dimension 3 Code" := ItemBudgetEntry2."Budget Dimension 3 Code";

        Window.Update(1, NewItemBudgetEntry."Budget Name");
        Window.Update(2, NewItemBudgetEntry."Item No.");
        Window.Update(3, NewItemBudgetEntry.Date);
        DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
        Window.Update(4, DateComprReg."No. of New Records");
    end;

    local procedure InsertNewEntry(var NewItemBudgetEntry: Record "Item Budget Entry"; DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(DimEntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
        NewItemBudgetEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        NewItemBudgetEntry.Insert();
    end;

    procedure InitializeRequest(AnalAreaSelection: Option; StartDate: Date; EndDate: Date; PeriodLength: Option; Desc: Text[100]; RetainDimensions: Text[250])
    begin
        InitializeRequest(AnalAreaSelection, StartDate, EndDate, PeriodLength, Desc, RetainDimensions, true);
    end;

    procedure InitializeRequest(AnalAreaSelection: Option; StartDate: Date; EndDate: Date; PeriodLength: Option; Desc: Text[100]; RetainDimensions: Text[250]; DoUseDataArchive: Boolean)
    begin
        InitializeVariables();
        AnalysisAreaSelection := "Analysis Area Type".FromInteger(AnalAreaSelection);
        EntrdDateComprReg."Starting Date" := StartDate;
        EntrdDateComprReg."Ending Date" := EndDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        EntrdItemBudgetEntry.Description := Desc;
        RetainDimText := RetainDimensions;
        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    local procedure InitializeVariables()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();

        InsertField("Item Budget Entry".FieldNo("Global Dimension 1 Code"), "Item Budget Entry".FieldCaption("Global Dimension 1 Code"));
        InsertField("Item Budget Entry".FieldNo("Global Dimension 2 Code"), "Item Budget Entry".FieldCaption("Global Dimension 2 Code"));
        InsertField("Item Budget Entry".FieldNo("Budget Dimension 1 Code"), "Item Budget Entry".FieldCaption("Budget Dimension 1 Code"));
        InsertField("Item Budget Entry".FieldNo("Budget Dimension 2 Code"), "Item Budget Entry".FieldCaption("Budget Dimension 2 Code"));
        InsertField("Item Budget Entry".FieldNo("Budget Dimension 3 Code"), "Item Budget Entry".FieldCaption("Budget Dimension 3 Code"));

        RetainDimText := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Date Comp. Item Budget Entries", '');

        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists;
    end;

    procedure SetSkipAnalysisViewUpdateCheck();
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
        TelemetryDimensions.Add('PeriodLength', Format(EntrdDateComprReg."Period Length", 0, 9));
        TelemetryDimensions.Add('EndDate', Format(EntrdDateComprReg."Ending Date", 0, 9));
        TelemetryDimensions.Add('AnalysisAreaSelection', Format(AnalysisAreaSelection, 0, 9));
        TelemetryDimensions.Add('RetainDimensions', RetainDimText);
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4E', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F4F', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;
}

