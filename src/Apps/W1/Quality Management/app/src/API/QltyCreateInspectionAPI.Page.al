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
/// This web service is used to help create tests.
/// </summary>
page 20415 "Qlty. Create Inspection API"
{
    APIVersion = 'v2.0';
    APIGroup = 'qualityinspection';
    APIPublisher = 'microsoft';
    Caption = 'qltyCreateInspection', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'qltyCreateInspectionOnRecord';
    EntitySetName = 'qltyCreateInspectionOnRecords';
    EntityCaption = 'Any Record in Business Central';
    EntitySetCaption = 'Records';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    RefreshOnActivate = true;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = SystemId;
    layout
    {
        area(Content)
        {
            repeater(rptTests)
            {
                ShowCaption = false;
                field(qltySystemIDOfAnyRecord; Rec.SystemId)
                {
                    Caption = 'qltySystemIDOfAnyRecord', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the system id of the record to create a test for.';
                }
            }
        }
    }

    var
        systemRecord: Guid;
        currentTable: Integer;
        NoSystemIDRecordErr: Label 'Business Central cannot find a record for the system id of %1', Locked = true;
        OnlyOneRecordForTableAndFilterErr: Label 'Please check your PowerAutomate configuration. 1 record should have been found, but %1 records were found for table %2 and filter %3.', Comment = '%1=the count, %2=the table, %3=the filter';

    trigger OnFindRecord(Which: Text): Boolean
    var
        FilterGroupIterator: Integer;
    begin
        FilterGroupIterator := 4;
        repeat
            Rec.FilterGroup(FilterGroupIterator);
            if Rec.GetFilter(SystemId) <> '' then
                systemRecord := Rec.GetRangeMin(SystemId);

            if Rec.GetFilter(ID) <> '' then
                currentTable := Rec.GetRangeMin(ID);

            FilterGroupIterator -= 1;
        until (FilterGroupIterator < 0);
        Rec.FilterGroup(0);
        Rec.ID := currentTable;
        Rec.SystemId := systemRecord;
        if Rec.Insert() then; // this is to work around BC needing the system id on any page action when used as a webservice.        
        exit(Rec.Find(Which));
    end;

    // Min of BC 16 for the system ID and GetBySystemId
    /// <summary>
    /// Minimum of BC 16 is needed.
    /// Create a test from a known table.
    /// </summary>
    /// <param name="tableName">The table ID or table name to create a test</param>
    /// <param name="ActionContext"></param>
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
            if Rec.IsTemporary then Rec.DeleteAll();
            Rec.SystemId := CreatedInspection.SystemId;
            if Rec.Insert() then;
        end else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;

    /// <summary>
    /// Creates a test with a table and table filter to identify a record.
    /// </summary>
    /// <param name="ActionContext">VAR WebServiceActionContext.</param>
    /// <param name="tableName">Text. The table ID, or table name, or table caption.</param>
    /// <param name="tableNameFilter">The table filter that can identify a specific record.</param>
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
            if Rec.IsTemporary then Rec.DeleteAll();
            Rec.SystemId := CreatedInspection.SystemId;
            if Rec.Insert() then;
        end else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
