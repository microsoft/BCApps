namespace Microsoft.FabricExport;

using System.Apps;
using System.Fabric;
using System.Reflection;
using System.Security.Authentication;

codeunit 48535 "Fabric Table Validation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Table Metadata" = r;

    var
        TableNotExportableErr: Label 'Table %1 cannot be exported to Microsoft Fabric because it is an external, linked, or virtual table.', Comment = '%1 = table id';
        TableRestrictedErr: Label 'Table %1 cannot be exported to Microsoft Fabric because it contains internal or sensitive data.', Comment = '%1 = table id';

    [EventSubscriber(ObjectType::Table, Database::"Tenant Fabric Tables", OnBeforeInsertEvent, '', false, false)]
    local procedure ValidateOnBeforeInsert(var Rec: Record "Tenant Fabric Tables")
    begin
        if Rec.IsTemporary() then
            exit;
        ValidateTable(Rec."Table ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Fabric Tables", OnBeforeModifyEvent, '', false, false)]
    local procedure ValidateOnBeforeModify(var Rec: Record "Tenant Fabric Tables")
    begin
        if Rec.IsTemporary() then
            exit;
        ValidateTable(Rec."Table ID");
    end;

    /// <summary>Returns an Object ID filter that leaves out every table that cannot be exported to Microsoft Fabric.</summary>
    internal procedure GetExportableTableIdFilter(): Text
    var
        TableMetadata: Record "Table Metadata";
        FilterBuilder: TextBuilder;
        NextAllowedId: Integer;
    begin
        // The filter lists the allowed ranges between the excluded IDs to keep it short.
        TableMetadata.SetLoadFields(ID, DataIsExternal, LinkedObject, TableType);
        if TableMetadata.FindSet() then
            repeat
                if IsRestrictedTable(TableMetadata.ID) or IsUnsupportedTable(TableMetadata) then begin
                    if TableMetadata.ID > NextAllowedId then
                        AppendRange(FilterBuilder, NextAllowedId, TableMetadata.ID - 1);
                    NextAllowedId := TableMetadata.ID + 1;
                end;
            until TableMetadata.Next() = 0;

        if FilterBuilder.Length() > 0 then
            FilterBuilder.Append('|');
        FilterBuilder.Append(Format(NextAllowedId, 0, 9) + '..');
        exit(FilterBuilder.ToText());
    end;

    local procedure ValidateTable(TableId: Integer)
    var
        TableMetadata: Record "Table Metadata";
    begin
        if IsRestrictedTable(TableId) then
            Error(TableRestrictedErr, TableId);

        // A missing table is reported by the callers; only reject what is known to be unsupported.
        if not TableMetadata.Get(TableId) then
            exit;

        if IsUnsupportedTable(TableMetadata) then
            Error(TableNotExportableErr, TableId);
    end;

    local procedure IsUnsupportedTable(var TableMetadata: Record "Table Metadata"): Boolean
    begin
        exit(TableMetadata.DataIsExternal or TableMetadata.LinkedObject or (TableMetadata.TableType <> TableMetadata.TableType::Normal));
    end;

    local procedure IsRestrictedTable(TableId: Integer): Boolean
    begin
        // Tenant Application Storage, Token Cache, AI Consumption Log Entry, Agent Data.
        exit(TableId in [Database::"Token Cache", Database::"Tenant Application Storage", 2000000147, 2000000258]);
    end;

    local procedure AppendRange(var FilterBuilder: TextBuilder; FromId: Integer; ToId: Integer)
    begin
        if FilterBuilder.Length() > 0 then
            FilterBuilder.Append('|');
        if FromId = ToId then
            FilterBuilder.Append(Format(FromId, 0, 9))
        else
            FilterBuilder.Append(Format(FromId, 0, 9) + '..' + Format(ToId, 0, 9));
    end;
}
