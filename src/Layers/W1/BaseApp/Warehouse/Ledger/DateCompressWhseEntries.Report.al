// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Tracking;
using System.DataAdministration;
using System.Utilities;

report 7398 "Date Compress Whse. Entries"
{
    Caption = 'Date Compress Whse. Entries';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Warehouse Entry" = rimd,
                  TableData "Warehouse Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Warehouse Entry"; "Warehouse Entry")
        {
            DataItemTableView = sorting("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated, "Package No.");
            RequestFilterFields = "Item No.", "Bin Code", "Location Code", "Zone Code";

            trigger OnAfterGetRecord()
            begin
                WhseEntry2 := "Warehouse Entry";
                WhseEntry2.SetCurrentKey(
                    "Item No.", "Bin Code", "Location Code", "Variant Code",
                    "Unit of Measure Code", "Lot No.", "Serial No.");
                WhseEntry2.CopyFilters("Warehouse Entry");
                WhseEntry2.SetRange("Item No.", WhseEntry2."Item No.");
                WhseEntry2.SetRange("Bin Code", WhseEntry2."Bin Code");
                WhseEntry2.SetRange("Location Code", WhseEntry2."Location Code");
                WhseEntry2.SetRange("Variant Code", WhseEntry2."Variant Code");
                WhseEntry2.SetRange("Unit of Measure Code", WhseEntry2."Unit of Measure Code");
                WhseEntry2.SetFilter(
                  WhseEntry2."Registering Date",
                  DateComprMgt.GetDateFilter(WhseEntry2."Registering Date", EntrdDateComprReg, false));

                if (not RetainSerialNo) or (not RetainLotNo) or (not RetainPackageNo) then
                    UpdateITWhseEntries();

                WhseEntry2.SetTrackingFilterFromWhseEntry(WhseEntry2);
                WhseEntry2.SetRange("Warranty Date", WhseEntry2."Warranty Date");
                WhseEntry2.SetRange("Expiration Date", WhseEntry2."Expiration Date");

                CalcCompressWhseEntry();

                NewWhseEntry.Init();
                NewWhseEntry."Location Code" := WhseEntry2."Location Code";
                NewWhseEntry."Bin Code" := WhseEntry2."Bin Code";
                NewWhseEntry."Item No." := WhseEntry2."Item No.";
                NewWhseEntry.Description := Text008;
                NewWhseEntry."Variant Code" := WhseEntry2."Variant Code";
                NewWhseEntry."Unit of Measure Code" := WhseEntry2."Unit of Measure Code";
                NewWhseEntry.Dedicated := WhseEntry2.Dedicated;
                NewWhseEntry."Zone Code" := WhseEntry2."Zone Code";
                NewWhseEntry."Bin Type Code" := WhseEntry2."Bin Type Code";
                NewWhseEntry."Registering Date" := WhseEntry2.GetRangeMin(WhseEntry2."Registering Date");
                NewWhseEntry.CopyTrackingFromWhseEntry(WhseEntry2);
                NewWhseEntry."Warranty Date" := WhseEntry2."Warranty Date";
                NewWhseEntry."Expiration Date" := WhseEntry2."Expiration Date";

                OnAfterGetWarehouseEntryOnAfterInitNewWhseEntry(NewWhseEntry, "Warehouse Entry");

                Window.Update(1, NewWhseEntry."Registering Date");
                Window.Update(2, DateComprReg."No. of New Records");

                repeat
                    WhseEntry2.Delete();
                    DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
                    Window.Update(3, DateComprReg."No. Records Deleted");
                    if UseDataArchive then
                        DataArchive.SaveRecord(WhseEntry2);
                until not WhseEntry2.FindFirst();

                if PosQtyBaseonBin > 0 then begin
                    InsertNewEntry(
                      NewWhseEntry, PosQtyonBin, PosQtyBaseonBin,
                      PosCubage, PosWeight, NewWhseEntry."Entry Type"::"Positive Adjmt.");
                    DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                end;

                if NegQtyBaseonBin < 0 then begin
                    InsertNewEntry(
                      NewWhseEntry, NegQtyonBin, NegQtyBaseonBin,
                      NegCubage, NegWeight, NewWhseEntry."Entry Type"::"Negative Adjmt.");
                    DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(WhseReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(WhseReg, DateComprReg);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress Whse. Entries");

                DateComprReg.LockTable();
                WhseEntry2.ReadIsolation(IsolationLevel::ReadCommitted);
                LastEntryNo := WhseEntry2.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Registering Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                InitRegisters();

                RetainSerialNo := RetainNo(FieldNo("Serial No."));
                RetainLotNo := RetainNo(FieldNo("Lot No."));
                RetainPackageNo := RetainNo(FieldNo("Package No."));

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress Whse. Entries"));
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
                        ApplicationArea = Warehouse;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date to be included in the date compression. The compression will affect all warehouse entries from this date to the Ending Date.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date to be included in the date compression. The compression will affect all warehouse entries from the Starting Date to this date.';

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
                    }
                    field(PeriodLength; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the length of the period whose entries will be combined. Choose the field to see the options.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field(SerialNo; RetainFields[1])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Serial No.';
                            ToolTip = 'Specifies if you want to retain the serial number in the compression.';
                        }
                        field(LotNo; RetainFields[2])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Lot No.';
                            ToolTip = 'Specifies if you want to retain the lot number in the compression.';
                        }
                        field(PackageNo; RetainFields[3])
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Package No.';
                            ToolTip = 'Specifies if you want to retain the package number in the compression.';
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
            if not HideDialog then
                if not ConfirmManagement.GetResponseOrDefault(CompressEntriesQst, true) then
                    CurrReport.Break();
        end;

        trigger OnOpenPage()
        var
            DateCompression: Codeunit "Date Compression";
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();

            InsertField("Warehouse Entry".FieldNo("Serial No."), "Warehouse Entry".FieldCaption("Serial No."));
            InsertField("Warehouse Entry".FieldNo("Lot No."), "Warehouse Entry".FieldCaption("Lot No."));
            InsertField("Warehouse Entry".FieldNo("Package No."), "Warehouse Entry".FieldCaption("Package No."));

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
        WhseEntryFilter := CopyStr("Warehouse Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

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
        WhseReg: Record "Warehouse Register";
        NewWhseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
        DateComprMgt: Codeunit DateComprMgt;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        WhseEntryFilter: Text[250];
        PosQtyonBin: Decimal;
        PosQtyBaseonBin: Decimal;
        NegQtyonBin: Decimal;
        NegQtyBaseonBin: Decimal;
        PosWeight: Decimal;
        NegWeight: Decimal;
        PosCubage: Decimal;
        NegCubage: Decimal;
        NoOfFields: Integer;
        RetainFields: array[3] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        i: Integer;
        WhseRegExists: Boolean;
        RetainSerialNo: Boolean;
        RetainLotNo: Boolean;
        RetainPackageNo: Boolean;
#pragma warning disable AA0074
        Text008: Label 'Date Compressed';
#pragma warning restore AA0074
        HideDialog: Boolean;
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;

        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text004: Label 'Date compressing warehouse entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Date                 #1######\\';
        Text006: Label 'No. of new entries   #2######\';
        Text007: Label 'No. of entries del.  #3######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    local procedure InitRegisters()
    var
        NextRegNo: Integer;
    begin
        WhseReg.Init();
        WhseReg."No." := WhseReg.GetNextEntryNo();
        WhseReg."Creation Date" := Today;
        WhseReg."Creation Time" := Time;
        WhseReg."Source Code" := SourceCodeSetup."Compress Whse. Entries";
        WhseReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseReg."User ID"));

        NextRegNo := DateComprReg.GetLastEntryNo() + 1;

        DateComprReg.InitRegister(
          Database::"Warehouse Entry", NextRegNo,
          EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date", EntrdDateComprReg."Period Length",
          WhseEntryFilter, WhseReg."No.", SourceCodeSetup."Compress Whse. Entries");

        for i := 1 to NoOfFields do
            if RetainFields[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        WhseRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var WhseReg: Record "Warehouse Register"; var DateComprReg: Record "Date Compr. Register")
    begin
        WhseReg."From Entry No." := FirstEntryNo;
        WhseReg."To Entry No." := NewWhseEntry."Entry No.";

        if WhseRegExists then begin
            WhseReg.Modify();
            DateComprReg.Modify();
        end else begin
            WhseReg.InsertRecord();
            DateComprReg.Insert();
            WhseRegExists := true;
        end;
        Commit();

        DateComprReg.LockTable();
        WhseEntry2.Reset();
    end;

    local procedure InsertField(Number: Integer; Name: Text)
    begin
        NoOfFields := NoOfFields + 1;
        FieldNumber[NoOfFields] := Number;
        FieldNameArray[NoOfFields] := Name;
    end;

    local procedure RetainNo(Number: Integer): Boolean
    begin
        exit(RetainFields[Index(Number)]);
    end;

    local procedure Index(Number: Integer): Integer
    begin
        for i := 1 to NoOfFields do
            if Number = FieldNumber[i] then
                exit(i);
    end;

    local procedure CalcCompressWhseEntry()
    var
        LocalWhseEntry: Record "Warehouse Entry";
    begin
        PosQtyonBin := 0;
        PosQtyBaseonBin := 0;
        PosWeight := 0;
        PosCubage := 0;
        NegQtyonBin := 0;
        NegQtyBaseonBin := 0;
        NegWeight := 0;
        NegCubage := 0;
        LocalWhseEntry.Copy(WhseEntry2);
        if LocalWhseEntry.Find('-') then
            repeat
                if LocalWhseEntry."Qty. (Base)" < 0 then begin
                    NegQtyonBin := NegQtyonBin + LocalWhseEntry.Quantity;
                    NegQtyBaseonBin := NegQtyBaseonBin + LocalWhseEntry."Qty. (Base)";
                    NegWeight := NegWeight + LocalWhseEntry.Weight;
                    NegCubage := NegCubage + LocalWhseEntry.Cubage;
                end else begin
                    PosQtyonBin := PosQtyonBin + LocalWhseEntry.Quantity;
                    PosQtyBaseonBin := PosQtyBaseonBin + LocalWhseEntry."Qty. (Base)";
                    PosWeight := PosWeight + LocalWhseEntry.Weight;
                    PosCubage := PosCubage + LocalWhseEntry.Cubage;
                end;
            until LocalWhseEntry.Next() = 0;
    end;

    local procedure UpdateITWhseEntries()
    var
        LocalWhseEntry: Record "Warehouse Entry";
        LocalWhseEntry2: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyonBin: Decimal;
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup(WhseEntry2."Item No.", WhseItemTrackingSetup);
        OnUpdateITWhseEntriesOnAfterGetWhseItemTrkgSetup(WhseEntry2, WhseItemTrackingSetup);

        LocalWhseEntry.Copy(WhseEntry2);
        if RetainSerialNo or RetainLotNo or RetainPackageNo then begin
            if WhseItemTrackingSetup.TrackingRequired() then begin
                LocalWhseEntry.SetFilter("Warranty Date", '<>%1', 0D);
                LocalWhseEntry.SetFilter("Expiration Date", '<>%1', 0D);
                if not LocalWhseEntry.Find('-') then begin
                    LocalWhseEntry.SetRange("Warranty Date");
                    LocalWhseEntry.SetRange("Expiration Date");
                end;
            end;
        end else begin
            LocalWhseEntry.SetRange("Warranty Date", WhseEntry2."Warranty Date");
            LocalWhseEntry.SetRange("Expiration Date", WhseEntry2."Expiration Date");
        end;

        if not RetainSerialNo then begin
            if WhseItemTrackingSetup."Serial No. Required" then
                LocalWhseEntry.SetFilter(LocalWhseEntry."Serial No.", '<>''''');
        end else
            LocalWhseEntry.SetRange("Serial No.", WhseEntry2."Serial No.");
        if not RetainLotNo then begin
            if WhseItemTrackingSetup."Lot No. Required" then
                LocalWhseEntry.SetFilter(LocalWhseEntry."Lot No.", '<>''''');
        end else
            LocalWhseEntry.SetRange("Lot No.", WhseEntry2."Lot No.");
        if not RetainPackageNo then begin
            if WhseItemTrackingSetup."Package No. Required" then
                LocalWhseEntry.SetFilter(LocalWhseEntry."Package No.", '<>''''');
        end else
            LocalWhseEntry.SetRange("Package No.", WhseEntry2."Package No.");
        if LocalWhseEntry.Find('-') then
            repeat
                QtyonBin := 0;
                LocalWhseEntry2.Copy(LocalWhseEntry);

                if not RetainSerialNo and WhseItemTrackingSetup."Serial No. Required" then
                    LocalWhseEntry2.SetRange("Serial No.", LocalWhseEntry."Serial No.");

                if not RetainLotNo and WhseItemTrackingSetup."Lot No. Required" then
                    LocalWhseEntry2.SetRange("Lot No.", LocalWhseEntry."Lot No.");

                if not RetainPackageNo and WhseItemTrackingSetup."Package No. Required" then
                    LocalWhseEntry2.SetRange("Package No.", LocalWhseEntry."Package No.");

                if (not RetainSerialNo and WhseItemTrackingSetup."Serial No. Required") or
                   (not RetainLotNo and WhseItemTrackingSetup."Lot No. Required") or
                   (not RetainPackageNo and WhseItemTrackingSetup."Package No. Required")
                then begin
                    LocalWhseEntry2.SetRange("Warranty Date", LocalWhseEntry."Warranty Date");
                    LocalWhseEntry2.SetRange("Expiration Date", LocalWhseEntry."Expiration Date");
                end;

                if LocalWhseEntry2.Find('-') then
                    repeat
                        QtyonBin := QtyonBin + LocalWhseEntry2."Qty. (Base)";
                    until LocalWhseEntry2.Next() = 0;

                if QtyonBin <= 0 then begin
                    if LocalWhseEntry2.Find('-') then
                        repeat
                            if not RetainSerialNo and WhseItemTrackingSetup."Serial No. Required" then
                                LocalWhseEntry2."Serial No." := '';
                            if not RetainLotNo and WhseItemTrackingSetup."Lot No. Required" then
                                LocalWhseEntry2."Lot No." := '';
                            if not RetainPackageNo and WhseItemTrackingSetup."Package No. Required" then
                                LocalWhseEntry2."Package No." := '';
                            if (not RetainSerialNo and WhseItemTrackingSetup."Serial No. Required") or
                               (not RetainLotNo and WhseItemTrackingSetup."Lot No. Required") or
                               (not RetainPackageNo and WhseItemTrackingSetup."Package No. Required")
                            then begin
                                LocalWhseEntry2."Warranty Date" := 0D;
                                LocalWhseEntry2."Expiration Date" := 0D;
                            end;
                            OnUpdateITWhseEntriesOnBeforeLocalWhseEntry2Modify(
                                LocalWhseEntry2,
                                RetainSerialNo, WhseItemTrackingSetup."Serial No. Required",
                                RetainLotNo, WhseItemTrackingSetup."Lot No. Required",
                                RetainPackageNo, WhseItemTrackingSetup."Package No. Required");
                            LocalWhseEntry2.Modify();
                        until LocalWhseEntry2.Next() = 0;

                    if (not RetainSerialNo and WhseItemTrackingSetup."Serial No. Required") or
                       (not RetainLotNo and WhseItemTrackingSetup."Lot No. Required") or
                       (not RetainPackageNo and WhseItemTrackingSetup."Package No. Required")
                    then begin
                        WhseEntry2."Warranty Date" := 0D;
                        WhseEntry2."Expiration Date" := 0D;
                    end;
                    if not RetainSerialNo then
                        WhseEntry2."Serial No." := '';
                    if not RetainLotNo then
                        WhseEntry2."Lot No." := '';
                    if not RetainPackageNo then
                        WhseEntry2."Package No." := '';
                    OnUpdateITWhseEntriesOnAfterSetWhseEntry2(
                        WhseEntry2,
                        RetainSerialNo, WhseItemTrackingSetup."Serial No. Required",
                        RetainLotNo, WhseItemTrackingSetup."Lot No. Required",
                        RetainPackageNo, WhseItemTrackingSetup."Package No. Required");
                end;
            until LocalWhseEntry.Next() = 0;
    end;

    local procedure InsertNewEntry(var WhseEntry: Record "Warehouse Entry"; Qty: Decimal; QtyBase: Decimal; Cubage: Decimal; Weight: Decimal; EntryType: Option)
    begin
        LastEntryNo := WhseEntry.GetNextEntryNo();
        WhseEntry."Entry No." := LastEntryNo;
        WhseEntry."Warehouse Register No." := WhseReg."No.";
        WhseEntry.Quantity := Qty;
        WhseEntry."Qty. (Base)" := QtyBase;
        WhseEntry.Cubage := Cubage;
        WhseEntry.Weight := Weight;
        WhseEntry."Entry Type" := EntryType;
        OnBeforeInsertNewEntry(WhseEntry);
        WhseEntry.Insert(true);
        if FirstEntryNo = 0 then
            FirstEntryNo := LastEntryNo;
    end;

    procedure SetParameters(EntrdDateComprReg2: Record "Date Compr. Register"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetParameters(EntrdDateComprReg2, ItemTrackingSetup, true)
    end;

    procedure SetParameters(EntrdDateComprReg2: Record "Date Compr. Register"; ItemTrackingSetup: Record "Item Tracking Setup"; DoUseDataArchive: Boolean)
    begin
        EntrdDateComprReg.Copy(EntrdDateComprReg2);
        InsertField(WhseEntry2.FieldNo("Serial No."), WhseEntry2.FieldCaption("Serial No."));
        InsertField(WhseEntry2.FieldNo("Lot No."), WhseEntry2.FieldCaption("Lot No."));
        InsertField(WhseEntry2.FieldNo("Package No."), WhseEntry2.FieldCaption("Package No."));
        RetainFields[1] := ItemTrackingSetup."Serial No. Required";
        RetainFields[2] := ItemTrackingSetup."Lot No. Required";
        RetainFields[3] := ItemTrackingSetup."Package No. Required";
        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
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
        TelemetryDimensions.Add('SerialNoRequired', Format(RetainFields[1], 0, 9));
        TelemetryDimensions.Add('LotNoRequired', Format(RetainFields[2], 0, 9));
        TelemetryDimensions.Add('PackageNoRequired', Format(RetainFields[3], 0, 9));
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F50', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, TelemetryDimensions);
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

        Session.LogMessage('0000F51', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWarehouseEntryOnAfterInitNewWhseEntry(var NewWarehouseEntry: Record "Warehouse Entry"; OldWarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewEntry(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateITWhseEntriesOnAfterSetWhseEntry2(var WarehouseEntry: Record "Warehouse Entry"; RetainSerialNo: Boolean; SNRequired: Boolean; RetainLotNo: Boolean; LNRequired: Boolean; RetainPackageNo: Boolean; PNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateITWhseEntriesOnBeforeLocalWhseEntry2Modify(var WarehouseEntry: Record "Warehouse Entry"; RetainSerialNo: Boolean; SNRequired: Boolean; RetainLotNo: Boolean; LNRequired: Boolean; RetainPackageNo: Boolean; PNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateITWhseEntriesOnAfterGetWhseItemTrkgSetup(var WarehouseEntry: Record "Warehouse Entry"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;
}

