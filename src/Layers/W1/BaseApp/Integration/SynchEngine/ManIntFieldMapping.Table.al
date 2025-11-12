// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;
using System.IO;
using Microsoft.Integration.Dataverse;

table 5384 "Man. Int. Field Mapping"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(5; Name; Code[20])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(10; "Table Field No."; Integer)
        {
            Caption = 'Table Field';
            DataClassification = SystemMetadata;
        }
        field(20; "Table Field Caption"; Text[80])
        {
            Caption = 'Table Field Caption';
            DataClassification = SystemMetadata;
        }
        field(30; "Integration Table Field No."; Integer)
        {
            Caption = 'Integration Table Field';
            DataClassification = SystemMetadata;
        }
        field(40; "Int. Table Field Caption"; Text[80])
        {
            Caption = 'Integration Table Field Caption';
            DataClassification = SystemMetadata;
        }
        field(41; "Integration Table Field Name"; Text[80])
        {
            Caption = 'Integration Field Name';
            DataClassification = SystemMetadata;
        }
        field(50; "Direction"; Option)
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(60; "Const Value"; Text[50])
        {
            Caption = 'Const Value';
            DataClassification = SystemMetadata;
        }
        field(70; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
            DataClassification = SystemMetadata;
        }
        field(80; "Validate Integr. Table Field"; Boolean)
        {
            Caption = 'Validate Integration Table Field';
            DataClassification = SystemMetadata;
        }
        field(90; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule';
            DataClassification = SystemMetadata;
            TableRelation = "Transformation Rule";
        }
    }

    keys
    {
        key(Key1; "Name", "Table Field No.", "Integration Table Field No.")
        {
            Clustered = true;
        }
    }

    var
        FieldTypeNotTheSameErr: Label 'The field %1 with type %2 must have the same type as field %3 (%4).', Comment = '%1 - field name, %2 - field type, %3 - field name, %4 - field type';

    internal procedure GetAllValidFields(var Field: Record "Field"; IntegrationTable: Boolean; IntegrationMappingName: Code[20]; TableNo: Integer)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TextBuilder: TextBuilder;
    begin
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetFilter(Type, '%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12',
                            Field.Type::BigInteger,
                            Field.Type::Boolean,
                            Field.Type::Code,
                            Field.Type::Date,
                            Field.Type::DateFormula,
                            Field.Type::DateTime,
                            Field.Type::Decimal,
                            Field.Type::Duration,
                            Field.Type::GUID,
                            Field.Type::Integer,
                            Field.Type::Option,
                            Field.Type::Text);

        //Filder fields that are in field mapping table
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationMappingName);
        if IntegrationFieldMapping.FindSet() then
            repeat
                if TextBuilder.Length = 0 then begin
                    if IntegrationTable then
                        TextBuilder.Append('<>' + Format(IntegrationFieldMapping."Integration Table Field No."))
                    else
                        TextBuilder.Append('<>' + Format(IntegrationFieldMapping."Field No."));
                end else
                    if IntegrationTable then
                        TextBuilder.Append('&<>' + Format(IntegrationFieldMapping."Integration Table Field No."))
                    else
                        TextBuilder.Append('&<>' + Format(IntegrationFieldMapping."Field No."));
            until IntegrationFieldMapping.Next() = 0;

        //Filter fields that are already selected
        if xRec.FindSet() then
            repeat
                if TextBuilder.Length = 0 then begin
                    if IntegrationTable then
                        TextBuilder.Append('<>' + Format(xRec."Integration Table Field No."))
                    else
                        TextBuilder.Append('<>' + Format(xRec."Table Field No."));
                end else
                    if IntegrationTable then
                        TextBuilder.Append('&<>' + Format(xRec."Integration Table Field No."))
                    else
                        TextBuilder.Append('&<>' + Format(xRec."Table Field No."));
            until xRec.Next() = 0;
        if TextBuilder.Length = 0 then
            Field.SetFilter("No.", '..1999999999')
        else
            Field.SetFilter("No.", TextBuilder.ToText() + '&..1999999999');
    end;

    internal procedure GetAllValidIntegrationFields(var IntegrationField: Record "Integration Field"; IntegrationMappingName: Code[20]; TableNo: Integer)
    var
        Field: Record "Field";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        Field.SetRange(TableNo, TableNo);
        GetAllValidFields(Field, true, IntegrationMappingName, TableNo);
        if Field.FindSet() then
            repeat
                IntegrationField."Table No." := Field.TableNo;
                IntegrationField."Field Name" := Field.FieldName;
                IntegrationField."Field Caption" := Field."Field Caption";
                IntegrationField."Field No." := Field."No.";
                IntegrationField.IsRuntime := false;
                IntegrationField.Insert();
            until Field.Next() = 0;
        CDSIntegrationMgt.GetEntityFields(TableNo, IntegrationField);
    end;

    internal procedure CompareFieldType(LocalField: Record Field; IntegrationField: Record Field)
    begin
        if LocalField.Type = IntegrationField.Type then
            exit;

        if ((LocalField.Type = LocalField.Type::Code) or
            (LocalField.Type = LocalField.Type::Text) or
            (LocalField.Type = LocalField.Type::BLOB)) and
            ((IntegrationField.Type = IntegrationField.Type::Code) or
            (IntegrationField.Type = IntegrationField.Type::Text) or
            (IntegrationField.Type = IntegrationField.Type::BLOB))
        then
            exit;

        if LocalField.Type <> IntegrationField.Type then
            Error(FieldTypeNotTheSameErr, IntegrationField."Field Caption", IntegrationField.Type, LocalField."Field Caption", LocalField.Type);
    end;

    internal procedure CreateRecord(IntegrationMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; lDirection: Option; ConstValue: Text[50]; ValidateField: Boolean; ValidateIntegrTableField: Boolean; TransformationRule: Code[20])
    begin
        Init();
        Name := IntegrationMappingName;
        "Table Field No." := TableFieldNo;
        "Integration Table Field No." := IntegrationTableFieldNo;
        Direction := lDirection;
        "Const Value" := ConstValue;
        ValidateField := ValidateField;
        ValidateIntegrTableField := ValidateIntegrTableField;
        "Transformation Rule" := TransformationRule;
        Insert(true);
    end;
}