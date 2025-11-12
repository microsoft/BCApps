// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;

table 50 "Accounting Period"
{
    Caption = 'Accounting Period';
    LookupPageID = "Accounting Periods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := Format("Starting Date", 0, Text000);
            end;
        }
        field(2; Name; Text[10])
        {
            Caption = 'Name';
        }
        field(3; "New Fiscal Year"; Boolean)
        {
            Caption = 'New Fiscal Year';

            trigger OnValidate()
            begin
                TestField("Date Locked", false);
                if "New Fiscal Year" then begin
                    if not InvtSetup.Get() then
                        exit;
                    "Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type";
                    "Average Cost Period" := InvtSetup."Average Cost Period";
                end else begin
                    "Average Cost Calc. Type" := "Average Cost Calc. Type"::" ";
                    "Average Cost Period" := "Average Cost Period"::" ";
                end;
            end;
        }
        field(4; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(5; "Date Locked"; Boolean)
        {
            Caption = 'Date Locked';
            Editable = false;
        }
        field(5804; "Average Cost Calc. Type"; Enum "Average Cost Calculation Type")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Average Cost Calc. Type';
            Editable = false;
        }
        field(5805; "Average Cost Period"; Enum "Average Cost Period Type")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Average Cost Period';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "New Fiscal Year", "Date Locked")
        {
        }
        key(Key3; Closed)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Starting Date", Name, "New Fiscal Year", Closed)
        {
        }
    }

    trigger OnDelete()
    begin
        TestField("Date Locked", false);
    end;

    trigger OnInsert()
    begin
        AccountingPeriod2 := Rec;
        if AccountingPeriod2.Find('>') then
            AccountingPeriod2.TestField("Date Locked", false);
    end;

    trigger OnRename()
    begin
        TestField("Date Locked", false);
        AccountingPeriod2 := Rec;
        if AccountingPeriod2.Find('>') then
            AccountingPeriod2.TestField("Date Locked", false);
    end;

    var
        AccountingPeriod2: Record "Accounting Period";
        InvtSetup: Record "Inventory Setup";

#pragma warning disable AA0074
        Text000: Label '<Month Text,10>', Locked = true;
#pragma warning restore AA0074
        MonthTxt: Label '<Month Text>', Locked = true;

    procedure UpdateAvgItems()
    var
        ChangeAvgCostSetting: Codeunit "Change Average Cost Setting";
    begin
        ChangeAvgCostSetting.UpdateAvgCostFromAccPeriodChg(Rec);
    end;

    procedure GetFiscalYearEndDate(ReferenceDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        exit(GetFiscalYearEndDate(AccountingPeriod, ReferenceDate))
    end;

    procedure GetFiscalYearEndDate(var AccountingPeriod: Record "Accounting Period"; ReferenceDate: Date): Date
    begin
        AccountingPeriod.Reset();
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<CY>', ReferenceDate));

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Starting Date", 0D, ReferenceDate);
        if AccountingPeriod.FindLast() then
            AccountingPeriod.SetRange("Starting Date");
        if AccountingPeriod.Find('>') then
            exit(AccountingPeriod."Starting Date" - 1);
    end;

    procedure GetFiscalYearStartDate(ReferenceDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        exit(GetFiscalYearStartDate(AccountingPeriod, ReferenceDate))
    end;

    procedure GetFiscalYearStartDate(var AccountingPeriod: Record "Accounting Period"; ReferenceDate: Date): Date
    begin
        AccountingPeriod.Reset();
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<-CY>', ReferenceDate));

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Starting Date", 0D, ReferenceDate);
        if AccountingPeriod.FindLast() then
            exit(AccountingPeriod."Starting Date")
    end;

    procedure CorrespondingAccountingPeriodExists(var AccountingPeriod: Record "Accounting Period"; AccSchedDate: Date): Boolean
    begin
        AccountingPeriod.SetFilter("Starting Date", '%1', CalcDate('<-CM>', AccSchedDate));
        if AccountingPeriod.FindFirst() then
            exit(true);
        exit(false);
    end;

    procedure MakeRecurringTexts(PostingDate: Date; var DocumentNo: Code[20]; var Description: Text[100])
    var
        AccountingPeriod: Record "Accounting Period";
        Day: Integer;
        Week: Integer;
        Month: Integer;
        Year: Integer;
        MonthText: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeRecurringTexts(PostingDate, DocumentNo, Description, IsHandled);
        if IsHandled then
            exit;

        Day := Date2DMY(PostingDate, 1);
        Week := Date2DWY(PostingDate, 2);
        Month := Date2DMY(PostingDate, 2);
        MonthText := Format(PostingDate, 0, MonthTxt);
        Year := Date2DMY(PostingDate, 3);
        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
        if not AccountingPeriod.FindLast() then
            AccountingPeriod.Name := '';
        DocumentNo :=
            CopyStr(
                DelChr(
                    PadStr(
                        StrSubstNo(DocumentNo, Day, Week, Month, MonthText, AccountingPeriod.Name, Year), MaxStrLen(DocumentNo)), '>'),
                    1, MaxStrLen(DocumentNo));
        Description :=
            CopyStr(
                DelChr(
                    PadStr(
                        StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name, Year), MaxStrLen(Description)), '>'),
                    1, MaxStrLen(Description));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeRecurringTexts(PostingDate: Date; var DocumentNo: Code[20]; var Description: Text[100]; var IsHandled: Boolean)
    begin
    end;
}

