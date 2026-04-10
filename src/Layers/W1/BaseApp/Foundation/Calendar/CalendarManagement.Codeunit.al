// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 7600 "Calendar Management"
{
    Permissions = tabledata "Base Calendar Change" = r;

    trigger OnRun()
    begin
    end;

    var
        CurrCustomizedCalendarChange: Record "Customized Calendar Change";
        TempCustChange: Record "Customized Calendar Change" temporary;
#pragma warning disable AA0470
        NegativeExprErr: Label 'The expression %1 cannot be negative.';
#pragma warning restore AA0470
        SourceErr: Label 'The calendar source must be set by a source record.';

    procedure SetSource(SourceVariant: Variant; var NewCustomCalendarChange: Record "Customized Calendar Change")
    begin
        OnBeforeSetSource(SourceVariant, NewCustomCalendarChange);

        if not SourceVariant.IsRecord then
            Error(SourceErr);

        FillSource(SourceVariant, NewCustomCalendarChange);
        CombineChanges(NewCustomCalendarChange, TempCustChange)
    end;

    procedure FillSource(SourceVariant: Variant; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceVariant);
        case RecRef.RecordId.TableNo of
            Database::"Base Calendar":
                SetSourceBaseCalendar(RecRef, CustomCalendarChange);
            Database::"Company Information":
                SetSourceCompany(RecRef, CustomCalendarChange);
            Database::Location:
                SetSourceLocation(RecRef, CustomCalendarChange);
            Database::Customer:
                SetSourceCustomer(RecRef, CustomCalendarChange);
            Database::Vendor:
                SetSourceVendor(RecRef, CustomCalendarChange);
            Database::"Shipping Agent Services":
                SetSourceShippingAgentServices(RecRef, CustomCalendarChange);
            Database::"Customized Calendar Entry":
                SetSourceCustomizedCalendarEntry(RecRef, CustomCalendarChange);
            else
                OnFillSourceRec(RecRef, CustomCalendarChange);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillSourceRec(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    local procedure SetSourceBaseCalendar(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        BaseCalendar: Record "Base Calendar";
    begin
        RecRef.SetTable(BaseCalendar);
        CustomCalendarChange.SetSource(CustomCalendarChange."Source Type"::Company, '', '', BaseCalendar.Code);
    end;

    local procedure SetSourceCompany(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        CompanyInfo: Record "Company Information";
    begin
        RecRef.SetTable(CompanyInfo);
        CustomCalendarChange.SetSource(CustomCalendarChange."Source Type"::Company, '', '', CompanyInfo."Base Calendar Code");
    end;

    local procedure SetSourceLocation(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        Location: Record Location;
    begin
        RecRef.SetTable(Location);
        CustomCalendarChange.SetSource(
            CustomCalendarChange."Source Type"::Location, Location.Code, '', Location."Base Calendar Code");
    end;

    local procedure SetSourceCustomer(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        Customer: Record Customer;
    begin
        RecRef.SetTable(Customer);
        CustomCalendarChange.SetSource(
            CustomCalendarChange."Source Type"::Customer, Customer."No.", '', Customer."Base Calendar Code");
    end;

    local procedure SetSourceCustomizedCalendarEntry(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        CustomizedCalendarEntry: record "Customized Calendar Entry";
    begin
        RecRef.SetTable(CustomizedCalendarEntry);
        CustomCalendarChange.SetSource(
            CustomizedCalendarEntry."Source Type", CustomizedCalendarEntry."Source Code",
            CustomizedCalendarEntry."Additional Source Code", CustomizedCalendarEntry."Base Calendar Code");
    end;

    local procedure SetSourceShippingAgentServices(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        OnBeforeSetSourceShippingAgentServices(ShippingAgentServices);
        RecRef.SetTable(ShippingAgentServices);
        CustomCalendarChange.SetSource(
            CustomCalendarChange."Source Type"::"Shipping Agent", ShippingAgentServices."Shipping Agent Code",
            ShippingAgentServices.Code, ShippingAgentServices."Base Calendar Code");
    end;

    local procedure SetSourceVendor(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        Vendor: Record Vendor;
    begin
        RecRef.SetTable(Vendor);
        CustomCalendarChange.SetSource(
            CustomCalendarChange."Source Type"::Vendor, Vendor."No.", '', Vendor."Base Calendar Code");
    end;

    procedure ShowCustomizedCalendar(SourceVariant: Variant)
    var
        TempCustomizedCalEntry: Record "Customized Calendar Entry" temporary;
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        FillSource(SourceVariant, CustomizedCalendarChange);
        TempCustomizedCalEntry.CopyFromCustomizedCalendarChange(CustomizedCalendarChange);
        TempCustomizedCalEntry.Insert();
        PAGE.Run(PAGE::"Customized Calendar Entries", TempCustomizedCalEntry);
    end;

    procedure GetMaxDate(): Date
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.FindLast();
        exit(NormalDate(Date."Period End"));
    end;

    procedure IsNonworkingDay(TargetDate: Date; var CustomizedCalendarChange: Record "Customized Calendar Change"): Boolean;
    begin
        OnBeforeIsNonworkingDay(TargetDate, CustomizedCalendarChange);
        CustomizedCalendarChange.Date := TargetDate;
        CheckDateStatus(CustomizedCalendarChange);
        exit(CustomizedCalendarChange.Nonworking);
    end;

    procedure CheckDateStatus(var TargetCustomizedCalendarChange: Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDateStatus(TargetCustomizedCalendarChange, IsHandled);
        if not IsHandled then begin
            CombineChanges(TargetCustomizedCalendarChange, TempCustChange);
            OnCheckDateStatusOnAfterCombineChanges(TargetCustomizedCalendarChange, TempCustChange);

            TargetCustomizedCalendarChange.Description := '';
            TargetCustomizedCalendarChange.Nonworking := false;
            if CurrCustomizedCalendarChange.IsBlankSource() then
                exit;

            TempCustChange.Reset();
            TempCustChange.SetCurrentKey("Entry No.");
            if TempCustChange.FindSet() then
                repeat
                    if TempCustChange.IsDateCustomized(TargetCustomizedCalendarChange.Date) then begin
                        TargetCustomizedCalendarChange.Description := TempCustChange.Description;
                        TargetCustomizedCalendarChange.Nonworking := TempCustChange.Nonworking;
                        OnCheckDateStatusAfterDateCustomized(TargetCustomizedCalendarChange, TempCustChange);
                        exit;
                    end;
                until TempCustChange.Next() = 0;
        end;
        OnAfterCheckDateStatus(TargetCustomizedCalendarChange);
    end;

    local procedure CombineChanges(NewCustomizedCalendarChange: Record "Customized Calendar Change"; var TempCustomizedCalendarChange: record "Customized Calendar Change" temporary)
    begin
        if CurrCustomizedCalendarChange.IsEqualSource(NewCustomizedCalendarChange) then
            exit;

        TempCustomizedCalendarChange.Reset();
        TempCustomizedCalendarChange.DeleteAll();

        AddCustomizedCalendarChanges(NewCustomizedCalendarChange, TempCustomizedCalendarChange);
        AddBaseCalendarChanges(NewCustomizedCalendarChange, TempCustomizedCalendarChange);

        CurrCustomizedCalendarChange := NewCustomizedCalendarChange;
    end;

    local procedure AddCustomizedCalendarChanges(NewCustomizedCalendarChange: Record "Customized Calendar Change"; var TempCustomizedCalendarChange: record "Customized Calendar Change" temporary)
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        EntryNo: Integer;
    begin
        OnBeforeAddCustomizedCalendarChanges(CustomizedCalendarChange);

        if TempCustomizedCalendarChange.FindLast() then
            EntryNo := TempCustomizedCalendarChange."Entry No.";

        CustomizedCalendarChange.Reset();
        CustomizedCalendarChange.SetRange("Source Type", NewCustomizedCalendarChange."Source Type");
        CustomizedCalendarChange.SetRange("Source Code", NewCustomizedCalendarChange."Source Code");
        CustomizedCalendarChange.SetRange("Base Calendar Code", NewCustomizedCalendarChange."Base Calendar Code");
        CustomizedCalendarChange.SetRange("Additional Source Code", NewCustomizedCalendarChange."Additional Source Code");
        if CustomizedCalendarChange.FindSet() then
            repeat
                EntryNo += 1;
                TempCustomizedCalendarChange := CustomizedCalendarChange;
                TempCustomizedCalendarChange."Entry No." := EntryNo;
                OnCombineCustomCalendarChange(CustomizedCalendarChange, TempCustomizedCalendarChange);
                TempCustomizedCalendarChange.Insert();
            until CustomizedCalendarChange.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCombineCustomCalendarChange(CustomCalChange: Record "Customized Calendar Change"; var CustomizedCalendarChange: record "Customized Calendar Change")
    begin
    end;

    local procedure AddBaseCalendarChanges(NewCustomizedCalendarChange: Record "Customized Calendar Change"; var TempCustomizedCalendarChange: record "Customized Calendar Change" temporary)
    var
        BaseCalendarChange: Record "Base Calendar Change";
        EntryNo: Integer;
    begin
        OnBeforeAddBaseCalendarChanges(NewCustomizedCalendarChange, TempCustomizedCalendarChange, BaseCalendarChange);

        if TempCustomizedCalendarChange.FindLast() then
            EntryNo := TempCustomizedCalendarChange."Entry No.";

        BaseCalendarChange.Reset();
        BaseCalendarChange.SetRange("Base Calendar Code", NewCustomizedCalendarChange."Base Calendar Code");
        if BaseCalendarChange.FindSet() then
            repeat
                EntryNo += 1;
                TempCustomizedCalendarChange.Init();
                TempCustomizedCalendarChange."Entry No." := EntryNo;
                TempCustomizedCalendarChange."Source Type" := NewCustomizedCalendarChange."Source Type";
                TempCustomizedCalendarChange."Source Code" := NewCustomizedCalendarChange."Source Code";
                TempCustomizedCalendarChange."Additional Source Code" := NewCustomizedCalendarChange."Additional Source Code";
                TempCustomizedCalendarChange."Base Calendar Code" := BaseCalendarChange."Base Calendar Code";
                TempCustomizedCalendarChange.Date := BaseCalendarChange.Date;
                TempCustomizedCalendarChange.Description := BaseCalendarChange.Description;
                TempCustomizedCalendarChange.Day := BaseCalendarChange.Day;
                TempCustomizedCalendarChange.Nonworking := BaseCalendarChange.Nonworking;
                TempCustomizedCalendarChange."Recurring System" := BaseCalendarChange."Recurring System";
                OnCombineBaseCalendarChange(BaseCalendarChange, TempCustomizedCalendarChange);
                TempCustomizedCalendarChange.Insert();
            until BaseCalendarChange.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCombineBaseCalendarChange(BaseCalendarChange: Record "Base Calendar Change"; var CustomizedCalendarChange: record "Customized Calendar Change")
    begin
    end;

    procedure CreateWhereUsedEntries(BaseCalendarCode: Code[10])
    var
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        WhereUsedBaseCalendar.DeleteAll();
        AddWhereUsedBaseCalendarCompany(BaseCalendarCode);
        AddWhereUsedBaseCalendarCustomer(BaseCalendarCode);
        AddWhereUsedBaseCalendarLocation(BaseCalendarCode);
        AddWhereUsedBaseCalendarVendor(BaseCalendarCode);
        AddWhereUsedBaseCalendarShippingAgentServices(BaseCalendarCode);
        OnCreateWhereUsedEntries(BaseCalendarCode);
        Commit();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateWhereUsedEntries(BaseCalendarCode: code[10])
    begin
    end;

    local procedure AddWhereUsedBaseCalendarCompany(BaseCalendarCode: code[10])
    var
        CompanyInfo: Record "Company Information";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        if CompanyInfo.Get() then
            if CompanyInfo."Base Calendar Code" = BaseCalendarCode then begin
                WhereUsedBaseCalendar.Init();
                WhereUsedBaseCalendar."Base Calendar Code" := CompanyInfo."Base Calendar Code";
                WhereUsedBaseCalendar."Source Type" := WhereUsedBaseCalendar."Source Type"::Company;
                WhereUsedBaseCalendar."Source Name" :=
                  CopyStr(CompanyInfo.Name, 1, MaxStrLen(WhereUsedBaseCalendar."Source Name"));
                WhereUsedBaseCalendar."Customized Changes Exist" := CustomizedChangesExist(CompanyInfo);
                WhereUsedBaseCalendar.Insert();
            end;
    end;

    local procedure AddWhereUsedBaseCalendarCustomer(BaseCalendarCode: code[10])
    var
        Customer: Record Customer;
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        Customer.SetLoadFields("Base Calendar Code", "Name");
        Customer.SetRange("Base Calendar Code", BaseCalendarCode);
        if Customer.FindSet() then
            repeat
                WhereUsedBaseCalendar.Init();
                WhereUsedBaseCalendar."Base Calendar Code" := Customer."Base Calendar Code";
                WhereUsedBaseCalendar."Source Type" := WhereUsedBaseCalendar."Source Type"::Customer;
                WhereUsedBaseCalendar."Source Code" := Customer."No.";
                WhereUsedBaseCalendar."Source Name" :=
                  CopyStr(Customer.Name, 1, MaxStrLen(WhereUsedBaseCalendar."Source Name"));
                WhereUsedBaseCalendar."Customized Changes Exist" := CustomizedChangesExist(Customer);
                WhereUsedBaseCalendar.Insert();
            until Customer.Next() = 0;
    end;

    local procedure AddWhereUsedBaseCalendarLocation(BaseCalendarCode: code[10])
    var
        Location: Record Location;
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        Location.SetLoadFields("Base Calendar Code", "Name");
        Location.SetRange("Base Calendar Code", BaseCalendarCode);
        if Location.FindSet() then
            repeat
                WhereUsedBaseCalendar.Init();
                WhereUsedBaseCalendar."Base Calendar Code" := Location."Base Calendar Code";
                WhereUsedBaseCalendar."Source Type" := WhereUsedBaseCalendar."Source Type"::Location;
                WhereUsedBaseCalendar."Source Code" := Location.Code;
                WhereUsedBaseCalendar."Source Name" :=
                  CopyStr(Location.Name, 1, MaxStrLen(WhereUsedBaseCalendar."Source Name"));
                WhereUsedBaseCalendar."Customized Changes Exist" := CustomizedChangesExist(Location);
                WhereUsedBaseCalendar.Insert();
            until Location.Next() = 0;
    end;

    local procedure AddWhereUsedBaseCalendarShippingAgentServices(BaseCalendarCode: code[10])
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        ShippingAgentServices.SetLoadFields("Base Calendar Code", "Description");
        ShippingAgentServices.SetRange("Base Calendar Code", BaseCalendarCode);
        if ShippingAgentServices.FindSet() then
            repeat
                WhereUsedBaseCalendar.Init();
                WhereUsedBaseCalendar."Base Calendar Code" := ShippingAgentServices."Base Calendar Code";
                WhereUsedBaseCalendar."Source Type" := WhereUsedBaseCalendar."Source Type"::"Shipping Agent";
                WhereUsedBaseCalendar."Source Code" := ShippingAgentServices."Shipping Agent Code";
                WhereUsedBaseCalendar."Additional Source Code" := ShippingAgentServices.Code;
                WhereUsedBaseCalendar."Source Name" :=
                  CopyStr(ShippingAgentServices.Description, 1, MaxStrLen(WhereUsedBaseCalendar."Source Name"));
                WhereUsedBaseCalendar."Customized Changes Exist" := CustomizedChangesExist(ShippingAgentServices);
                WhereUsedBaseCalendar.Insert();
            until ShippingAgentServices.Next() = 0;
    end;

    local procedure AddWhereUsedBaseCalendarVendor(BaseCalendarCode: code[10])
    var
        Vendor: Record Vendor;
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        Vendor.SetLoadFields("Base Calendar Code", "Name");
        Vendor.SetRange("Base Calendar Code", BaseCalendarCode);
        if Vendor.FindSet() then
            repeat
                WhereUsedBaseCalendar.Init();
                WhereUsedBaseCalendar."Base Calendar Code" := Vendor."Base Calendar Code";
                WhereUsedBaseCalendar."Source Type" := WhereUsedBaseCalendar."Source Type"::Vendor;
                WhereUsedBaseCalendar."Source Code" := Vendor."No.";
                WhereUsedBaseCalendar."Source Name" :=
                  CopyStr(Vendor.Name, 1, MaxStrLen(WhereUsedBaseCalendar."Source Name"));
                WhereUsedBaseCalendar."Customized Changes Exist" := CustomizedChangesExist(Vendor);
                WhereUsedBaseCalendar.Insert();
            until Vendor.Next() = 0;
    end;

    procedure CustomizedChangesExist(SourceVariant: Variant): Boolean
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        FillSource(SourceVariant, CustomizedCalendarChange);
        CustomizedCalendarChange.Reset();
        CustomizedCalendarChange.SetRange("Source Type", CustomizedCalendarChange."Source Type");
        CustomizedCalendarChange.SetRange("Source Code", CustomizedCalendarChange."Source Code");
        CustomizedCalendarChange.SetRange("Additional Source Code", CustomizedCalendarChange."Additional Source Code");
        CustomizedCalendarChange.SetRange("Base Calendar Code", CustomizedCalendarChange."Base Calendar Code");
        exit(not CustomizedCalendarChange.IsEmpty());
    end;

    procedure CalcDateBOC(OrgDateExpression: Text[30]; OrgDate: Date; CustomCalendarChange: array[2] of Record "Customized Calendar Change"; CheckBothCalendars: Boolean): Date
    var
        CompanyInfo: Record "Company Information";
        CalendarMgt: array[2] of Codeunit "Calendar Management";
        DateFormula: DateFormula;
        NegDateFormula: DateFormula;
        LoopCounter: Integer;
        NewDate: Date;
        LoopFactor: Integer;
        CalConvTimeFrame: Integer;
        CalendarChangeNo: Integer;
        IsHandled: Boolean;
    begin
        if not IsOnBeforeCalcDateBOCHandled(CustomCalendarChange, CalConvTimeFrame) then begin
            CustomCalendarChange[1].AdjustSourceType();
            CustomCalendarChange[2].AdjustSourceType();

            if CompanyInfo.Get() then
                CalConvTimeFrame := CalcDate(CompanyInfo."Cal. Convergence Time Frame", WorkDate()) - WorkDate();

            CustomCalendarChange[1].CalcCalendarCode();
            CustomCalendarChange[2].CalcCalendarCode();

            OnCalcDateBOCOnAfterGetCalendarCodes(CustomCalendarChange, CalConvTimeFrame);
        end;

        IsHandled := false;
        NewDate := 0D;
        OnCalcDateBOCOnBeforeCalcNewDate(OrgDateExpression, OrgDate, CustomCalendarChange, CheckBothCalendars, NewDate, IsHandled);
        if IsHandled then
            exit(NewDate);

        Evaluate(DateFormula, OrgDateExpression);
        Evaluate(NegDateFormula, '<-0D>');

        if OrgDate = 0D then
            OrgDate := WorkDate();
        if (CalcDate(DateFormula, OrgDate) >= OrgDate) and (DateFormula <> NegDateFormula) then
            LoopFactor := 1
        else
            LoopFactor := -1;

        CalendarChangeNo := 1;
        if CheckBothCalendars and (CustomCalendarChange[1]."Base Calendar Code" = '') and (CustomCalendarChange[2]."Base Calendar Code" <> '') then
            CalendarChangeNo := 2;
        NewDate := OrgDate;
        if CalcDate(DateFormula, OrgDate) <> OrgDate then
            repeat
                NewDate := NewDate + LoopFactor;
                CustomCalendarChange[CalendarChangeNo].Date := NewDate;
                CalendarMgt[CalendarChangeNo].CheckDateStatus(CustomCalendarChange[CalendarChangeNo]);
                OnCalcDateBOCOnAfterCheckDates(CustomCalendarChange[CalendarChangeNo]);
                if not CustomCalendarChange[CalendarChangeNo].Nonworking then
                    LoopCounter := LoopCounter + 1;
                if NewDate >= OrgDate + CalConvTimeFrame then
                    LoopCounter := Abs(CalcDate(DateFormula, OrgDate) - OrgDate);
                if LoopFactor = -1 then
                    if NewDate <= OrgDate - CalConvTimeFrame then
                        LoopCounter := Abs(CalcDate(DateFormula, OrgDate) - OrgDate);
            until LoopCounter = Abs(CalcDate(DateFormula, OrgDate) - OrgDate);

        LoopCounter := 0;
        repeat
            LoopCounter := LoopCounter + 1;
            CalendarMgt[1].IsNonworkingDay(NewDate, CustomCalendarChange[1]);
            CalendarMgt[2].IsNonworkingDay(NewDate, CustomCalendarChange[2]);

            OnCalcDateBOCOnAfterSetNonworking(CustomCalendarChange);
            if CustomCalendarChange[1].Nonworking or CheckBothCalendars and CustomCalendarChange[2].Nonworking then
                NewDate := NewDate + LoopFactor
            else
                exit(NewDate);
        until LoopCounter >= CalConvTimeFrame;
        exit(NewDate);
    end;

    procedure CalcDateBOC2(OrgDateExpression: Text[30]; OrgDate: Date; CustomCalendarChange: array[2] of Record "Customized Calendar Change"; CheckBothCalendars: Boolean): Date
    var
        NewOrgDateExpression: Text[30];
    begin
        // Use this procedure to subtract time expression.
        NewOrgDateExpression := ReverseSign(OrgDateExpression);
        exit(CalcDateBOC(NewOrgDateExpression, OrgDate, CustomCalendarChange, CheckBothCalendars));
    end;

    local procedure ReverseSign(DateFormulaExpr: Text[30]): Text[30]
    var
        Formula: DateFormula;
        NewDateFormulaExpr: Text[30];
    begin
        Evaluate(Formula, DateFormulaExpr);
        NewDateFormulaExpr := ConvertStr(Format(Formula), '+-', '-+');
        if not (DateFormulaExpr[1] in ['+', '-']) then
            if NewDateFormulaExpr <> '<0D>' then
                NewDateFormulaExpr := '-' + NewDateFormulaExpr;
        exit(NewDateFormulaExpr);
    end;

    procedure CheckDateFormulaPositive(CurrentDateFormula: DateFormula)
    begin
        if CalcDate(CurrentDateFormula) < Today then
            Error(NegativeExprErr, CurrentDateFormula);
    end;

    procedure CalcTimeDelta(EndingTime: Time; StartingTime: Time) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTimeDelta(EndingTime, StartingTime, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := EndingTime - StartingTime;
        if (Result <> 0) and (EndingTime = 235959T) then
            Result += 1000;
    end;

    procedure CalcTimeSubtract(SubstractTime: Time; SubstractValue: Integer) Result: Time
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTimeSubtract(SubstractTime, SubstractValue, Result, IsHandled);
        if IsHandled then
            exit;

        Result := SubstractTime - SubstractValue;
        if (Result <> 000000T) and (SubstractTime = 235959T) and (SubstractValue <> 0) then
            Result += 1000;
    end;

    local procedure IsOnBeforeCalcDateBOCHandled(var CustomCalendarChange: array[2] of Record "Customized Calendar Change"; var CalConvTimeFrame: Integer) IsHandled: Boolean
    begin
        OnBeforeCalcDateBOC(CustomCalendarChange, CalConvTimeFrame, IsHandled)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDateBOC(var CustomCalendarChange: array[2] of Record "Customized Calendar Change"; var CalConvTimeFrame: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure DeleteCustomizedBaseCalendarData(SourceType: Enum "Calendar Source Type"; SourceCode: Code[20])
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        CustomizedCalendarChange.SetRange("Source Type", SourceType);
        CustomizedCalendarChange.SetRange("Source Code", SourceCode);
        OnDeleteCustomizedBaseCalendarDataOnAfterFilterCalendarChange(CustomizedCalendarChange);
        CustomizedCalendarChange.DeleteAll();

        CustomizedCalendarEntry.SetRange("Source Type", SourceType);
        CustomizedCalendarEntry.SetRange("Source Code", SourceCode);
        OnDeleteCustomizedBaseCalendarDataOnAfterFilterCalendarEntry(CustomizedCalendarEntry);
        CustomizedCalendarEntry.DeleteAll();

        WhereUsedBaseCalendar.SetRange("Source Type", SourceType);
        WhereUsedBaseCalendar.SetRange("Source Code", SourceCode);
        OnDeleteCustomizedBaseCalendarDataOnAfterFilterWhereUsedBaseCalendar(WhereUsedBaseCalendar);
        WhereUsedBaseCalendar.DeleteAll();
    end;

    procedure RenameCustomizedBaseCalendarData(SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; xSourceCode: Code[20])
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        TempCustomizedCalendarChange: Record "Customized Calendar Change" temporary;
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        TempCustomizedCalendarEntry: Record "Customized Calendar Entry" temporary;
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
        TempWhereUsedBaseCalendar: Record "Where Used Base Calendar" temporary;
    begin
        CustomizedCalendarChange.SetRange("Source Type", SourceType);
        CustomizedCalendarChange.SetRange("Source Code", xSourceCode);
        if CustomizedCalendarChange.FindSet() then
            repeat
                TempCustomizedCalendarChange := CustomizedCalendarChange;
                TempCustomizedCalendarChange.Insert();
            until CustomizedCalendarChange.Next() = 0;
        if TempCustomizedCalendarChange.FindSet() then
            repeat
                Clear(CustomizedCalendarChange);
                CustomizedCalendarChange := TempCustomizedCalendarChange;
                CustomizedCalendarChange.Rename(
                  CustomizedCalendarChange."Source Type",
                  SourceCode,
                  CustomizedCalendarChange."Additional Source Code",
                  CustomizedCalendarChange."Base Calendar Code",
                  CustomizedCalendarChange."Recurring System",
                  CustomizedCalendarChange.Date,
                  CustomizedCalendarChange.Day,
                  CustomizedCalendarChange."Entry No.");
            until TempCustomizedCalendarChange.Next() = 0;

        CustomizedCalendarEntry.SetRange("Source Type", SourceType);
        CustomizedCalendarEntry.SetRange("Source Code", xSourceCode);
        if CustomizedCalendarEntry.FindSet() then
            repeat
                TempCustomizedCalendarEntry := CustomizedCalendarEntry;
                TempCustomizedCalendarEntry.Insert();
            until CustomizedCalendarEntry.Next() = 0;
        if TempCustomizedCalendarEntry.FindSet() then
            repeat
                Clear(CustomizedCalendarEntry);
                CustomizedCalendarEntry := TempCustomizedCalendarEntry;
                CustomizedCalendarEntry.Rename(
                  CustomizedCalendarEntry."Source Type",
                  SourceCode,
                  CustomizedCalendarEntry."Additional Source Code",
                  CustomizedCalendarEntry."Base Calendar Code",
                  CustomizedCalendarEntry.Date);
            until TempCustomizedCalendarEntry.Next() = 0;

        WhereUsedBaseCalendar.SetRange("Source Type", SourceType);
        WhereUsedBaseCalendar.SetRange("Source Code", xSourceCode);
        if WhereUsedBaseCalendar.FindSet() then
            repeat
                TempWhereUsedBaseCalendar := WhereUsedBaseCalendar;
                TempWhereUsedBaseCalendar.Insert();
            until WhereUsedBaseCalendar.Next() = 0;
        if TempWhereUsedBaseCalendar.FindSet() then
            repeat
                Clear(WhereUsedBaseCalendar);
                WhereUsedBaseCalendar := TempWhereUsedBaseCalendar;
                WhereUsedBaseCalendar.Rename(
                  WhereUsedBaseCalendar."Base Calendar Code",
                  WhereUsedBaseCalendar."Source Type",
                  SourceCode,
                  WhereUsedBaseCalendar."Source Name");
            until TempWhereUsedBaseCalendar.Next() = 0;
    end;

    procedure ReverseDateFormula(var ReversedDateFormula: DateFormula; DateFormula: DateFormula)
    var
        DateFormulaAsText: Text;
        ReversedDateFormulaAsText: Text;
        SummandPositions: array[100] of Integer;
        i: Integer;
        j: Integer;
    begin
        Clear(ReversedDateFormula);
        DateFormulaAsText := Format(DateFormula);
        if DateFormulaAsText = '' then
            exit;

        if not (CopyStr(DateFormulaAsText, 1, 1) in ['+', '-']) then
            DateFormulaAsText := '+' + DateFormulaAsText;

        j := 0;
        for i := 1 to StrLen(DateFormulaAsText) do
            if DateFormulaAsText[i] in ['+', '-'] then begin
                SummandPositions[j + 1] := i;
                j += 1;
                if DateFormulaAsText[i] = '+' then
                    DateFormulaAsText[i] := '-'
                else
                    DateFormulaAsText[i] := '+';
            end;

        for i := j downto 1 do
            if i = j then
                ReversedDateFormulaAsText := CopyStr(DateFormulaAsText, SummandPositions[i])
            else
                ReversedDateFormulaAsText :=
                  ReversedDateFormulaAsText + CopyStr(DateFormulaAsText, SummandPositions[i], SummandPositions[i + 1] - SummandPositions[i]);

        Evaluate(ReversedDateFormula, ReversedDateFormulaAsText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDateStatus(var CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTimeSubtract(SubstractTime: Time; SubstractValue: Integer; var Result: Time; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDateStatus(var CustomizedCalendarChange: Record "Customized Calendar Change"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsNonworkingDay(var TargetDate: Date; var CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSourceShippingAgentServices(var ShippingAgentServices: Record "Shipping Agent Services")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDateBOCOnAfterCheckDates(var CustomCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDateBOCOnAfterGetCalendarCodes(var CustomCalendarChange: array[2] of Record "Customized Calendar Change"; var CalConvTimeFrame: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDateBOCOnAfterSetNonworking(var CustomCalendarChange: array[2] of Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDateStatusAfterDateCustomized(var TargetCustomizedCalendarChange: Record "Customized Calendar Change"; TempCustChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDateStatusOnAfterCombineChanges(var TargetCustomizedCalendarChange: Record "Customized Calendar Change"; var TempCustChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDateBOCOnBeforeCalcNewDate(var OrgDateExpression: Text[30]; var OrgDate: Date; var CustomCalendarChange: array[2] of Record "Customized Calendar Change"; CheckBothCalendars: Boolean; var NewDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteCustomizedBaseCalendarDataOnAfterFilterCalendarChange(var CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteCustomizedBaseCalendarDataOnAfterFilterCalendarEntry(var CustomizedCalendarEntry: Record "Customized Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteCustomizedBaseCalendarDataOnAfterFilterWhereUsedBaseCalendar(var WhereUsedBaseCalendar: Record "Where Used Base Calendar")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTimeDelta(EndingTime: Time; StartingTime: Time; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddCustomizedCalendarChanges(var CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSource(SourceVariant: Variant; var NewCustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddBaseCalendarChanges(NewCustomizedCalendarChange: Record "Customized Calendar Change"; var TempCustomizedCalendarChange: Record "Customized Calendar Change" temporary; var BaseCalendarChange: Record "Base Calendar Change")
    begin
    end;
}

