// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Setup;

table 99000752 "Shop Calendar Working Days"
{
    Caption = 'Shop Calendar Working Days';
    DataCaptionFields = "Shop Calendar Code";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Calendar Code"; Code[10])
        {
            Caption = 'Shop Calendar Code';
            NotBlank = true;
            TableRelation = "Shop Calendar";
        }
        field(2; Day; Option)
        {
            Caption = 'Day';
            OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
        }
        field(3; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            NotBlank = true;
            TableRelation = "Work Shift";
        }
        field(4; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                if ("Ending Time" = 0T) or
                   ("Ending Time" < "Starting Time")
                then begin
                    ShopCalendar.SetRange("Shop Calendar Code", "Shop Calendar Code");
                    ShopCalendar.SetRange(Day, Day);
                    ShopCalendar.SetRange("Starting Time", "Starting Time", 235959T);
                    if ShopCalendar.FindFirst() then
                        "Ending Time" := ShopCalendar."Starting Time"
                    else
                        "Ending Time" := 235959T;
                end;
                CheckRedundancy();
            end;
        }
        field(5; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                if ("Ending Time" < "Starting Time") and
                   ("Ending Time" <> 000000T)
                then
                    Error(Text000, FieldCaption("Ending Time"), FieldCaption("Starting Time"));

                CheckRedundancy();
            end;
        }
    }

    keys
    {
        key(Key1; "Shop Calendar Code", Day, "Starting Time", "Ending Time", "Work Shift Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckRedundancy();
    end;

    trigger OnRename()
    begin
        CheckRedundancy();
    end;

    var
        ShopCalendar: Record "Shop Calendar Working Days";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be higher than %2.';
        Text001: Label 'There is redundancy in the Shop Calendar. Actual work shift %1 from : %2 to %3. Conflicting work shift %4 from : %5 to %6.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckRedundancy()
    var
        ShopCalendar2: Record "Shop Calendar Working Days";
        TempShopCalendar: Record "Shop Calendar Working Days" temporary;
    begin
        ShopCalendar2.SetRange("Shop Calendar Code", "Shop Calendar Code");
        ShopCalendar2.SetRange(Day, Day);
        if ShopCalendar2.Find('-') then
            repeat
                TempShopCalendar := ShopCalendar2;
                TempShopCalendar.Insert();
            until ShopCalendar2.Next() = 0;

        TempShopCalendar := xRec;
        if TempShopCalendar.Delete() then;

        TempShopCalendar.SetRange("Shop Calendar Code", "Shop Calendar Code");
        TempShopCalendar.SetRange(Day, Day);
        TempShopCalendar.SetRange("Starting Time", 0T, "Ending Time" - 1);
        TempShopCalendar.SetRange("Ending Time", "Starting Time" + 1, 235959T);
        OnCheckRedundancyOnAfterTempShopCalendarSetFilters(Rec, TempShopCalendar);

        if TempShopCalendar.FindFirst() then begin
            if (TempShopCalendar."Starting Time" = "Starting Time") and
               (TempShopCalendar."Ending Time" = "Ending Time") and
               (TempShopCalendar."Work Shift Code" = "Work Shift Code")
            then
                exit;

            Error(
              Text001,
              "Work Shift Code",
              "Starting Time",
              "Ending Time",
              TempShopCalendar."Work Shift Code",
              TempShopCalendar."Starting Time",
              TempShopCalendar."Ending Time");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRedundancyOnAfterTempShopCalendarSetFilters(ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; var TempShopCalendarWorkingDays: Record "Shop Calendar Working Days" temporary)
    begin
    end;
}

