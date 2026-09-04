// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.API;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Utilities;

/// <summary>
/// Power automate friendly web service for quality inspections.
/// This web service is used to help create quality inspections.
/// </summary>
page 20415 "Qlty. Create Inspection API"
{
    APIVersion = 'v1.0';
    APIGroup = 'qualityManagement';
    APIPublisher = 'microsoft';
    Editable = false;
    EntityName = 'createQualityInspection';
    EntitySetName = 'createQualityInspections';
    EntityCaption = 'Create Quality Inspection';
    EntitySetCaption = 'Create Quality Inspections';
    PageType = API;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(SourceDocument)
            {
                ShowCaption = false;

                field(systemIDOfAnyRecord; Rec.SystemId)
                {
                    Caption = 'System ID of any record';
                    ToolTip = 'Specifies the System ID of the record to create an inspection for.';
                }
            }
        }
    }

    var
        SystemRecord: Guid;
        CurrentTable: Integer;
        NoSystemIDRecordErr: Label 'Business Central cannot find a record for the System ID of %1', Comment = '%1=the system ID that was not found';
        OnlyOneRecordForTableAndFilterErr: Label 'Exactly one record must match the filter, but %1 were found for table %2 with filter %3.', Comment = '%1=count, %2=table, %3=filter';

    trigger OnFindRecord(Which: Text): Boolean
    var
        FilterGroupIterator: Integer;
    begin
        FilterGroupIterator := 4;
        repeat
            Rec.FilterGroup(FilterGroupIterator);
            if Rec.GetFilter(SystemId) <> '' then
                SystemRecord := Rec.GetRangeMin(SystemId);
            if Rec.GetFilter(ID) <> '' then
                CurrentTable := Rec.GetRangeMin(ID);

            FilterGroupIterator -= 1;
        until (FilterGroupIterator < 0);
        Rec.FilterGroup(0);

        Rec.ID := CurrentTable;
        Rec.SystemId := SystemRecord;
        if Rec.Insert(false, true) then;
        exit(Rec.Find(Which));
    end;

    /// <summary>
    /// Creates an inspection for the record identified by the page System ID and a table name or ID.
    /// </summary>
    /// <param name="ActionContext">The web service action context updated with the creation result.</param>
    /// <param name="tableName">The table ID or table name to create an inspection for.</param>
    [ServiceEnabled]
    procedure CreateInspectionFromRecordID(var ActionContext: WebServiceActionContext; tableName: Text)
    var
        CreatedInspection: Record "Qlty. Inspection Header";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        AnyInputRecord: RecordRef;
    begin
        Rec.ID := QltyFilterHelpers.IdentifyTableIDFromText(tableName);

        AnyInputRecord.Open(Rec.ID);

        if not AnyInputRecord.GetBySystemId(Rec.SystemId) then
            Error(NoSystemIDRecordErr, Rec.SystemId);

        if QltyInspectionCreate.CreateInspection(AnyInputRecord, true) then begin
            QltyInspectionCreate.GetCreatedInspection(CreatedInspection);
            ActionContext.SetObjectType(ObjectType::Table);
            ActionContext.SetObjectId(Database::"Name/Value Buffer");
            ActionContext.AddEntityKey(CreatedInspection.FieldNo(SystemId), CreatedInspection.SystemId);
            ActionContext.SetResultCode(WebServiceActionResultCode::Created);
            if Rec.IsTemporary() then
                Rec.DeleteAll();
            Rec.SystemId := CreatedInspection.SystemId;
            if Rec.Insert(false, true) then;
        end else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;

    /// <summary>
    /// Creates an inspection for the single record identified by a table and table view.
    /// </summary>
    /// <param name="ActionContext">The web service action context updated with the creation result.</param>
    /// <param name="tableName">The table ID, name, or caption containing the source record.</param>
    /// <param name="tableNameFilter">The table view that must identify exactly one source record.</param>
    [ServiceEnabled]
    procedure CreateInspectionFromTableIDAndFilter(var ActionContext: WebServiceActionContext; tableName: Text; tableNameFilter: Text)
    var
        CreatedInspection: Record "Qlty. Inspection Header";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        AnyInputRecord: RecordRef;
    begin
        Rec.ID := QltyFilterHelpers.IdentifyTableIDFromText(tableName);
        AnyInputRecord.Open(Rec.ID);
        AnyInputRecord.SetView(tableNameFilter);
        if not AnyInputRecord.FindSet(false) then
            Error(OnlyOneRecordForTableAndFilterErr, 0, Rec.ID, tableNameFilter);

        if AnyInputRecord.Count() <> 1 then
            Error(OnlyOneRecordForTableAndFilterErr, AnyInputRecord.Count(), Rec.ID, tableNameFilter);

        if QltyInspectionCreate.CreateInspection(AnyInputRecord, true) then begin
            QltyInspectionCreate.GetCreatedInspection(CreatedInspection);
            ActionContext.SetObjectType(ObjectType::Table);
            ActionContext.SetObjectId(Database::"Name/Value Buffer");
            ActionContext.AddEntityKey(CreatedInspection.FieldNo(SystemId), CreatedInspection.SystemId);
            ActionContext.SetResultCode(WebServiceActionResultCode::Created);
            if Rec.IsTemporary() then
                Rec.DeleteAll();
            Rec.SystemId := CreatedInspection.SystemId;
            if Rec.Insert(false, true) then;
        end else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
