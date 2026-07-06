// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

using System.Utilities;

table 7601 "Base Calendar Change"
{
    Caption = 'Base Calendar Change';
    DataCaptionFields = "Base Calendar Code";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            Editable = false;
            TableRelation = "Base Calendar";
        }
        field(2; "Recurring System"; Option)
        {
            Caption = 'Recurring System';
            OptionCaption = ' ,Annual Recurring,Weekly Recurring';
            OptionMembers = " ","Annual Recurring","Weekly Recurring";

            trigger OnValidate()
            begin
                if "Recurring System" <> xRec."Recurring System" then
                    case "Recurring System" of
                        "Recurring System"::"Annual Recurring":
                            Day := Day::" ";
                        "Recurring System"::"Weekly Recurring":
                            Date := 0D;
                    end;
            end;
        }
        field(3; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                if ("Recurring System" = "Recurring System"::" ") or
                   ("Recurring System" = "Recurring System"::"Annual Recurring")
                then
                    TestField(Date)
                else
                    TestField(Date, 0D);
                UpdateDayName();
            end;
        }
        field(4; Day; Option)
        {
            Caption = 'Day';
            OptionCaption = ' ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = " ",Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;

            trigger OnValidate()
            begin
                if "Recurring System" = "Recurring System"::"Weekly Recurring" then
                    TestField(Day);
                UpdateDayName();
            end;
        }
        field(5; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(6; Nonworking; Boolean)
        {
            Caption = 'Nonworking';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Base Calendar Code", "Recurring System", Date, Day)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckEntryLine();
    end;

    trigger OnModify()
    begin
        CheckEntryLine();
    end;

    trigger OnRename()
    begin
        CheckEntryLine();
    end;

    local procedure UpdateDayName()
    var
        DateTable: Record Date;
    begin
        if (Date > 0D) and
           ("Recurring System" = "Recurring System"::"Annual Recurring")
        then
            Day := Day::" "
        else begin
            DateTable.SetRange("Period Type", DateTable."Period Type"::Date);
            DateTable.SetRange("Period Start", Date);
            if DateTable.FindFirst() then
                Day := DateTable."Period No.";
        end;
        if (Date = 0D) and (Day = Day::" ") then begin
            Day := xRec.Day;
            Date := xRec.Date;
        end;
        if "Recurring System" = "Recurring System"::"Annual Recurring" then
            TestField(Day, Day::" ");
    end;

    local procedure CheckEntryLine()
    begin
        case "Recurring System" of
            "Recurring System"::" ":
                begin
                    TestField(Date);
                    TestField(Day);
                end;
            "Recurring System"::"Annual Recurring":
                begin
                    TestField(Date);
                    TestField(Day, Day::" ");
                end;
            "Recurring System"::"Weekly Recurring":
                begin
                    TestField(Date, 0D);
                    TestField(Day);
                end;
        end;
        OnAfterCheckEntryLine(Rec, xRec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEntryLine(var BaseCalendarChange: Record "Base Calendar Change"; xBaseCalendarChange: Record "Base Calendar Change")
    begin
    end;
}

