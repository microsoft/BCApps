// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.Utilities;

codeunit 12131 "Spesometro Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        VATReportSetup: Record "VAT Report Setup";
        FlatFileManagement: Codeunit "Flat File Management";
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        ConstRecordType: Option A,B,C,D,E,G,H,Z;
        ProgressiveTransmissionNo: Integer;
        DetailedExport: Boolean;
        ModuleCount: array[15] of Integer;
        TotalFrameworkCount: array[15] of Integer;
        ReportType: Option Standard,Corrective,Cancellation;
        OrgReportNo: Code[18];
        OrgReportReceiptNo: Code[17];
        StartDate: Date;
        EndDate: Date;
        PeriodType: Option Month,Quarter,Year,Hide;
        TaxRepresentativeTxt: Label 'Tax Representative';
        UnknownReportTypeErr: Label 'The report type %1 could not be mapped to Spesometro report types.';
        AppointmentFieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";

    [Scope('OnPrem')]
    procedure Initialize(NewDetailedExport: Boolean; NewStartDate: Date; NewEndDate: Date; NewPeriodType: Option Month,Quarter,Year,Hide)
    begin
        FlatFileManagement.Initialize();
        FlatFileManagement.SetHeaderFooterRecordCountPerFile(4); // A, B, E and Z record

        ProgressiveTransmissionNo := 0;

        // Set options
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        DetailedExport := NewDetailedExport;
        PeriodType := NewPeriodType;
        ReportType := ReportType::Standard;
        OrgReportNo := '';
        OrgReportReceiptNo := '';

        // Get global data
        CompanyInfo.Get();
        VATReportSetup.Get();

        ValidateGlobalData();
    end;

    [Scope('OnPrem')]
    procedure SetServerFileName(FileName: Text)
    begin
        FlatFileManagement.SetServerFileName(FileName);
    end;

    local procedure ValidateGlobalData()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Name);
        CompanyInfo.TestField("VAT Registration No.");
        CompanyInfo.TestField("Industrial Classification");

        if GetSpesometroAppointment(SpesometroAppointment) then
            SpesometroAppointment.ValidateAppointment();
    end;

    [Scope('OnPrem')]
    procedure SetReportTypeData(NewReportType: Option Standard,Corrective,Cancellation; NewOrgReportNo: Code[18]; NewOrgReceiptNo: Code[17])
    begin
        ReportType := NewReportType;
        OrgReportNo := NewOrgReportNo;
        OrgReportReceiptNo := NewOrgReceiptNo;
    end;

    [Scope('OnPrem')]
    procedure SetTotalNumberOfRecords(NewTotalRecords: Integer)
    begin
        FlatFileManagement.SetEstimatedNumberOfRecords(NewTotalRecords);
    end;

    [Scope('OnPrem')]
    procedure SetTotalFrameworkCount(Framework: Option ,FA,SA,BL,FE,FR,NE,NR,DF,FN,SE,TU; "Count": Integer)
    begin
        TotalFrameworkCount[Framework] := Count;
    end;

    [Scope('OnPrem')]
    procedure IncrementCount(CountToIncrement: Option ,TA001001,TA002001,TA003001,TA003002,TA003003,TA004001,TA004002,TA005001,TA005002,TA006001,TA007001,TA008001,TA009001,TA010001,TA011001)
    begin
        ModuleCount[CountToIncrement] += 1;
    end;

    [Scope('OnPrem')]
    procedure GetTotalTransmissions(): Integer
    begin
        exit(FlatFileManagement.GetTotalTransmissions());
    end;

    [Scope('OnPrem')]
    procedure MapVATReportType(SourceType: Option): Integer
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        case SourceType of
            VATReportHeader."VAT Report Type"::Standard:
                exit(ReportType::Standard);
            VATReportHeader."VAT Report Type"::Corrective:
                exit(ReportType::Corrective);
            VATReportHeader."VAT Report Type"::"Cancellation ":
                exit(ReportType::Cancellation);
        end;
        Error(UnknownReportTypeErr, SourceType);
    end;

    [Scope('OnPrem')]
    procedure WritePositionalValue(Position: Integer; Length: Integer; ValueFormat: Option; Value: Text; Truncate: Boolean)
    begin
        FlatFileManagement.WritePositionalValue(Position, Length, ValueFormat, Value, Truncate);
    end;

    [Scope('OnPrem')]
    procedure WriteBlockValue("Code": Code[8]; ValueFormat: Option; Value: Text)
    begin
        FlatFileManagement.WriteBlockValue(Code, ValueFormat, Value);
    end;

    [Scope('OnPrem')]
    procedure StartNewFile()
    begin
        FlatFileManagement.StartNewFile();
        ProgressiveTransmissionNo += 1;

        Clear(ModuleCount);

        BuildRecordTypeA();
        BuildRecordTypeB();
    end;

    [Scope('OnPrem')]
    procedure EndFile()
    begin
        if FlatFileManagement.GetEstimatedNumberOfRecords() > 0 then
            BuildRecordTypeE();
        BuildRecordTypeZ();
        FlatFileManagement.EndFile();
    end;

    [Scope('OnPrem')]
    procedure FinalizeReport(FileName: Text)
    begin
        FlatFileManagement.DownloadFile(FileName);
    end;

    [Scope('OnPrem')]
    procedure StartNewRecord(Type: Option A,B,C,D,E,G,H,Z)
    var
        IDFileOffset: integer;
    begin
        if FlatFileManagement.RecordsPerFileExceeded(Type) then begin
            EndFile();
            StartNewFile();
        end;
        FlatFileManagement.StartNewRecord(Type); // TODO: addr record H
        if Type = ConstRecordType::B then
            IDFileOffset := 12;
        if Type = ConstRecordType::A then
            if GetTotalTransmissions() > 1 then begin
                WritePositionalValue(522 + IDFileOffset, 4, ConstFormat::NU, Format(ProgressiveTransmissionNo), false);
                WritePositionalValue(526 + IDFileOffset, 4, ConstFormat::NU, Format(GetTotalTransmissions()), false);
            end else begin
                WritePositionalValue(522 + IDFileOffset, 4, ConstFormat::NU, '0', false);
                WritePositionalValue(526 + IDFileOffset, 4, ConstFormat::NU, '0', false);
            end;

        if Type in [ConstRecordType::B] then
            WritePositionalValue(18, 8, ConstFormat::NU, '1', false);

        if Type in [ConstRecordType::C, ConstRecordType::D, ConstRecordType::E] then
            WritePositionalValue(18, 8, ConstFormat::NU, Format(FlatFileManagement.GetRecordCount(Type)), false);

        if Type in [ConstRecordType::B, ConstRecordType::C, ConstRecordType::D, ConstRecordType::E] then begin
            if (Type in [ConstRecordType::B, ConstRecordType::C, ConstRecordType::E, ConstRecordType::D]) and
               (CompanyInfo."Fiscal Code" <> '')
            then
                WritePositionalValue(2, 16, ConstFormat::AN, CompanyInfo."Fiscal Code", false)
            else
                WritePositionalValue(2, 16, ConstFormat::AN, CompanyInfo."VAT Registration No.", false);
            WritePositionalValue(74, 16, ConstFormat::AN, '08106710158', false);
        end;
    end;

    [Scope('OnPrem')]
    procedure FormatPadding(ValueFormat: Option; Value: Text; Length: Integer): Text
    begin
        exit(FlatFileManagement.FormatPadding(ValueFormat, Value, Length));
    end;

    [Scope('OnPrem')]
    procedure FormatDate(InputDate: Date; OutputFormat: Option): Text
    begin
        exit(FlatFileManagement.FormatDate(InputDate, OutputFormat));
    end;

    [Scope('OnPrem')]
    procedure FormatNum(Number: Decimal; ValueFormat: Option): Text
    begin
        exit(FlatFileManagement.FormatNum(Number, ValueFormat));
    end;

    local procedure NumericalVal(Input: Code[20]): Code[20]
    begin
        exit(DelChr(Input, '=', DelChr(Input, '=', '0123456789')));
    end;

    local procedure BuildRecordTypeA()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        StartNewRecord(ConstRecordType::A);
        WritePositionalValue(16, 5, ConstFormat::NU, 'NSP00', false);

        if VATReportSetup."Intermediary VAT Reg. No." <> '' then begin
            WritePositionalValue(21, 2, ConstFormat::NU, '10', false);
            WritePositionalValue(23, 16, ConstFormat::AN, VATReportSetup."Intermediary VAT Reg. No.", false);
        end else begin
            WritePositionalValue(21, 2, ConstFormat::NU, '01', false);
            if GetSpesometroAppointment(SpesometroAppointment) then
                WritePositionalValue(23, 16, ConstFormat::AN, SpesometroAppointment.GetValueOf(AppointmentFieldName::"Fiscal Code"), false)
            else
                WritePositionalValue(23, 16, ConstFormat::AN, CompanyInfo.GetTaxCode(), false);
        end;
    end;

    local procedure BuildRecordTypeB()
    begin
        StartNewRecord(ConstRecordType::B);

        WriteRecordBDocTypeValues(); // B8-B14
        WriteRecordBContentIndicatorValues(); // B15-26
        WriteRecordBCompanyInfoValues(); // B27-38
        WriteRecordBDateValues(); // B39-B40
        WriteRecordBAppointmentValues(); // B41-51
        WriteRecordBIntermediaryValues(); // B52-56
    end;

    local procedure BuildRecordTypeE()
    var
        Index: Integer;
        ConstModuleGroup: Option ,TA001001,TA002001,TA003001,TA003002,TA003003,TA004001,TA004002,TA005001,TA005002,TA006001,TA007001,TA008001,TA009001,TA010001,TA011001;
        ConstModuleGroupValue: Code[8];
    begin
        StartNewRecord(ConstRecordType::E);

        for Index := 1 to 15 do begin
            ConstModuleGroup := Index;
            ConstModuleGroupValue := CopyStr(Format(ConstModuleGroup), 1, 8);
            WriteBlockValue(ConstModuleGroupValue, ConstFormat::NP, Format(ModuleCount[Index]));
        end;
    end;

    local procedure BuildRecordTypeZ()
    var
        Index: Integer;
        Pos: Integer;
        Len: Integer;
    begin
        StartNewRecord(ConstRecordType::Z);
        Pos := 16;
        Len := 9;
        for Index := ConstRecordType::B to ConstRecordType::E do begin
            WritePositionalValue(Pos, Len, ConstFormat::NU, Format(FlatFileManagement.GetRecordCount(Index), 0, 1), false);
            Pos += Len;
        end;
    end;

    local procedure WriteRecordBDocTypeValues()
    var
        IDFileOffset: integer;
    begin
        IDFileOffset := 12;
        case ReportType of
            ReportType::Standard:
                WritePositionalValue(90, 3, ConstFormat::CB, '100', false);
            ReportType::Corrective:
                WritePositionalValue(90, 3, ConstFormat::CB, '010', false);
            ReportType::Cancellation:
                WritePositionalValue(90, 3, ConstFormat::CB, '001', false);
        end;

        if ReportType <> ReportType::Standard then begin
            WritePositionalValue(93, 17, ConstFormat::NU, OrgReportReceiptNo, false); //B11
            WritePositionalValue(110, 18, ConstFormat::NU, OrgReportNo, false);
        end else begin
            WritePositionalValue(93, 17, ConstFormat::NU, '0', false);
            WritePositionalValue(110, 18, ConstFormat::NU, '0', false);
        end;

        if ReportType = ReportType::Cancellation then
            WritePositionalValue(116 + IDFileOffset, 2, ConstFormat::CB, '00', false)
        else
            if DetailedExport then
                WritePositionalValue(116 + IDFileOffset, 2, ConstFormat::CB, '01', false)
            else
                WritePositionalValue(116 + IDFileOffset, 2, ConstFormat::CB, '10', false);
    end;

    local procedure WriteRecordBCompanyInfoValues()
    var
        IDFileOffset: integer;
    begin
        IDFileOffset := 12;
        WritePositionalValue(
          130 + IdFileOffset, 11, ConstFormat::PI, FlatFileManagement.CopyStringEnding(NumericalVal(CompanyInfo."VAT Registration No."), 11), false);
        WritePositionalValue(141 + IDFileOffset, 6, ConstFormat::AN, DelChr(CompanyInfo."Industrial Classification", '=', '.'), true);
        WritePositionalValue(147 + IDFileOffset, 12, ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInfo."Phone No."), true);
        WritePositionalValue(159 + IDFileOffset, 12, ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInfo."Fax No."), true);
        WritePositionalValue(171 + IDFileOffset, 50, ConstFormat::AN, CompanyInfo."E-Mail", true);
        WritePositionalValue(266 + IDFileOffset, 8, ConstFormat::DT, '00000000', false);
        WritePositionalValue(316 + IDFileOffset, 60, ConstFormat::AN, CompanyInfo.Name, true);
    end;

    local procedure WriteRecordBContentIndicatorValues()
    var
        CumRecordCount: array[11] of Integer;
        Index: Integer;
        FileStart: Integer;
        FileEnd: Integer;
        IDFileOffset: integer;
    begin
        IDFileOffset := 12;
        // Content of submission
        CumRecordCount[1] := 0;
        for Index := 1 to 10 do
            CumRecordCount[Index + 1] := CumRecordCount[Index] + TotalFrameworkCount[Index];

        // Calculate which frameworks that are going in the current file
        WritePositionalValue(118 + IDFileOffset, 12, ConstFormat::CN, '000000000000', false);
        FileStart := FlatFileManagement.GetMaxRecordsPerFile() * (ProgressiveTransmissionNo - 1);
        FileEnd := FlatFileManagement.GetMaxRecordsPerFile() * ProgressiveTransmissionNo;
        for Index := 1 to 10 do
            if CumRecordCount[Index + 1] - CumRecordCount[Index] > 0 then
                if ((CumRecordCount[Index] >= FileStart) and (CumRecordCount[Index] < FileEnd)) or
                   ((CumRecordCount[Index] <= FileStart) and (CumRecordCount[Index + 1] > FileStart))
                then
                    WritePositionalValue(117 + Index + IDFileOffset, 1, ConstFormat::CB, '1', false);
        if FlatFileManagement.GetEstimatedNumberOfRecords() > 0 then
            WritePositionalValue(129 + IDFileOffset, 1, ConstFormat::CB, '1', false);
    end;

    local procedure GetSpesometroAppointment(var SpesometroAppointment: Record "Spesometro Appointment"): Boolean
    begin
        if SpesometroAppointment.FindAppointmentByDate(StartDate, EndDate) then
            exit(true);

        // Fallback: Tax Representative, use a virtual entry
        if CompanyInfo."Tax Representative No." <> '' then begin
            SpesometroAppointment.Init();
            SpesometroAppointment."Appointment Code" := '06'; // Tax Representative
            SpesometroAppointment."Vendor No." := CompanyInfo."Tax Representative No.";
            SpesometroAppointment."Starting Date" := StartDate;
            SpesometroAppointment."Ending Date" := 0D;
            SpesometroAppointment.Designation := TaxRepresentativeTxt;
            exit(true);
        end;

        exit(false);
    end;

    local procedure WriteRecordBAppointmentValues()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
        IDFileOffset: integer;
    begin
        IDFileOffset := 12;
        if GetSpesometroAppointment(SpesometroAppointment) then begin
            WritePositionalValue(382 + IDFileOffset, 16, ConstFormat::CF, SpesometroAppointment.GetValueOf(AppointmentFieldName::"Fiscal Code"), false);
            WritePositionalValue(398 + IDFileOffset, 2, ConstFormat::NU, SpesometroAppointment."Appointment Code", false);
            WritePositionalValue(400 + IDFileOffset, 8, ConstFormat::DT, FormatDate(SpesometroAppointment."Starting Date", ConstFormat::DT), false);
            if SpesometroAppointment."Ending Date" <> 0D then
                WritePositionalValue(408 + IDFileOffset, 8, ConstFormat::DT, FormatDate(SpesometroAppointment."Ending Date", ConstFormat::DT), false)
            else
                WritePositionalValue(408 + IDFileOffset, 8, ConstFormat::NU, '00000000', false);

            if SpesometroAppointment.IsIndividual() then begin
                WritePositionalValue(416 + IDFileOffset, 24, ConstFormat::AN, SpesometroAppointment.GetValueOf(AppointmentFieldName::"First Name"), true);
                WritePositionalValue(440 + IDFileOffset, 20, ConstFormat::AN, SpesometroAppointment.GetValueOf(AppointmentFieldName::"Last Name"), true);
                WritePositionalValue(460 + IDFileOffset, 1, ConstFormat::AN, SpesometroAppointment.GetValueOf(AppointmentFieldName::Gender), true);
                WritePositionalValue(461 + IDFileOffset, 8, ConstFormat::DT, SpesometroAppointment.GetValueOf(AppointmentFieldName::"Date of Birth"), true);
                WritePositionalValue(469 + IDFileOffset, 40, ConstFormat::AN, SpesometroAppointment.GetValueOf(AppointmentFieldName::Municipality), true);
                WritePositionalValue(509 + IDFileOffset, 2, ConstFormat::PN, SpesometroAppointment.GetValueOf(AppointmentFieldName::Province), true);
            end else begin
                WritePositionalValue(461 + IDFileOffset, 8, ConstFormat::DT, '00000000', false);
                WritePositionalValue(511 + IDFileOffset, 24, ConstFormat::AN, SpesometroAppointment.Designation, false);
            end;
        end else begin
            WritePositionalValue(398 + IDFileOffset, 2, ConstFormat::NU, '00', false);
            WritePositionalValue(400 + IDFileOffset, 8, ConstFormat::NU, '00000000', false);
            WritePositionalValue(408 + IDFileOffset, 8, ConstFormat::NU, '00000000', false);
            WritePositionalValue(461 + IDFileOffset, 8, ConstFormat::DT, '00000000', false);
        end;
    end;

    local procedure WriteRecordBIntermediaryValues()
    var
        IDFileOffset: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWriteRecordBIntermediaryValues(VATReportSetup, FlatFileManagement, IsHandled);
        if IsHandled then
            exit;

        IDFileOffset := 12;
        if VATReportSetup."Intermediary VAT Reg. No." <> '' then begin
            WritePositionalValue(571 + IDFileOffset, 16, ConstFormat::CF, VATReportSetup."Intermediary VAT Reg. No.", false); //B52
            WritePositionalValue(587 + IDFileOffset, 5, ConstFormat::NU, VATReportSetup."Intermediary CAF Reg. No.", false); //B53
            if VATReportSetup."Intermediary CAF Reg. No." <> '' then
                WritePositionalValue(592 + IDFileOffset, 1, ConstFormat::NU, '2', false) //B54
            else
                WritePositionalValue(592 + IDFileOffset, 1, ConstFormat::NU, '1', false); //B54
            if VATReportSetup."Intermediary Date" <> 0D then
                WritePositionalValue(594 + IDFileOffset, 8, ConstFormat::DT, FormatDate(VATReportSetup."Intermediary Date", ConstFormat::DT), false)
            else
                WritePositionalValue(594 + IDFileOffset, 8, ConstFormat::NU, '00000000', false);
        end else begin
            WritePositionalValue(587 + IDFileOffset, 5, ConstFormat::NU, '00000', false); //B53
            WritePositionalValue(592 + IDFileOffset, 1, ConstFormat::NU, '0', false); //B54
            WritePositionalValue(594 + IDFileOffset, 8, ConstFormat::NU, '00000000', false); //B55
        end;
    end;

    local procedure WriteRecordBDateValues()
    var
        Date: Record Date;
        DateRef: Code[2];
        IDFileOffset: integer;
    begin
        IDFileOffset := 12;
        case PeriodType of
            PeriodType::Month:
                DateRef := CopyStr(FormatPadding(ConstFormat::NUp, Format(Date2DMY(StartDate, 2)), 2), 1, 2);
            PeriodType::Quarter:
                begin
                    Date.Reset();
                    Date.SetRange("Period Type", Date."Period Type"::Quarter);
                    Date.SetFilter("Period Start", '<=%1', StartDate);
                    Date.SetFilter("Period End", '>=%1', StartDate);
                    if Date.FindFirst() then
                        DateRef := 'T' + Format(Date."Period No.");
                end;
            PeriodType::Year:
                DateRef := '  ';
        end;

        WritePositionalValue(376 + IDFileOffset, 4, ConstFormat::DA, FormatDate(StartDate, ConstFormat::DA), false);
        if PeriodType <> PeriodType::Hide then
            WritePositionalValue(380 + IDFileOffset, 2, ConstFormat::AN, DateRef, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWriteRecordBIntermediaryValues(var VATReportSetup: Record "VAT Report Setup"; var FlatFileManagement: Codeunit "Flat File Management"; var IsHandled: Boolean)
    begin
    end;
}

