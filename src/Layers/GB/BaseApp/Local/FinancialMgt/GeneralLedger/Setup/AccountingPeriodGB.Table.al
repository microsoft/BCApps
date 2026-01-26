#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Setup;
using System.Utilities;

table 10560 "Accounting Period GB"
{
    Caption = 'Accounting Period GB';
    LookupPageID = "Accounting Periods";
    DataClassification = CustomerContent;
    ObsoleteReason = 'No longer required';
#if CLEAN28
    ObsoleteState = Removed;
    ObsoleteTag = '31.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
#endif

    fields
    {
        field(1; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(2; "Period Start"; Date)
        {
            Caption = 'Period Start';
            NotBlank = true;
        }
        field(3; "Period End"; Date)
        {
            Caption = 'Period End';
            ClosingDates = true;

            trigger OnValidate()
            begin
                "Period End" := ClosingDate("Period End");
            end;
        }
        field(4; "Period No."; Integer)
        {
            Caption = 'Period No.';
        }
        field(5; "Period Name"; Text[30])
        {
            Caption = 'Period Name';
        }
        field(5804; "Average Cost Calc. Type"; Enum "Average Cost Calculation Type")
        {
            Caption = 'Average Cost Calc. Type';
            Editable = false;
        }
        field(5805; "Average Cost Period"; Enum "Average Cost Period Type")
        {
            Caption = 'Average Cost Period';
            Editable = false;
        }
        field(10500; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(10501; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
        key(Key2; "Period Start", "Line No.")
        {
        }
        key(Key3; Closed)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Closed, false);
    end;

    trigger OnInsert()
    var
        InvtSetup: Record "Inventory Setup";
    begin
        CheckExist();
        if "Period Type" = "Period Type"::Year then begin
            InvtSetup.Get();
            "Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type";
            "Average Cost Period" := InvtSetup."Average Cost Period";
        end;
        AccountingPeriod2 := Rec;
        if AccountingPeriod2.Find('>') then
            AccountingPeriod2.TestField(Closed, false);
    end;

    trigger OnModify()
    begin
        TestField(Closed, false);
    end;

    trigger OnRename()
    begin
        TestField(Closed, false);
        CheckExist();
        AccountingPeriod2 := Rec;
        if AccountingPeriod2.Find('>') then
            AccountingPeriod2.TestField(Closed, false);
    end;

    var
        AccountingPeriod2: Record "Accounting Period GB";
        Calendar: Record Date;
        Text1041000: Label 'You cannot insert period between closed periods.';
        Text1041001: Label '%1 %2 with %3=%4 conflicts with existing %5 %2 %6..%7.';

    [Scope('OnPrem')]
    procedure UpdateName()
    begin
        if
           ("Period Type" <> Calendar."Period Type") or
           ("Period Start" <> Calendar."Period Start")
        then
            if Calendar.Get("Period Type", "Period Start") then
                if
                   ("Period Type" = Calendar."Period Type") and
                   ("Period Start" = Calendar."Period Start") and
                   (NormalDate("Period End") = NormalDate(Calendar."Period End"))
                then begin
                    "Period No." := Calendar."Period No.";
                    "Period Name" := Calendar."Period Name";
                end;
    end;

    [Scope('OnPrem')]
    procedure CheckExist()
    begin
        AccountingPeriod2 := Rec;
        AccountingPeriod2.SetRange("Period Type", "Period Type");
        if AccountingPeriod2.Find('>') then begin
            Closed := AccountingPeriod2.Closed;
            if
               ("Period Start" >= AccountingPeriod2."Period Start") and
               ("Period Start" <= AccountingPeriod2."Period End")
            then
                Error(Text1041001,
                  FieldCaption("Period Type"), Format("Period Type"),
                  FieldCaption("Period Start"), Format("Period Start"), TableCaption(),
                  Format(AccountingPeriod2."Period Start"), Format(AccountingPeriod2."Period End"));
        end;
        if AccountingPeriod2.Find('<') then begin
            if
               ("Period Start" >= AccountingPeriod2."Period Start") and
               ("Period Start" <= AccountingPeriod2."Period End")
            then
                Error(Text1041001,
                  FieldCaption("Period Type"), Format("Period Type"),
                  FieldCaption("Period Start"), Format("Period Start"), TableCaption(),
                  Format(AccountingPeriod2."Period Start"), Format(AccountingPeriod2."Period End"));
            if Closed and AccountingPeriod2.Closed then
                Error(Text1041000);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccountingPeriodDate(var StartDate: Date; var EndDate: Date; ReferenceDate: Date)
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("Period Start", 0D, ReferenceDate);
        if AccountingPeriod2.FindLast() then begin
            StartDate := AccountingPeriod2."Period Start";
            EndDate := AccountingPeriod2."Period End";
        end;
    end;
}
#endif

