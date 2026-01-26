// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 10700 "Due Date-Adjust"
{

    trigger OnRun()
    begin
    end;

    procedure SalesAdjustDueDate(var DueDate: Date; MinDate: Date; MaxDate: Date; CustomerNo: Code[20])
    var
        PaymentDay: Record "Payment Day";
        NonPaymentPeriod: Record "Non-Payment Period";
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit;
        if not Customer.Get(CustomerNo) then
            exit;

        SetNonPaymentPeriodFilterAndFields(NonPaymentPeriod, NonPaymentPeriod."Table Name"::Customer, Customer."Non-Paymt. Periods Code");
        SetPaymentDayFilterAndFields(PaymentDay, PaymentDay."Table Name"::Customer, Customer."Payment Days Code");
        AdjustDate(NonPaymentPeriod, PaymentDay, DueDate, MinDate, MaxDate);
    end;

    procedure PurchAdjustDueDate(var DueDate: Date; MinDate: Date; MaxDate: Date; VendorNo: Code[20])
    var
        PaymentDay: Record "Payment Day";
        NonPaymentPeriod: Record "Non-Payment Period";
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
		IsHandled: Boolean;
    begin
        if VendorNo = '' then
            exit;
        if not Vendor.Get(VendorNo) then
            exit;

        IsHandled := false;
        OnPurchAdjustDueDateOnBeforeSetNonPaymentPeriodFilterAndFields(NonPaymentPeriod, Vendor, IsHandled);
        if not IsHandled then
			if Vendor."Non-Paymt. Periods Code" <> '' then
				SetNonPaymentPeriodFilterAndFields(NonPaymentPeriod, NonPaymentPeriod."Table Name"::Vendor, Vendor."Non-Paymt. Periods Code")
			else begin
				CompanyInfo.Get();
				SetNonPaymentPeriodFilterAndFields(
				  NonPaymentPeriod, NonPaymentPeriod."Table Name"::"Company Information", CompanyInfo."Non-Paymt. Periods Code")
        end;

        IsHandled := false;
        OnPurchAdjustDueDateOnBeforeSetPaymentDayFilterAndFields(PaymentDay, Vendor, IsHandled);
        if not IsHandled then		
			if Vendor."Payment Days Code" <> '' then
				SetPaymentDayFilterAndFields(PaymentDay, PaymentDay."Table Name"::Vendor, Vendor."Payment Days Code")
			else
				SetPaymentDayFilterAndFieldsFromCompany(PaymentDay);

        AdjustDate(NonPaymentPeriod, PaymentDay, DueDate, MinDate, MaxDate);

        OnAfterPurchAdjustDueDate(DueDate, MinDate, MaxDate, VendorNo, PaymentDay);
    end;

    local procedure SetPaymentDayFilterAndFieldsFromCompany(var PaymentDay: Record "Payment Day")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        SetPaymentDayFilterAndFields(PaymentDay, PaymentDay."Table Name"::"Company Information", CompanyInformation."Payment Days Code");
    end;

    local procedure AdjustDate(var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; var DueDate: Date; MinDate: Date; MaxDate: Date)
    var
        InitialDate: Date;
        ForwardCalculation: Boolean;
    begin
        if DueDateIsGreaterMaxAvailDate(DueDate, MinDate, MaxDate) then
            DueDate := MaxDate;
        ForwardCalculation := true;

        repeat
            InitialDate := DueDate;
            if not NonPaymentPeriod.IsEmpty() then begin
                if ForwardCalculation then begin
                    DueDate := AdjustToNonPaymentPeriod(NonPaymentPeriod, DueDate, ForwardCalculation);
                    if DueDateIsGreaterMaxAvailDate(DueDate, MinDate, MaxDate) then
                        ForwardCalculation := false
                end;
                if not ForwardCalculation then
                    DueDate := AdjustToNonPaymentPeriod(NonPaymentPeriod, InitialDate, ForwardCalculation);
            end;
            if not PaymentDay.IsEmpty() then begin
                if ForwardCalculation then begin
                    DueDate := AdjustToPaymentDay(PaymentDay, DueDate, '>', '-', '+');
                    if DueDateIsGreaterMaxAvailDate(DueDate, MinDate, MaxDate) then
                        ForwardCalculation := false
                end;
                if not ForwardCalculation then
                    DueDate := AdjustToPaymentDay(PaymentDay, InitialDate, '<', '+', '-');
            end;
            if (DueDate < MinDate) or PaymentDayInNonPaymentPeriod(NonPaymentPeriod, PaymentDay, DueDate) then begin
                DueDate := 0D;
                exit
            end
        until (DueDate = InitialDate)
    end;

    local procedure AdjustToNonPaymentPeriod(var NonPaymentPeriod: Record "Non-Payment Period"; DueDate: Date; ForwardCalculation: Boolean): Date
    var
        PreviousFromDate: Date;
    begin
        PreviousFromDate := NonPaymentPeriod."From Date";
        NonPaymentPeriod."From Date" := DueDate;
        if NonPaymentPeriod.Find('=<') and (DueDate <= NonPaymentPeriod."To Date") then begin
            if ForwardCalculation then
                DueDate := NonPaymentPeriod."To Date" + 1
            else
                DueDate := NonPaymentPeriod."From Date" - 1;

            OnAdjustToNonPaymentPeriodOnAfterCalcDueDate();
        end else
            if PreviousFromDate <> 0D then
                NonPaymentPeriod."From Date" := PreviousFromDate;
        exit(DueDate)
    end;

    local procedure AdjustToPaymentDay(var PaymentDay: Record "Payment Day"; DueDate: Date; DirectionText: Text[1]; FindText: Text[1]; Sign: Text[1]): Date
    begin
        if (CalcDate('<CM>', DueDate) = DueDate) and PaymentDay.Get(PaymentDay."Table Name", PaymentDay.Code, 31) then
            exit(DueDate);
        PaymentDay."Day of the month" := Date2DMY(DueDate, 1);
        if PaymentDay.Find('=') then
            exit(DueDate);
        if PaymentDay.Find(DirectionText) then
            exit(CalcDate(StrSubstNo('<%1D%2>', Sign, PaymentDay."Day of the month"), DueDate));
        if PaymentDay.Find(FindText) then
            exit(CalcDate(StrSubstNo('<%1D%2>', Sign, PaymentDay."Day of the month"), DueDate));
        exit(DueDate)
    end;

    local procedure SetPaymentDayFilterAndFields(var PaymentDay: Record "Payment Day"; TableNameOption: Option; PaymentDayCode: Code[20])
    begin
        PaymentDay.Reset();
        PaymentDay.SetRange("Table Name", TableNameOption);
        PaymentDay.SetRange(Code, PaymentDayCode);
        PaymentDay."Table Name" := TableNameOption;
        PaymentDay.Code := PaymentDayCode
    end;

    local procedure SetNonPaymentPeriodFilterAndFields(var NonPaymentPeriod: Record "Non-Payment Period"; TableNameOption: Option; NonPaymentPeriodCode: Code[20])
    begin
        NonPaymentPeriod.Reset();
        NonPaymentPeriod.SetRange("Table Name", TableNameOption);
        NonPaymentPeriod.SetRange(Code, NonPaymentPeriodCode);
        NonPaymentPeriod."Table Name" := TableNameOption;
        NonPaymentPeriod.Code := NonPaymentPeriodCode
    end;

    local procedure PaymentDayInNonPaymentPeriod(var NonPaymentPeriod: Record "Non-Payment Period"; PaymentDay: Record "Payment Day"; PaymentDate: Date): Boolean
    begin
        if not NonPaymentPeriod.IsEmpty() and not PaymentDay.IsEmpty() then begin
            if (PaymentDate >= NonPaymentPeriod."From Date") and (PaymentDate <= NonPaymentPeriod."To Date") then
                exit(true);

            exit(false);
        end;
    end;

    local procedure DueDateIsGreaterMaxAvailDate(DueDate: Date; MinDate: Date; MaxDate: Date): Boolean
    begin
        exit((DueDate > MaxDate) and (MinDate <> MaxDate));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchAdjustDueDate(var DueDate: Date; MinDate: Date; MaxDate: Date; VendorNo: Code[20]; var PaymentDay: Record "Payment Day")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustToNonPaymentPeriodOnAfterCalcDueDate()
    begin
    end;
	
	[IntegrationEvent(false, false)]
    local procedure OnPurchAdjustDueDateOnBeforeSetNonPaymentPeriodFilterAndFields(var NonPaymentPeriod: Record "Non-Payment Period"; Vendor: Record Vendor; IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchAdjustDueDateOnBeforeSetPaymentDayFilterAndFields(var PaymentDay: Record "Payment Day"; Vendor: Record Vendor; IsHandled: Boolean)
    begin
    end;
}

