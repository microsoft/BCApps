// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

table 99000751 "Shop Calendar"
{
    Caption = 'Shop Calendar';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Shop Calendars";
    LookupPageID = "Shop Calendars";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ShopCalendarWorkDays.SetRange("Shop Calendar Code", Code);
        ShopCalendarWorkDays.DeleteAll();

        ShopCalHoliday.SetRange("Shop Calendar Code", Code);
        ShopCalHoliday.DeleteAll();
    end;

    var
        ShopCalendarWorkDays: Record "Shop Calendar Working Days";
        ShopCalHoliday: Record "Shop Calendar Holiday";
}

