namespace Microsoft.FabricExport;

using System.Fabric;
using System.Reflection;

codeunit 48536 "Fabric Field Validation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Field = r;

    var
        FieldTypeNotSupportedErr: Label 'Field %1 of table %2 cannot be exported to Microsoft Fabric because its type, %3, is not supported.', Comment = '%1 = field id, %2 = table id, %3 = field type';
        FieldClassNotSupportedErr: Label 'Field %1 of table %2 cannot be exported to Microsoft Fabric because it is a FlowField or FlowFilter.', Comment = '%1 = field id, %2 = table id';

    [EventSubscriber(ObjectType::Table, Database::"Tenant Fabric Table Fields", OnBeforeInsertEvent, '', false, false)]
    local procedure ValidateOnBeforeInsert(var Rec: Record "Tenant Fabric Table Fields")
    begin
        if Rec.IsTemporary() then
            exit;
        ValidateField(Rec."Table ID", Rec."Field ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Fabric Table Fields", OnBeforeModifyEvent, '', false, false)]
    local procedure ValidateOnBeforeModify(var Rec: Record "Tenant Fabric Table Fields")
    begin
        if Rec.IsTemporary() then
            exit;
        ValidateField(Rec."Table ID", Rec."Field ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Fabric Table Fields", OnBeforeRenameEvent, '', false, false)]
    local procedure ValidateOnBeforeRename(var Rec: Record "Tenant Fabric Table Fields")
    begin
        if Rec.IsTemporary() then
            exit;
        ValidateField(Rec."Table ID", Rec."Field ID");
    end;

    local procedure ValidateField(TableId: Integer; FieldId: Integer)
    var
        Field: Record Field;
    begin
        // A missing field is reported by the callers; only reject what is known to be unsupported.
        if not Field.Get(TableId, FieldId) then
            exit;

        if Field.Class <> Field.Class::Normal then
            Error(FieldClassNotSupportedErr, FieldId, TableId);

        if not IsSupportedType(Field) then
            Error(FieldTypeNotSupportedErr, FieldId, TableId, Field.Type);
    end;

    local procedure IsSupportedType(var Field: Record Field): Boolean
    begin
        // Enum and Byte-based fields are reported as Option.
        case Field.Type of
            Field.Type::Text,
            Field.Type::Code,
            Field.Type::DateFormula,
            Field.Type::GUID,
            Field.Type::Integer,
            Field.Type::BigInteger,
            Field.Type::Decimal,
            Field.Type::Boolean,
            Field.Type::Option,
            Field.Type::Duration,
            Field.Type::Date,
            Field.Type::Time,
            Field.Type::DateTime:
                exit(true);
        end;
        exit(false);
    end;
}
