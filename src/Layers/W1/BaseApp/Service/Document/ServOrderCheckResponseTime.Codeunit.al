// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Calendar;
using Microsoft.Inventory.Location;
using Microsoft.Service.Contract;
using Microsoft.Service.Email;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Setup;
using System.Threading;

codeunit 5918 "ServOrder-Check Response Time"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        ServMgtSetup.Get();
        ServMgtSetup.TestField("First Warning Within (Hours)");
        RepairStatus.SetRange(Initial, true);
        if not RepairStatus.FindFirst() then
            Error(Text005, RepairStatus.TableCaption(), RepairStatus.FieldCaption(Initial));
        Clear(ServItemLine);
        Clear(ServHeader);
        ServHeader.SetCurrentKey(Status, "Response Date", "Response Time", Priority);
        ServHeader.SetRange(Status, ServHeader.Status::Pending);
        if ServHeader.FindSet() then
            repeat
                CheckDate1 := WorkDate();
                CheckTime1 := Time;
                CalculateCheckDate(CheckDate1, CheckTime1, ServMgtSetup."First Warning Within (Hours)");
                ServItemLine.SetCurrentKey("Document Type", "Document No.", "Response Date");
                ServItemLine.SetRange("Document Type", ServHeader."Document Type");
                ServItemLine.SetRange("Document No.", ServHeader."No.");
                ServItemLine.SetFilter("Response Date", '>%1&<=%2', 0D, CheckDate1);
                ServItemLine.SetFilter("Repair Status Code", RepairStatus.Code);
                if ServItemLine.FindSet() then begin
                    if ServHeader."Responsibility Center" <> '' then
                        RespCenter.Get(ServHeader."Responsibility Center");

                    repeat
                        WarningStatus := CheckResponseTime(ServItemLine."Response Date", ServItemLine."Response Time");
                        if WarningStatus > ServHeader."Warning Status" then
                            case WarningStatus of
                                1:
                                    if RespCenter."E-Mail" <> '' then
                                        SendEMail(RespCenter."E-Mail")
                                    else
                                        SendEMail(ServMgtSetup."Send First Warning To");
                                2:
                                    if RespCenter."E-Mail" <> '' then
                                        SendEMail(RespCenter."E-Mail")
                                    else
                                        SendEMail(ServMgtSetup."Send Second Warning To");
                                3:
                                    if RespCenter."E-Mail" <> '' then
                                        SendEMail(RespCenter."E-Mail")
                                    else
                                        SendEMail(ServMgtSetup."Send Third Warning To");
                            end;

                    until ServItemLine.Next() = 0;
                end;
            until ServHeader.Next() = 0
        else  // No Pending ServiceHeaders -> deactivate the job queue entry.
            Rec.SetStatus(Rec.Status::"On Hold");
    end;

    var
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServMgtSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        ServHour: Record "Service Hour";
        RepairStatus: Record "Repair Status";
        WarningStatus: Integer;
        CheckDate1: Date;
        CheckDate2: Date;
        CheckDate3: Date;
        CheckTime1: Time;
        CheckTime2: Time;
        CheckTime3: Time;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1. Warning Message for Service Order %2';
        Text001: Label 'Check the response time for service order %1';
#pragma warning restore AA0470
        Text004: Label 'Email address is missing.';
