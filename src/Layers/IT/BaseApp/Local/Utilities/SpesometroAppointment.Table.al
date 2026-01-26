// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;

table 12126 "Spesometro Appointment"
{
    Caption = 'Spesometro Appointment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Appointment Code"; Code[2])
        {
            Caption = 'Appointment Code';
            NotBlank = true;
            TableRelation = "Appointment Code".Code;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor."No.";
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(5; Designation; Text[60])
        {
            Caption = 'Designation';
        }
    }

    keys
    {
        key(Key1; "Appointment Code", "Vendor No.", "Starting Date", "Ending Date")
        {
            Clustered = true;
        }
        key(Key2; "Starting Date", "Ending Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Appointment Code");
        TestField("Vendor No.");
        TestField("Starting Date");
    end;

    var
        DateErr: Label '%1 cannot be after %2.';
        RecordNotLoadedErr: Label 'There is no Spesometro Appointment code within the specified filter.';
        IndividualValueMissingErr: Label 'Specify the %1 for Vendor %2 that is used in the Spesometro Appointment.', Comment = 'Specify the Fiscal Code for Vendor 10000 that is used in the Spesometro Appointment.';
        ValueMissingErr: Label 'Specify %1 in the Spesometro Appointment.';
        AndMsg: Label '%1 and %2', Comment = 'Fiscal Code and VAT Registration No.';
        CommaMsg: Label '%1, %2', Comment = 'Fiscal Code, VAT Registration No.';
        OrMsg: Label '%1 or %2', Comment = 'Fiscal Code or VAT Registration No.';

    local procedure CheckDate()
    begin
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(DateErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;

    [Scope('OnPrem')]
    procedure FormatDate(InputDate: Date): Text
    begin
        exit(Format(InputDate, 0, '<Day,2><Month,2><Year4>'));
    end;

    [Scope('OnPrem')]
    procedure FindAppointmentByDate(FromDate: Date; ToDate: Date): Boolean
    begin
        SetCurrentKey("Starting Date", "Ending Date");
        SetFilter("Starting Date", '<=%1', ToDate);
        SetFilter("Ending Date", '>=%1|%2', FromDate, 0D);
        exit(FindFirst());
    end;

    [Scope('OnPrem')]
    procedure GetValueOf(FieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code"): Text
    var
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
    begin
        if "Appointment Code" = '' then
            Error(RecordNotLoadedErr);

        Vendor.Get("Vendor No.");
        case FieldName of
            FieldName::"First Name":
                exit(Vendor."First Name");
            FieldName::"Last Name":
                exit(Vendor."Last Name");
            FieldName::Gender:
                begin
                    if Vendor.Gender = Vendor.Gender::Male then
                        exit('M');
                    exit('F');
                end;
            FieldName::"Date of Birth":
                exit(FormatDate(Vendor."Date of Birth"));
            FieldName::Municipality:
                begin
                    if Vendor.Resident = Vendor.Resident::Resident then
                        exit(Vendor."Birth City");
                    if CountryRegion.Get(Vendor."Birth Country/Region Code") then
                        exit(CountryRegion."Foreign Country/Region Code");
                end;
            FieldName::Province:
                begin
                    if Vendor.Resident = Vendor.Resident::Resident then
                        exit(Vendor."Birth County");
                    exit('EE');
                end;
            FieldName::"Fiscal Code":
                begin
                    if Vendor."Fiscal Code" <> '' then
                        exit(Vendor."Fiscal Code");
                    exit(Vendor."VAT Registration No.");
                end;
        end;
        exit('');
    end;

    [Scope('OnPrem')]
    procedure IsIndividual(): Boolean
    var
        Vendor: Record Vendor;
    begin
        if "Appointment Code" = '' then
            Error(RecordNotLoadedErr);

        Vendor.Get("Vendor No.");
        exit(Vendor."Individual Person");
    end;

    [Scope('OnPrem')]
    procedure ValidateAppointment()
    var
        Vendor: Record Vendor;
        FieldNamesIndividual: Text;
        FieldNames: Text;
    begin
        if "Appointment Code" = '' then
            Error(RecordNotLoadedErr);

        Vendor.Get("Vendor No.");

        if (Vendor."Fiscal Code" = '') and (Vendor."VAT Registration No." = '') then
            AddToErrorString(
              FieldNamesIndividual, StrSubstNo(OrMsg, Vendor.FieldCaption("Fiscal Code"), Vendor.FieldCaption("VAT Registration No.")));
        if "Appointment Code" = '' then
            AddToErrorString(FieldNames, FieldCaption("Appointment Code"));
        if "Starting Date" = 0D then
            AddToErrorString(FieldNames, FieldCaption("Starting Date"));

        if IsIndividual() then begin
            if Vendor."First Name" = '' then
                AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption("First Name"));
            if Vendor."Last Name" = '' then
                AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption("Last Name"));
            if Vendor.Gender = Vendor.Gender::" " then
                AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption(Gender));
            if Vendor."Date of Birth" = 0D then
                AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption("Date of Birth"));

            if Vendor.Resident = Vendor.Resident::Resident then begin
                if Vendor."Birth City" = '' then
                    AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption("Birth City"));
                if Vendor."Birth County" = '' then
                    AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption("Birth County"));
            end;

            if Vendor.Resident = Vendor.Resident::"Non-Resident" then
                if Vendor."Birth Country/Region Code" = '' then
                    AddToErrorString(FieldNamesIndividual, Vendor.FieldCaption("Birth Country/Region Code"));
        end else
            if Designation = '' then
                AddToErrorString(FieldNames, FieldCaption(Designation));

        if FieldNames <> '' then
            Error(ValueMissingErr, FieldNames);
        if FieldNamesIndividual <> '' then
            Error(IndividualValueMissingErr, FieldNamesIndividual, "Vendor No.");
    end;

    local procedure AddToErrorString(var FieldNames: Text; FieldName: Text)
    begin
        if FieldNames <> '' then
            if StrPos(FieldNames, StrSubstNo(AndMsg, '', '')) = 0 then
                FieldNames := StrSubstNo(AndMsg, FieldName, FieldNames)
            else
                FieldNames := StrSubstNo(CommaMsg, FieldName, FieldNames)
        else
            FieldNames := FieldName;
    end;
}

