// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

#if not CLEAN28
using Microsoft.Finance.GeneralLedger.Setup;
#endif
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
#if not CLEAN28
using System.Security.User;
#endif

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
#if not CLEAN28
                if not "New Fiscal Year" then
                    CheckPostingRangeInAccPeriod("Starting Date");
#endif

                if "New Fiscal Year" then begin
                    CheckOpenFiscalYears();
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
        field(10800; "Fiscally Closed"; Boolean)
        {
            Caption = 'Fiscally Closed';
            Editable = false;
        }
        field(10801; "Fiscal Closing Date"; Date)
        {
            Caption = 'Fiscal Closing Date';
            Editable = false;
        }
        field(10802; "Period Reopened Date"; Date)
        {
            Caption = 'Period Reopened Date';
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
        key(Key4; "New Fiscal Year", "Fiscally Closed")
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
#if not CLEAN28
        CheckPostingRangeInAccPeriod("Starting Date");
#endif
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
#if not CLEAN28
        Text10800: Label 'To delete the fiscal year from %1 to %2, you must first modify the fields %3 and %4 in the %5 and %6 so that they are outside the fiscal year that is being deleted.';
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
#endif
        Text10801: Label 'It is not allowed to have more than two open fiscal years. Please fiscally close the oldest open fiscal year first.';
        Text10802: Label 'You will not be able to post transactions in a closed period. Are you sure you want to close the period with starting date %1?';
        Text10803: Label 'There are no open fiscal periods that can be closed.';
        Text10804: Label 'You cannot close the last period of a fiscal year. In order to close the last period of a fiscal year, you must fiscally close the fiscal year.';
        Text10805: Label 'The period you are trying to reopen belongs to a fiscal year that has been fiscally closed.\Once a fiscal year is fiscally closed, you cannot reopen any of the periods in that fiscal year.';
        Text10806: Label 'A closed fiscal period should normally not be reopened. Are you sure you want to reopen the fiscal period with starting date %1?';
        Text10807: Label 'There are no closed fiscal periods that can be reopened.';
        Text10809: Label 'You must create a new fiscal year before you can close this fiscal period.';
        EndingDate: Date;
        NoOfOpenFiscalYears: Integer;

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

    [Scope('OnPrem')]
    procedure CheckOpenFiscalYears()
    var
        IsHandled: Boolean;
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetRange("Fiscally Closed", false);
        NoOfOpenFiscalYears := AccountingPeriod2.Count();
        if AccountingPeriod2.FindFirst() then;

        // check last period of previous fiscal year
        AccountingPeriod2.SetRange("New Fiscal Year");
        AccountingPeriod2.SetRange("Fiscally Closed");
        if AccountingPeriod2.Find('<') then
            if not AccountingPeriod2."Fiscally Closed" then
                NoOfOpenFiscalYears := NoOfOpenFiscalYears + 1;

        IsHandled := false;
        OnCheckOpenFiscalYearsOnBeforeError(Rec, IsHandled);
        if not IsHandled then
            if NoOfOpenFiscalYears > 2 then
                Error(Text10801);
    end;

    [Scope('OnPrem')]
    procedure CloseFiscalPeriod()
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("Fiscally Closed", false);
        if AccountingPeriod2.FindFirst() then begin
            if not AccountingPeriod2.Find('>') then
                Error(Text10809);
            // check last period in fiscal year
            if AccountingPeriod2."New Fiscal Year" then
                Error(Text10804);
            EndingDate := CalcDate('<-1D>', AccountingPeriod2."Starting Date");
            AccountingPeriod2.Find('<');
            if Confirm(Text10802, true, AccountingPeriod2."Starting Date") then begin
                AccountingPeriod2."Fiscally Closed" := true;
                AccountingPeriod2."Fiscal Closing Date" := Today;
                AccountingPeriod2.Modify();
#if not CLEAN28
                // update allowed posting range
                UpdateGLSetup(EndingDate);
                UpdateUserSetup(EndingDate);
#endif
            end;
        end else
            Message(Text10803);
    end;

    [Scope('OnPrem')]
    procedure ReopenFiscalPeriod()
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("Fiscally Closed", false);
        if AccountingPeriod2.FindFirst() then
            if AccountingPeriod2."New Fiscal Year" then
                Error(Text10805);
        AccountingPeriod2.SetRange("Fiscally Closed", true);
        if AccountingPeriod2.FindLast() then begin
            if not Confirm(Text10806, false, AccountingPeriod2."Starting Date") then
                exit;
            AccountingPeriod2."Fiscally Closed" := false;
            AccountingPeriod2."Period Reopened Date" := Today;
            AccountingPeriod2.Modify();
        end else
            Message(Text10807);
    end;

#if not CLEAN28
    [Obsolete('The procedure will be removed in a future release.', '28.0')]
    [Scope('OnPrem')]
    procedure UpdateGLSetup(PeriodEndDate: Date)
    begin
        GLSetup.Get();
        GLSetup.CalcFields("Posting Allowed From");
        if GLSetup."Allow Posting From" <= PeriodEndDate then begin
            GLSetup."Allow Posting From" := GLSetup."Posting Allowed From";
            GLSetup.Modify();
        end;
        if (GLSetup."Allow Posting To" <= PeriodEndDate) and (GLSetup."Allow Posting To" <> 0D) then begin
            GLSetup."Allow Posting To" := CalcDate('<+1M-1D>', GLSetup."Posting Allowed From");
            GLSetup.Modify();
        end;
    end;

    [Obsolete('The procedure will be removed in a future release.', '28.0')]
    [Scope('OnPrem')]
    procedure UpdateUserSetup(PeriodEndDate: Date)
    begin
        if UserSetup.FindFirst() then
            repeat
                if UserSetup."Allow Posting From" <= PeriodEndDate then begin
                    UserSetup."Allow Posting From" := GLSetup."Posting Allowed From";
                    UserSetup.Modify();
                end;
                if (UserSetup."Allow Posting To" <= PeriodEndDate) and (UserSetup."Allow Posting To" <> 0D) then begin
                    UserSetup."Allow Posting To" := CalcDate('<+1M-1D>', GLSetup."Posting Allowed From");
                    UserSetup.Modify();
                end;
            until UserSetup.Next() = 0;
    end;

    [Obsolete('The procedure will be removed in a future release.', '28.0')]
    [Scope('OnPrem')]
    procedure CheckPostingRangeSetup(FYEndDate: Date): Boolean
    begin
        GLSetup.Get();
        if (GLSetup."Allow Posting From" > FYEndDate) or (GLSetup."Allow Posting To" > FYEndDate) then
            exit(true);

        if UserSetup.FindFirst() then
            repeat
                if (UserSetup."Allow Posting From" > FYEndDate) or (UserSetup."Allow Posting To" > FYEndDate) then
                    exit(true);
            until UserSetup.Next() = 0;

        exit(false);
    end;

    [Obsolete('The procedure will be removed in a future release.', '28.0')]
    local procedure CheckPostingRangeInAccPeriod(ExcludePeriod: Date)
    var
        OldPostingAllowedTo: Date;
        NewPostingAllowedTo: Date;
    begin
        GLSetup.CalcFields("Posting Allowed To");
        if GLSetup."Posting Allowed To" <> 0D then
            OldPostingAllowedTo := CalcDate('<-1D>', GLSetup."Posting Allowed To");

        NewPostingAllowedTo := GetPostingAllowedToDate(ExcludePeriod);
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetFilter("Starting Date", '<>%1', ExcludePeriod);
        if AccountingPeriod2.FindLast() then
            if NewPostingAllowedTo <> 0D then
                if CheckPostingRangeSetup(CalcDate('<-1D>', NewPostingAllowedTo)) then
                    Error(
                      Text10800,
                      AccountingPeriod2."Starting Date", OldPostingAllowedTo,
                      GLSetup.FieldCaption("Allow Posting From"), GLSetup.FieldCaption("Allow Posting To"),
                      GLSetup.TableCaption(), UserSetup.TableCaption());
    end;

    [Obsolete('The procedure will be removed in a future release.', '28.0')]
    local procedure GetPostingAllowedToDate(ExcludePeriod: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Fiscally Closed", false);
        AccountingPeriod.SetFilter("Starting Date", '<>%1', ExcludePeriod);
        if AccountingPeriod.FindLast() then
            exit(AccountingPeriod."Starting Date");

        exit(0D);
    end;
#endif

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
    local procedure OnCheckOpenFiscalYearsOnBeforeError(var AccountingPeriod: Record "Accounting Period"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeRecurringTexts(PostingDate: Date; var DocumentNo: Code[20]; var Description: Text[100]; var IsHandled: Boolean)
    begin
    end;
}

