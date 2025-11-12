#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;
table 5381 "Man. Integration Field Mapping"
{
    DataClassification = SystemMetadata;
    ObsoleteReason = 'This table is obsolete. Start using the temporary table Man. Integration Field Mapping.';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    fields
    {
        field(10; "Mapping Name"; Code[20])
        {
            Caption = 'Mapping Name';
            DataClassification = SystemMetadata;
            TableRelation = "Man. Integration Table Mapping".Name;
        }
        field(20; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
            TableRelation = "Man. Integration Table Mapping"."Table ID";
        }
        field(40; "Table Field ID"; Integer)
        {
            Caption = 'Table Field';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Table ID"),
                                                type = filter(BigInteger | Boolean | Code | Date | DateFormula | Decimal | Duration | GUID | Integer | Option | Text | BLOB),
                                                "No." = filter(.. 1999999999));
            trigger OnValidate()
            var
                ManualIntTableMapping: Record "Man. Integration Table Mapping";
                Fld: Record Field;
            begin
                ManualIntTableMapping.Get("Mapping Name");
                Rec."Integration Table ID" := ManualIntTableMapping."Integration Table ID";
                Fld.Get(Rec."Table ID", Rec."Table Field ID");
                CheckFieldTypeForSync(Fld);
                CheckTableRelationForSync(Fld);
            end;
        }
        field(60; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
            DataClassification = SystemMetadata;
            TableRelation = "Man. Integration Table Mapping"."Integration Table ID";
        }
        field(80; "Integration Table Field ID"; Integer)
        {
            Caption = 'Integration Table Field';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Integration Table ID"),
                                                type = filter(BigInteger | Boolean | Code | Date | DateFormula | Decimal | Duration | GUID | Integer | Option | Text | BLOB));
            trigger OnValidate()
            var
                LocalField: Record Field;
                IntegrationField: Record Field;
            begin
                LocalField.Get(Rec."Table ID", Rec."Table Field ID");
                IntegrationField.Get(Rec."Integration Table ID", Rec."Integration Table Field ID");
                CompareFieldType(LocalField, IntegrationField);
                CheckTableRelationForSync(IntegrationField);
                CheckTableRelationForSync(IntegrationField);
            end;
        }
        field(100; "Direction"; Option)
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(110; "Const Value"; Text[50])
        {
            Caption = 'Const Value';
            DataClassification = SystemMetadata;
        }
        field(120; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
            DataClassification = SystemMetadata;
        }
        field(130; "Validate Integr Table Field"; Boolean)
        {
            Caption = 'Validate Integration Table Field';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Mapping Name", "Table ID")
        {
            Clustered = true;
        }
    }

    var
        FieldClassNormalErr: Label 'The field %1 must have the field class set to "Normal"', comment = '%1 = field name';
        FieldTypeNotSupportedErr: Label 'The field %1 of type %2 is not supported.', Comment = '%1 = field name, %2 = field type';
        FieldTypeNotTheSameErr: Label 'The field %1 with type %2 must have the same type as field %3 (%4).', Comment = '%1 - field name, %2 - field type, %3 - field name, %4 - field type';
        FieldRelationExistsErr: Label 'The field %1 must not have a relationship with another table.', Comment = '%1 = field name';

    internal procedure CheckFieldTypeForSync(FieldRec: Record Field)
    begin
        if FieldRec.Class <> FieldRec.Class::Normal then
            Error(FieldClassNormalErr, FieldRec."Field Caption");

        case FieldRec.Type of
            FieldRec.Type::BigInteger,
            FieldRec.Type::Boolean,
            FieldRec.Type::Code,
            FieldRec.Type::Date,
            FieldRec.Type::DateFormula,
            FieldRec.Type::DateTime,
            FieldRec.Type::Decimal,
            FieldRec.Type::Duration,
            FieldRec.Type::GUID,
            FieldRec.Type::Integer,
            FieldRec.Type::Option,
            FieldRec.Type::Text,
            FieldRec.Type::BLOB:
                exit;
        end;
        Error(FieldTypeNotSupportedErr, FieldRec."Field Caption", FieldRec.Type);
    end;

    internal procedure CheckTableRelationForSync(FieldRec: Record Field)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetRange("Table ID", FieldRec.TableNo);
        TableRelationsMetadata.SetRange("Field No.", FieldRec."No.");
        if not TableRelationsMetadata.IsEmpty() then
            Error(FieldRelationExistsErr, FieldRec."Field Caption");
    end;

    internal procedure CompareFieldType(LocalField: Record Field; IntegrationField: Record Field)
    begin
        if
            (LocalField.Type = LocalField.Type::Code) or
            (IntegrationField.Type = IntegrationField.Type::Text) or
            (IntegrationField.Type = IntegrationField.Type::BLOB)
        then
            exit;

        if LocalField.Type <> IntegrationField.Type then
            Error(FieldTypeNotTheSameErr, IntegrationField."Field Caption", IntegrationField.Type, LocalField."Field Caption", LocalField.Type);
    end;
}
#endif