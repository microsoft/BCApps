// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Foundation.Period;

table 5814 "Inventory Period"
{
    Caption = 'Inventory Period';
    LookupPageID = "Inventory Periods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := Format("Ending Date", 0, Text000);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Ending Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Ending Date", Name, Closed)
        {
        }
        fieldgroup(Brick; "Ending Date", Name, Closed)
        {
        }
    }

    trigger OnDelete()
    begin
        TestField(Closed, false);
        InvtPeriodEntry.SetRange("Ending Date", "Ending Date");
        InvtPeriodEntry.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if not IsValidDate("Ending Date") then
            Error(Text002, TableCaption(), "Ending Date");
    end;

    trigger OnRename()
    begin
        TestField(Closed, false);
        if InvtPeriodEntryExists(xRec."Ending Date") then
            Error(Text001, TableCaption(), InvtPeriodEntry.TableCaption());

        if not IsValidDate("Ending Date") then
            Error(Text001, TableCaption(), "Ending Date");
    end;

    var
        InvtPeriodEntry: Record "Inventory Period Entry";

#pragma warning disable AA0074
        Text000: Label '<Month Text> <Year4>', Locked = true;
#pragma warning disable AA0470
        Text001: Label 'You cannot rename the %1 because there is at least one %2 in this period.';
        Text002: Label 'You are not allowed to insert an %1 that ends before %2.';
        Text003: Label 'You cannot post before %1 because the %2 is already closed. You must re-open the period first.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure InvtPeriodEntryExists(EndingDate: Date): Boolean
    var
        InvtPeriodEntry: Record "Inventory Period Entry";
    begin
        InvtPeriodEntry.SetRange("Ending Date", EndingDate);
        exit(not InvtPeriodEntry.IsEmpty);
    end;

    procedure IsValidDate(var EndingDate: Date): Boolean
    var
        InvtPeriod: Record "Inventory Period";
    begin
        OnBeforeIsValidDate(EndingDate);
        InvtPeriod.SetFilter("Ending Date", '>=%1', EndingDate);
        InvtPeriod.SetRange(Closed, true);
        if InvtPeriod.FindLast() then
            EndingDate := InvtPeriod."Ending Date"
        else
            exit(true);
    end;

    procedure ShowError(PostingDate: Date)
    begin
        Error(Text003, CalcDate('<+1D>', PostingDate), TableCaption);
    end;

    procedure IsInvtPeriodClosed(EndingDate: Date): Boolean
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetFilter("Starting Date", '>=%1', EndingDate);
        if not AccPeriod.Find('-') then
            exit(false);
        if AccPeriod.Next() <> 0 then
            EndingDate := CalcDate('<-1D>', AccPeriod."Starting Date");

        SetFilter("Ending Date", '>=%1', EndingDate);
        SetRange(Closed, true);
        exit(not IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsValidDate(EndingDate: Date)
    begin
    end;
}

