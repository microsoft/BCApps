// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using Microsoft.Warehouse.Ledger;
using System.DataAdministration;
using System.Environment;
using System.Telemetry;

codeunit 9040 "Date Compression"
{
    var
        EndingDateMissingErr: Label 'You must specify an ending date.';
        DescriptionMissingErr: Label 'You must specify a description.';
        DateCompressionEndingDateErr: Label 'The end date %1 is not valid. You must keep at least %2 years uncompressed.', Comment = '%1 is a date in short date format, %2 is an integer';
        DateCompressionStartingDateErr: Label 'The start date %1 must be before the end date %2', Comment = '%1 and %2 are dates in short date format';
        AccountingPeriodMustBeDateLockedErr: Label 'The accounting periods for the period you wish to date compress must be Date Locked.';
        NoAccountingPeriodsErr: Label 'No accounting periods have been set up. In order to run date compression you must set up accounting periods.';
        MinUncompressedYearsErr: Label 'The number of years to keep uncompressed cannot be less than 1.';
        DefaultDateCompressionDescriptionLbl: Label 'Date Compressed', Comment = 'this label is used as a description on compressed entries.', MaxLength = 100;
        StartDateCompressionTelemetryMsg: Label 'Running date compression codeunit %1.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression codeunit %1.', Locked = true;
        DateCompressionCompletedLbl: Label 'Date compression completed by UserSecurityId %1 in company %2.', Comment = '%1 - User Security ID, %2 - Company name', Locked = true;

    procedure InitDateComprSettingsBuffer(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        DateComprSettingsBuffer."Retain Dimensions" := DimensionSelectionBuffer.GetDimSelectionText(8 /*ObjectType::Page*/, Page::"Data Administration Guide", '');
        DateComprSettingsBuffer."Period Length" := DateComprSettingsBuffer."Period Length"::Month;
        DateComprSettingsBuffer.Description := CopyStr(DefaultDateCompressionDescriptionLbl, 1, MaxStrLen(DateComprSettingsBuffer.Description));
        FindDateCompressionDates(DateComprSettingsBuffer);
        SetAnalysisViewDimensions(8 /*ObjectType::Page*/, Page::"Data Administration Guide", DateComprSettingsBuffer."Retain Dimensions");
    end;

    procedure VerifyDateCompressionDates(StartingDate: Date; EndingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then
            Error(NoAccountingPeriodsErr);

        if EndingDate = 0D then
            Error(EndingDateMissingErr);

        if EndingDate > CalcMaxEndDate() then
            Error(DateCompressionEndingDateErr, EndingDate, MinimumNumberOfYearsToKeep());

        if StartingDate > EndingDate then
            Error(DateCompressionStartingDateErr, StartingDate, EndingDate);

        AccountingPeriod.SetFilter("Starting Date", '<=%1', EndingDate);
        if AccountingPeriod.FindLast() then
            if not AccountingPeriod."Date Locked" then
                Error(AccountingPeriodMustBeDateLockedErr);
    end;

    local procedure FindDateCompressionDates(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer");
    begin
        DateComprSettingsBuffer."Ending Date" := CalcMaxEndDate();
        DateComprSettingsBuffer."Starting Date" := FindDateCompressionStartingDate(DateComprSettingsBuffer."Ending Date");
    end;

    local procedure FindDateCompressionStartingDate(EndingDate: Date) StartingDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
        DateComprRegister: Record "Date Compr. Register";
    begin
        if EndingDate = 0D then
            exit;

        // find the last date of previous date compression
        DateComprRegister.SetCurrentKey("Ending Date");
        if DateComprRegister.FindLast() then
            StartingDate := AccountingPeriod.GetFiscalYearStartDate(DateComprRegister."Ending Date" + 1);

        if StartingDate > EndingDate then
            StartingDate := 0D;
    end;

    procedure RunDateCompression(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        AnalysisView: Record "Analysis View";
        DateCompRegister: Record "Date Compr. Register";
        LastRegNo: Integer;
    begin
        VerifyDateCompressionDates(DateComprSettingsBuffer."starting date", DateComprSettingsBuffer."Ending Date");

        if DateComprSettingsBuffer.Description = '' then
            error(DescriptionMissingErr);

        // Analysis View dimensions must be retained
        SetAnalysisViewDimensions(8 /*ObjectType::Page*/, Page::"Data Administration Guide", DateComprSettingsBuffer."Retain Dimensions");

        LogStartTelemetryMessage(DateComprSettingsBuffer);

        // Analysis Views must be up to date
        if DateComprSettingsBuffer."Compress G/L Entries" or DateComprSettingsBuffer."Compress G/L Budget Entries" or DateComprSettingsBuffer."Compress Item Budget Entries" then
            AnalysisView.UpdateAllAnalysisViews(true);

        if DateCompRegister.FindLast() then
            LastRegNo := DateCompRegister."No.";

        if DateComprSettingsBuffer."Compress G/L Entries" then
            RunDateCompressGeneralLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compress VAT Entries" then
            RunDateCompressVATEntries(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compr. Bank Acc. Ledg Entries" then
            RunDateCompressBankAccLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compr. Customer Ledger Entries" then
            RunDateCompressCustomerLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compress Vendor Ledger Entries" then
            RunDateCompressVendorLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compress FA Ledger Entries" then
            RunDateCompressFALedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compr. Maintenance Ledg. Entr." then
            RunDateCompressMaintLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compress G/L Budget Entries" then
            RunDateComprGLBudgetEntries(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compr. Resource Ledger Entries" then
            RunDateCompressResourceLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compr. Insurance Ledg. Entries" then
            RunDateCompressInsuranceLedger(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compress Warehouse Entries" then
            RunDateCompressWhseEntries(DateComprSettingsBuffer);
        if DateComprSettingsBuffer."Compress Item Budget Entries" then
            RunDateCompItemBudgetEntries(DateComprSettingsBuffer);

        if DateComprSettingsBuffer."Delete Empty Registers" then begin
            if (DateComprSettingsBuffer."Compress G/L Entries" or
                DateComprSettingsBuffer."Compress VAT Entries" or
                DateComprSettingsBuffer."Compr. Bank Acc. Ledg Entries" or
                DateComprSettingsBuffer."Compr. Customer Ledger Entries" or
                DateComprSettingsBuffer."Compress Vendor Ledger Entries" or
                DateComprSettingsBuffer."Compress FA Ledger Entries" or
                DateComprSettingsBuffer."Compr. Maintenance Ledg. Entr.")
            then
                RunDeleteEmptyGLRegisters();

            if DateComprSettingsBuffer."Compr. Resource Ledger Entries" then
                RunDeleteEmptyResRegisters(DateComprSettingsBuffer);
            if DateComprSettingsBuffer."Compress FA Ledger Entries" then
                RunDeleteEmptyFARegisters(DateComprSettingsBuffer);
            if DateComprSettingsBuffer."Compr. Insurance Ledg. Entries" then
                RunDeleteEmptyInsuranceReg(DateComprSettingsBuffer);
            if DateComprSettingsBuffer."Compress Warehouse Entries" then
                RunDeleteEmptyWhseRegisters(DateComprSettingsBuffer);
            RunDeleteEmptyItemRegisters(DateComprSettingsBuffer);
        end;

        UpdateSavedSpace(DateComprSettingsBuffer, LastRegNo);

        LogEndTelemetryMessage(DateComprSettingsBuffer);
    end;

    local procedure RunDateCompressGeneralLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressGeneralLedger: Report "Date Compress General Ledger";
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress General Ledger", DateComprSettingsBuffer."Retain Dimensions");

        Clear(DateComprRetainFields);
        DateComprRetainFields."Retain Business Unit Code" := true;

        DateCompressGeneralLedger.UseRequestPage(false);
        DateCompressGeneralLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            DateComprRetainFields,
            DateComprSettingsBuffer."Retain Dimensions",
            true);
        DateCompressGeneralLedger.SetSkipAnalysisViewUpdateCheck();
        DateCompressGeneralLedger.Run();
    end;


    local procedure RunDateCompressVATEntries(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVATEntries: Report "Date Compress VAT Entries";
    begin
        Clear(DateComprRetainFields);

        DateCompressVATEntries.UseRequestPage(false);
        DateCompressVATEntries.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprRetainFields,
            true);
    end;

    local procedure RunDateCompressBankAccLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressBankAccLedger: Report "Date Compress Bank Acc. Ledger";
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress Bank Acc. Ledger", DateComprSettingsBuffer."Retain Dimensions");

        Clear(DateComprRetainFields);

        DateCompressBankAccLedger.UseRequestPage(false);
        DateCompressBankAccLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            DateComprRetainFields,
            DateComprSettingsBuffer."Retain Dimensions",
            true);
        DateCompressBankAccLedger.Run();

        RunDeleteCheckLedgerEntries(DateComprSettingsBuffer);
    end;

    local procedure RunDeleteCheckLedgerEntries(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DeleteCheckLedgerEntries: Report "Delete Check Ledger Entries";
    begin
        DeleteCheckLedgerEntries.UseRequestPage(false);
        DeleteCheckLedgerEntries.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date");
        DeleteCheckLedgerEntries.Run();
    end;

    local procedure RunDateComprGLBudgetEntries(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateComprGLBudgetEntries: Report "Date Compr. G/L Budget Entries";
        RetainBusinessUnitCode: Boolean;
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compr. G/L Budget Entries", DateComprSettingsBuffer."Retain Dimensions");
        RetainBusinessUnitCode := true;

        DateComprGLBudgetEntries.UseRequestPage(false);
        DateComprGLBudgetEntries.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            RetainBusinessUnitCode,
            DateComprSettingsBuffer."Retain Dimensions");
        DateComprGLBudgetEntries.SetSkipAnalysisViewUpdateCheck();
        DateComprGLBudgetEntries.Run();
    end;

    local procedure RunDateCompressCustomerLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressCustomerLedger: Report "Date Compress Customer Ledger";
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress Customer Ledger", DateComprSettingsBuffer."Retain Dimensions");

        Clear(DateComprRetainFields);

        DateCompressCustomerLedger.UseRequestPage(false);
        DateCompressCustomerLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            DateComprRetainFields,
            DateComprSettingsBuffer."Retain Dimensions",
            true);
        DateCompressCustomerLedger.Run();
    end;

    local procedure RunDateCompressVendorLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVendorLedger: Report "Date Compress Vendor Ledger";
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress Vendor Ledger", DateComprSettingsBuffer."Retain Dimensions");

        Clear(DateComprRetainFields);

        DateCompressVendorLedger.UseRequestPage(false);
        DateCompressVendorLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            DateComprRetainFields,
            DateComprSettingsBuffer."Retain Dimensions",
            true);
        DateCompressVendorLedger.Run();
    end;

    local procedure RunDateCompressResourceLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateCompressResourceLedger: Report "Date Compress Resource Ledger";
        RetainDocumentNo: Boolean;
        RetainWorkTypeCode: Boolean;
        RetainJobNo: Boolean;
        RetainUnitOfMeasureCode: Boolean;
        RetainSourceType: Boolean;
        RetainSourceNo: Boolean;
        RetainChargeable: Boolean;
    begin
        //DateCompressResourceLedger.
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress Resource Ledger", DateComprSettingsBuffer."Retain Dimensions");

        RetainDocumentNo := false;
        RetainWorkTypeCode := false;
        RetainJobNo := false;
        RetainUnitOfMeasureCode := false;
        RetainSourceType := false;
        RetainSourceNo := false;
        RetainChargeable := false;

        DateCompressResourceLedger.UseRequestPage(false);
        DateCompressResourceLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            RetainDocumentNo,
        RetainWorkTypeCode,
        RetainJobNo,
        RetainUnitOfMeasureCode,
        RetainSourceType,
        RetainSourceNo,
        RetainChargeable,
            DateComprSettingsBuffer."Retain Dimensions");
        DateCompressResourceLedger.Run();
    end;

    local procedure RunDateCompressFALedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateCompressFALedger: Report "Date Compress FA Ledger";
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress FA Ledger", DateComprSettingsBuffer."Retain Dimensions");

        DateCompressFALedger.UseRequestPage(false);
        DateCompressFALedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            DateComprSettingsBuffer."Retain Dimensions");
        DateCompressFALedger.Run();
    end;

    local procedure RunDateCompressMaintLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateCompressMaintLedger: Report "Date Compress Maint. Ledger";
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress Maint. Ledger", DateComprSettingsBuffer."Retain Dimensions");

        DateCompressMaintLedger.UseRequestPage(false);
        DateCompressMaintLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            DateComprSettingsBuffer."Retain Dimensions");
        DateCompressMaintLedger.Run();
    end;

    local procedure RunDateCompressInsuranceLedger(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateCompressInsuranceLedger: Report "Date Compress Insurance Ledger";
        OnlyIndexEntriesFrom: Boolean;
        RetainDocumentNo: Boolean;
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Compress Insurance Ledger", DateComprSettingsBuffer."Retain Dimensions");

        OnlyIndexEntriesFrom := false;
        RetainDocumentNo := false;

        DateCompressInsuranceLedger.UseRequestPage(false);
        DateCompressInsuranceLedger.InitializeRequest(
            DateComprSettingsBuffer."Starting Date",
            DateComprSettingsBuffer."Ending Date",
            DateComprSettingsBuffer."Period Length".AsInteger(),
            DateComprSettingsBuffer.Description,
            OnlyIndexEntriesFrom,
            RetainDocumentNo,
            DateComprSettingsBuffer."Retain Dimensions");
        DateCompressInsuranceLedger.Run();
    end;

    local procedure RunDateCompressWhseEntries(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        TempDateComprRegister: Record "Date Compr. Register" temporary;
        DateCompressWhseEntries: Report "Date Compress Whse. Entries";
    begin
        TempDateComprRegister."Starting Date" := DateComprSettingsBuffer."Starting Date";
        TempDateComprRegister."Ending Date" := DateComprSettingsBuffer."Ending Date";
        TempDateComprRegister."Period Length" := DateComprSettingsBuffer."Period Length".AsInteger();

        ItemTrackingSetup."Serial No. Required" := false;
        ItemTrackingSetup."Lot No. Required" := false;
        ItemTrackingSetup."Package No. Required" := false;

        DateCompressWhseEntries.UseRequestPage(false);
        DateCompressWhseEntries.SetParameters(TempDateComprRegister, ItemTrackingSetup);
        DateCompressWhseEntries.Run();
    end;

    local procedure RunDateCompItemBudgetEntries(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DateCompItemBudgetEntries: Report "Date Comp. Item Budget Entries";
        AnalysisAreaType: Enum "Analysis Area Type";
        AnalysisAreaTypeInt: Integer;
    begin
        SetSelectedDimensions(3 /*ObjectType::Report*/, Report::"Date Comp. Item Budget Entries", DateComprSettingsBuffer."Retain Dimensions");

        foreach AnalysisAreaTypeInt in AnalysisAreaType.Ordinals do begin
            DateCompItemBudgetEntries.UseRequestPage(false);
            DateCompItemBudgetEntries.InitializeRequest(
                AnalysisAreaTypeInt,
                DateComprSettingsBuffer."Starting Date",
                DateComprSettingsBuffer."Ending Date",
                DateComprSettingsBuffer."Period Length".AsInteger(),
                DateComprSettingsBuffer.Description,
                DateComprSettingsBuffer."Retain Dimensions");
            DateCompItemBudgetEntries.SetSkipAnalysisViewUpdateCheck();
            DateCompItemBudgetEntries.Run();
            Clear(DateCompItemBudgetEntries);
        end;
    end;

    local procedure RunDeleteEmptyGLRegisters()
    var
        DeleteEmptyGLRegisters: Report "Delete Empty G/L Registers";
    begin
        DeleteEmptyGLRegisters.UseRequestPage(false);
        DeleteEmptyGLRegisters.SetSkipConfirm();
        DeleteEmptyGLRegisters.Run();
    end;

    local procedure RunDeleteEmptyResRegisters(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DeleteEmptyResRegisters: Report "Delete Empty Res. Registers";
    begin
        if DateComprSettingsBuffer."Delete Empty Registers" then begin
            DeleteEmptyResRegisters.UseRequestPage(false);
            DeleteEmptyResRegisters.SetSkipConfirm();
            DeleteEmptyResRegisters.Run();
        end;
    end;

    local procedure RunDeleteEmptyFARegisters(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DeleteEmptyFARegisters: Report "Delete Empty FA Registers";
    begin
        if DateComprSettingsBuffer."Delete Empty Registers" then begin
            DeleteEmptyFARegisters.UseRequestPage(false);
            DeleteEmptyFARegisters.SetSkipConfirm();
            DeleteEmptyFARegisters.Run();
        end;
    end;

    local procedure RunDeleteEmptyInsuranceReg(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DeleteEmptyInsuranceReg: Report "Delete Empty Insurance Reg.";
    begin
        if DateComprSettingsBuffer."Delete Empty Registers" then begin
            DeleteEmptyInsuranceReg.UseRequestPage(false);
            DeleteEmptyInsuranceReg.SetSkipConfirm();
            DeleteEmptyInsuranceReg.Run();
        end;
    end;

    local procedure RunDeleteEmptyWhseRegisters(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DeleteEmptyWhseRegisters: Report "Delete Empty Whse. Registers";
    begin
        if DateComprSettingsBuffer."Delete Empty Registers" then begin
            DeleteEmptyWhseRegisters.UseRequestPage(false);
            DeleteEmptyWhseRegisters.SetSkipConfirm();
            DeleteEmptyWhseRegisters.Run();
        end;
    end;

    local procedure RunDeleteEmptyItemRegisters(DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        DeleteEmptyItemRegisters: Report "Delete Empty Item Registers";
    begin
        if DateComprSettingsBuffer."Delete Empty Registers" then begin
            DeleteEmptyItemRegisters.UseRequestPage(false);
            DeleteEmptyItemRegisters.SetSkipConfirm();
            DeleteEmptyItemRegisters.Run();
        end;
    end;

    local procedure SetSelectedDimensions(ObjectType: Option; ObjectId: Integer; RetainDimensions: Text)
    var
        SelectedDimension: Record "Selected Dimension";
        DimensionCode: Text;
    begin
        SelectedDimension.SetRange("User ID", UserId);
        SelectedDimension.SetRange("Object Type", ObjectType);
        SelectedDimension.SetRange("Object ID", ObjectId);
        SelectedDimension.SetRange("Analysis View Code", '');
        SelectedDimension.DeleteAll();

        foreach DimensionCode in RetainDimensions.Split(';') do
            InsertSelectedDimension(ObjectType, ObjectId, DimensionCode);
    end;

    local procedure SetAnalysisViewDimensions(ObjectType: Option; ObjectId: Integer; var RetainDimensions: Text[250])
    var
        SelectedDimension: Record "Selected Dimension";
        AnalysisView: Record "Analysis View";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        if AnalysisView.FindSet() then begin
            repeat
                if not SelectedDimension.Get(UserId, ObjectType, ObjectId, '', AnalysisView."Dimension 1 Code") then
                    InsertSelectedDimension(ObjectType, ObjectId, AnalysisView."Dimension 1 Code");
                if not SelectedDimension.Get(UserId, ObjectType, ObjectId, '', AnalysisView."Dimension 2 Code") then
                    InsertSelectedDimension(ObjectType, ObjectId, AnalysisView."Dimension 2 Code");
                if not SelectedDimension.Get(UserId, ObjectType, ObjectId, '', AnalysisView."Dimension 3 Code") then
                    InsertSelectedDimension(ObjectType, ObjectId, AnalysisView."Dimension 3 Code");
                if not SelectedDimension.Get(UserId, ObjectType, ObjectId, '', AnalysisView."Dimension 4 Code") then
                    InsertSelectedDimension(ObjectType, ObjectId, AnalysisView."Dimension 4 Code");
            until AnalysisView.Next() = 0;

            RetainDimensions := DimensionSelectionBuffer.GetDimSelectionText(ObjectType, ObjectId, '');
        end;
    end;

    local procedure InsertSelectedDimension(ObjectType: Option; ObjectId: Integer; DimensionCode: Text)
    var
        SelectedDimension: Record "Selected Dimension";
    begin
        if DimensionCode = '' then
            exit;

        SelectedDimension.Init();
        SelectedDimension."User ID" := CopyStr(UserId, 1, MaxStrLen(SelectedDimension."User ID"));
        SelectedDimension."Object Type" := ObjectType;
        SelectedDimension."Object ID" := ObjectId;
        SelectedDimension."Analysis View Code" := '';
        SelectedDimension."Dimension Code" := CopyStr(DimensionCode, 1, MaxStrLen(SelectedDimension."Dimension Code"));
        SelectedDimension.Insert();
    end;

    local procedure UpdateSavedSpace(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer"; LastRegNo: integer)
    var
        DateComprRegister: Record "Date Compr. Register";
        RecordsRemoved: Integer;
    begin
        DateComprRegister.Setfilter("No.", '>%1', LastRegNo);
        if DateComprRegister.FindSet() then
            repeat
                RecordsRemoved := DateComprRegister."No. Records Deleted" - DateComprRegister."No. of New Records";
                if RecordsRemoved <> 0 then
                    DateComprSettingsBuffer."No. of Records Removed" += RecordsRemoved;
                DateComprSettingsBuffer."Saved Space (MB)" += Round((RecordsRemoved * RecordSize(DateComprRegister."Table ID")) / (1024 * 1024));
            until DateComprRegister.Next() = 0;
    end;

    local procedure RecordSize(TableId: Integer): Decimal
    var
        TableInformation: Record "Table Information";
    begin
        if not TableInformation.Get(CompanyName, TableId) then
            if not TableInformation.Get('', TableId) then
                exit(0);
        exit(TableInformation."Record Size");
    end;

    procedure CalcMaxEndDate(): Date
    var
        DateCalcLbl: Label '<-%1Y + CY>', Locked = true;
    begin
        exit(CalcDate(StrSubstNo(DateCalcLbl, MinimumNumberOfYearsToKeep() + 1), Today()))
    end;

    local procedure MinimumNumberOfYearsToKeep() NumberOfYearsToKeep: Integer
    begin
        NumberOfYearsToKeep := 5;
        OnSetMinimumNumberOfYearsToKeep(NumberOfYearsToKeep);
        if NumberOfYearsToKeep <= 0 then
            Error(MinUncompressedYearsErr);
    end;

    local procedure LogStartTelemetryMessage(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // TelemetryDimensions.Add('CompanyName', CompanyName());
        TelemetryDimensions.Add('StartDate', Format(DateComprSettingsBuffer."Starting Date", 0, 9));
        TelemetryDimensions.Add('EndDate', Format(DateComprSettingsBuffer."Ending Date", 0, 9));
        TelemetryDimensions.Add('PeriodLength', Format(DateComprSettingsBuffer."Period Length", 0, 9));
        // TelemetryDimensions.Add('Description', DateComprSettingsBuffer.Description);
        TelemetryDimensions.Add('DeleteEmptyRegisters', Format(DateComprSettingsBuffer."Delete Empty Registers", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', DateComprSettingsBuffer."Retain Dimensions");

        Session.LogMessage('0000F52', StrSubstNo(StartDateCompressionTelemetryMsg, Codeunit::"Date Compression"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure LogEndTelemetryMessage(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    var
        AuditLog: Codeunit "Audit Log";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // TelemetryDimensions.Add('CompanyName', CompanyName());
        TelemetryDimensions.Add('StartDate', Format(DateComprSettingsBuffer."Starting Date", 0, 9));
        TelemetryDimensions.Add('EndDate', Format(DateComprSettingsBuffer."Ending Date", 0, 9));
        TelemetryDimensions.Add('PeriodLength', Format(DateComprSettingsBuffer."Period Length", 0, 9));
        // TelemetryDimensions.Add('Description', DateComprSettingsBuffer.Description);
        TelemetryDimensions.Add('DeleteEmptyRegisters', Format(DateComprSettingsBuffer."Delete Empty Registers", 0, 9));
        TelemetryDimensions.Add('RetainDimensions', DateComprSettingsBuffer."Retain Dimensions");
        TelemetryDimensions.Add('NoOfRecordsRemoved', Format(DateComprSettingsBuffer."No. of Records Removed", 0, 9));
        TelemetryDimensions.Add('SavedSpaceInMB', Format(DateComprSettingsBuffer."Saved Space (MB)", 0, 9));

        Session.LogMessage('0000F53', StrSubstNo(EndDateCompressionTelemetryMsg, Codeunit::"Date Compression"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
        if DateComprSettingsBuffer."No. of Records Removed" > 0 then
            AuditLog.LogAuditMessage(StrSubstNo(DateCompressionCompletedLbl, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetMinimumNumberOfYearsToKeep(var NumberOfYearsToKeep: Integer)
    begin
    end;
}
