// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Projects.Resources.Ledger;

table 205 "Resource Unit of Measure"
{
    Caption = 'Resource Unit of Measure';
    LookupPageID = "Resource Units of Measure";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            NotBlank = true;
            TableRelation = Resource;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Unit of Measure";
        }
        field(3; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if "Qty. per Unit of Measure" <= 0 then
                    FieldError("Qty. per Unit of Measure", Text000);
                Resource.Get("Resource No.");
                if Resource."Base Unit of Measure" = Code then
                    TestField("Qty. per Unit of Measure", 1);
            end;
        }
        field(4; "Related to Base Unit of Meas."; Boolean)
        {
            Caption = 'Related to Base Unit of Meas.';
            InitValue = true;

            trigger OnValidate()
            begin
                if not "Related to Base Unit of Meas." then
                    "Qty. per Unit of Measure" := 1;
            end;
        }
        field(721; "Coupled to Dataverse"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            FieldClass = FlowField;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Resource Unit of Measure")));
        }
    }

    keys
    {
        key(Key1; "Resource No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestResSetup();
        VerifyDelete();
    end;

    trigger OnRename()
    begin
        TestResSetup();
        VerifyRename();
    end;

    var
        Res: Record Resource;

#pragma warning disable AA0074
        Text000: Label 'must be greater than 0', Comment = 'starts with "Qty. per Unit of Measure"';
        Text001: Label 'You cannot change the value %2 of the %1 field for resource %3 because it is the resource''''s %4, and there are one or more open ledger entries for the resource.', Comment = '%1 = Resource Unit of Measure, %2 = Resource Unit of Measure Code, %3 = Resource No., %4 = Base Unit of Measure';
        Text002: Label 'You cannot delete the value %2 of the %1 field for resource %3 because it is the resource''''s %4.', Comment = '%1 = Resource Unit of Measure, %2 = Resource Unit of Measure Code, %3 = Resource No., %4 = Base Unit of Measure';
#pragma warning restore AA0074
        CannotModifyBaseUnitOfMeasureErr: Label 'You cannot modify %1 %2 for resource %3 because it is the resource''s %4.', Comment = '%1 Table name (Item Unit of measure), %2 Value of Measure (KG, PCS...), %3 Item ID, %4 Base unit of Measure';

    local procedure VerifyDelete()
    var
        Resource: Record Resource;
    begin
        if Resource.Get("Resource No.") then
            if Resource."Base Unit of Measure" = Code then
                Error(Text002, TableCaption(), Code, "Resource No.", Resource.FieldCaption("Base Unit of Measure"));
    end;

    local procedure VerifyRename()
    var
        Resource: Record Resource;
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        if Resource.Get("Resource No.") then
            if Resource."Base Unit of Measure" = xRec.Code then begin
                ResLedgerEntry.SetCurrentKey("Resource No.");
                ResLedgerEntry.SetRange("Resource No.", "Resource No.");
                if not ResLedgerEntry.IsEmpty() then
                    Error(Text001, TableCaption(), xRec.Code, "Resource No.", Resource.FieldCaption("Base Unit of Measure"));
            end;
    end;

    local procedure TestResSetup()
    begin
        if Res.Get("Resource No.") then
            if Res."Base Unit of Measure" = xRec.Code then
                Error(CannotModifyBaseUnitOfMeasureErr, TableCaption(), xRec.Code, "Resource No.", Res.FieldCaption("Base Unit of Measure"));
    end;
}