#pragma warning disable AA0470
        Text005: Label '%1 with the field %2 selected cannot be found.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServHrNotSetupErr: Label '%1 is not setup. Please set it up before running this scenario.', Comment = '%1 = page name';

    local procedure CheckResponseTime(ResponseDate: Date; ResponseTime: Time): Integer
    begin
        if ResponseDate = 0D then
            exit(0);

        if ServMgtSetup."Third Warning Within (Hours)" <> 0 then begin
            CheckDate3 := WorkDate();
            CheckTime3 := Time;
            CalculateCheckDate(CheckDate3, CheckTime3, ServMgtSetup."Third Warning Within (Hours)");
            if ResponseDate < CheckDate3 then
                exit(3);
            if ResponseDate = CheckDate3 then
                if ResponseTime < CheckTime3 then
                    exit(3);
        end;

        if ServMgtSetup."Second Warning Within (Hours)" <> 0 then begin
            CheckDate2 := WorkDate();
            CheckTime2 := Time;
            CalculateCheckDate(CheckDate2, CheckTime2, ServMgtSetup."Second Warning Within (Hours)");
            if ResponseDate < CheckDate2 then
                exit(2);
            if ResponseDate = CheckDate2 then
                if ResponseTime < CheckTime2 then
                    exit(2);
        end;

        if ResponseDate < CheckDate1 then
            exit(1);
        if ResponseDate = CheckDate1 then
            if ResponseTime < CheckTime1 then
                exit(1);

        exit(0);
    end;

    local procedure SendEMail(SendtoAddress: Text[80])
    var
        ServEmailQueue: Record "Service Email Queue";
    begin
        if SendtoAddress = '' then
            Error(Text004);

        ServHeader."Warning Status" := WarningStatus;
        ServHeader.Modify();

        ServEmailQueue.Init();
        ServEmailQueue."To Address" := SendtoAddress;
        ServEmailQueue."Copy-to Address" := '';
        ServEmailQueue."Subject Line" := StrSubstNo(Text000, Format(WarningStatus), ServHeader."No.");
        ServEmailQueue."Body Line" := StrSubstNo(Text001, ServHeader."No.");
        ServEmailQueue."Attachment Filename" := '';
        ServEmailQueue."Document Type" := ServEmailQueue."Document Type"::"Service Order";
        ServEmailQueue."Document No." := ServHeader."No.";
        ServEmailQueue.Status := ServEmailQueue.Status::" ";
        ServEmailQueue.Insert(true);
        ServEmailQueue.ScheduleInJobQueue();
    end;

    local procedure CalculateCheckDate(var CheckDate: Date; var CheckTime: Time; HoursAhead: Decimal)
    var
        CalChange: Record "Customized Calendar Change";
        ServMgtSetup: Record "Service Mgt. Setup";
        CalendarMgmt: Codeunit "Calendar Management";
        ServiceHours: Page "Default Service Hours";
        TotTime: Decimal;
        LastTotTime: Decimal;
        HoursLeft: Decimal;
        HoursOnLastDay: Decimal;
        Holiday: Boolean;
        TempDate: Date;
        TempDay: Integer;
    begin
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Base Calendar Code");
        CalendarMgmt.SetSource(ServMgtSetup, CalChange);
        ServHour.Reset();
        ServHour.SetRange("Service Contract No.", '');
        ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::" ");
        TotTime := 0;
        LastTotTime := 0;
        TempDate := CheckDate;
        HoursLeft := HoursAhead * 3600000;
        if ServHour.IsEmpty() then
            Error(ServHrNotSetupErr, ServiceHours.Caption);
        repeat
            TempDay := Date2DWY(TempDate, 1) - 1;
            HoursOnLastDay := 0;
            ServHour.SetRange(Day, TempDay);
            if ServHour.FindFirst() then begin
                if ServHour."Valid on Holidays" then
                    Holiday := false
                else
                    Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CalChange);
                if not Holiday then begin
                    if TempDate = CheckDate then begin
                        if CheckTime < ServHour."Ending Time" then
                            if HoursLeft > CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", CheckTime) then begin
                                TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", CheckTime);
                                HoursOnLastDay := CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", CheckTime);
                            end else begin
                                TotTime := TotTime + HoursLeft;
                                HoursOnLastDay := HoursLeft;
                            end;
                    end else
                        if HoursLeft > CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time") then begin
                            TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                            HoursOnLastDay := CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                        end else begin
                            TotTime := TotTime + HoursLeft;
                            HoursOnLastDay := HoursLeft;
                        end;
                    if LastTotTime < TotTime then begin
                        HoursLeft := HoursLeft - (TotTime - LastTotTime);
                        LastTotTime := TotTime;
                    end;
                end;
            end;
            TempDate := TempDate + 1;
        until HoursLeft <= 0;

        if TotTime > 0 then begin
            if CheckDate = TempDate - 1 then
                CheckTime := CheckTime + HoursOnLastDay
            else
                CheckTime := ServHour."Starting Time" + HoursOnLastDay;
            CheckDate := TempDate - 1;
        end;
    end;
}

