// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;

table 6939 "Mileage Rate Setup"
{
    Access = Internal;
    Caption = 'Mileage Rate Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "Mileage Rate Setup";
    LookupPageId = "Mileage Rate Setup";
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Specifies the unique code that identifies the mileage rate.';
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
            ToolTip = 'Specifies the currency the mileage rate is expressed in. Leave blank to use the local currency.';

            trigger OnValidate()
            begin
                CheckOverlappingRate();
            end;
        }
        field(3; "Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rate';
            DataClassification = CustomerContent;
            MinValue = 0;
            ToolTip = 'Specifies the reimbursement amount per unit of distance for this mileage rate.';
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Specifies the first date the mileage rate is effective.';

            trigger OnValidate()
            begin
                TestField("Starting Date");
                CheckDates();
                CheckOverlappingRate();
            end;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last date the mileage rate is effective. Leave blank for an open-ended rate.';

            trigger OnValidate()
            begin
                CheckDates();
                CheckOverlappingRate();
            end;
        }
        field(6; "Vehicle Type"; Code[20])
        {
            Caption = 'Vehicle Type';
            DataClassification = CustomerContent;
            TableRelation = "Expense Vehicle Type";
            ToolTip = 'Specifies the vehicle type this mileage rate applies to. Leave blank to define a generic rate that is used when no rate matches the vehicle type on the expense.';

            trigger OnValidate()
            begin
                CheckOverlappingRate();
            end;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Effective; "Vehicle Type", "Currency Code", "Starting Date")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Starting Date");
        CheckOverlappingRate();
    end;

    trigger OnModify()
    begin
        TestField("Starting Date");
        CheckOverlappingRate();
    end;

    var
        EndingDateBeforeStartingDateErr: Label 'Ending Date %1 cannot be before Starting Date %2.', Comment = '%1 = Ending Date, %2 = Starting Date';
        OverlappingRateErr: Label 'The date range overlaps with mileage rate %1, which is effective from %2 to %3.', Comment = '%1 = Conflicting rate code, %2 = Conflicting Starting Date, %3 = Conflicting Ending Date (or open-ended text)';
        OpenEndedTxt: Label 'open-ended';

    local procedure CheckDates()
    begin
        if ("Ending Date" <> 0D) and ("Starting Date" <> 0D) and ("Ending Date" < "Starting Date") then
            Error(EndingDateBeforeStartingDateErr, "Ending Date", "Starting Date");
    end;

    local procedure CheckOverlappingRate()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
    begin
        if "Starting Date" = 0D then
            exit;

        MileageRateSetup.SetFilter("Code", '<>%1', "Code");
        MileageRateSetup.SetRange("Vehicle Type", "Vehicle Type");
        MileageRateSetup.SetRange("Currency Code", "Currency Code");
        if MileageRateSetup.FindSet() then
            repeat
                if DateRangesOverlap("Starting Date", "Ending Date", MileageRateSetup."Starting Date", MileageRateSetup."Ending Date") then
                    Error(OverlappingRateErr, MileageRateSetup."Code", MileageRateSetup."Starting Date", FormatEndingDate(MileageRateSetup."Ending Date"));
            until MileageRateSetup.Next() = 0;
    end;

    local procedure DateRangesOverlap(Start1: Date; End1: Date; Start2: Date; End2: Date): Boolean
    begin
        exit((Start1 <= EffectiveEndingDate(End2)) and (Start2 <= EffectiveEndingDate(End1)));
    end;

    local procedure EffectiveEndingDate(EndingDate: Date): Date
    begin
        if EndingDate = 0D then
            exit(DMY2Date(31, 12, 9999));
        exit(EndingDate);
    end;

    local procedure FormatEndingDate(EndingDate: Date): Text
    begin
        if EndingDate = 0D then
            exit(OpenEndedTxt);
        exit(Format(EndingDate));
    end;

    procedure FindEffectiveRate(TransactionDate: Date; CurrencyCode: Code[10]; VehicleType: Code[20]): Boolean
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Vehicle Type", "Currency Code", "Starting Date");
        Rec.SetRange("Vehicle Type", VehicleType);
        Rec.SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
        Rec.SetFilter("Starting Date", '<=%1', TransactionDate);
        Rec.SetFilter("Ending Date", '%1|>=%2', 0D, TransactionDate);
        exit(Rec.FindLast());
    end;
}
