namespace System.Integration;

using System;
using System.Apps;
using System.Reflection;

page 6710 "OData Column Choose SubForm"
{
    Caption = 'OData Column Choose SubForm';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Tenant Web Service Columns";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Include; Rec.Include)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field name that is selected in the data set.';

                    trigger OnValidate()
                    begin
                        if CalledForExcelExport then
                            CheckFieldFilter();
                        IsModified := true;
                    end;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the field names in a data set.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    Editable = false;
                    ToolTip = 'Specifies the Field Captions in a data set.';
                }
                field("Data Item Caption"; Rec."Data Item Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Table';
                    Editable = false;
                    ToolTip = 'Specifies the Source Table for the Field Name.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    var
        RecRef: RecordRef;
        ColumnList: DotNet GenericList1;
        SourceObjectType: Option ,,,,,,,,"Page","Query";
        ActionType: Option "Create a new data set","Create a copy of an existing data set","Edit an existing data set";
        SourceServiceName: Text;
        SourceObjectID: Integer;
        IsModified: Boolean;
        CheckFieldErr: Label 'You cannot exclude field from selection because of applied filter for it.';
        AskYourSystemAdministratorToSetupErr: Label 'Cannot complete this task. Ask your administrator for assistance.';
        CalledForExcelExport: Boolean;

    [Scope('OnPrem')]
    procedure InitColumns(ObjectType: Option ,,,,,,,,"Page","Query"; ObjectID: Integer; InActionType: Option "Create a new data set","Create a copy of an existing data set","Edit an existing data set"; InSourceServiceName: Text; DestinationServiceName: Text)
    var
        AllObj: Record AllObj;
        ApplicationObjectMetadata: Record "Application Object Metadata";
        inStream: InStream;
    begin
        if Rec.FindFirst() then
            exit;

        ActionType := InActionType;
        SourceObjectType := ObjectType;
        SourceServiceName := InSourceServiceName;
        SourceObjectID := ObjectID;
        DestinationServiceName := DestinationServiceName;

        AllObj.Get(SourceObjectType, SourceObjectID);

        if SourceObjectType = SourceObjectType::Page then
            InitColumnsForPage(ObjectID)
        else begin
            if not ApplicationObjectMetadata.ReadPermission() then
                Error(AskYourSystemAdministratorToSetupErr);

            ApplicationObjectMetadata.Get(AllObj."App Runtime Package ID", SourceObjectType, SourceObjectID);
            if not ApplicationObjectMetadata.Metadata.HasValue() then
                exit;

            ApplicationObjectMetadata.CalcFields(Metadata);
            ApplicationObjectMetadata.Metadata.CreateInStream(inStream, TextEncoding::Windows);

            if SourceObjectType = SourceObjectType::Query then
                InitColumnsForQuery(inStream)
        end;

        Clear(Rec);
        CurrPage.Update();
    end;

    procedure GetColumns(var TempTenantWebServiceColumns: Record "Tenant Web Service Columns" temporary)
    begin
        Rec.SetRange(Include, true);
        if Rec.FindFirst() then
            repeat
                TempTenantWebServiceColumns.TransferFields(Rec);
                TempTenantWebServiceColumns.Insert();

            until Rec.Next() = 0;
        Rec.Reset();
    end;

    local procedure InitColumnsForQuery(queryStream: InStream)
    var
        queryField: DotNet QueryFields;
        metaData: DotNet QueryMetadataReader;
        i: Integer;
        OldTableNo: Integer;
    begin
        // Load into Query Metadata Reader and retrieve values
        metaData := metaData.FromStream(queryStream);
        if metaData.Fields.Count = 0 then
            exit;
        OldTableNo := 0;
        for i := 0 to metaData.Fields.Count - 1 do begin
            queryField := metaData.Fields.Item(i);
            if OldTableNo <> queryField.TableNo then
                ColumnList := ColumnList.List();
            OldTableNo := queryField.TableNo;
            Clear(Rec);
            if not queryField.IsFilterOnly then
                InsertRecord(queryField.TableNo, queryField.FieldNo, queryField.FieldName, false);
        end;
    end;

    local procedure InitColumnsForPage(ObjectID: Integer)
    var
        FieldsTable: Record "Field";
        ODataUtility: Codeunit ODataUtility;
        PageControlField: Record "Page Control Field";
        FieldNameText: Text;
        ColumnVisible: Boolean;
    begin
        ColumnList := ColumnList.List();
        // Sort on sequence to maintain order
        PageControlField.SetCurrentKey(Sequence);
        PageControlField.SETRANGE(PageNo, ObjectID);
        if PageControlField.FindSet() then
            repeat
                if not Evaluate(ColumnVisible, PageControlField.Visible) then
                    ColumnVisible := false;
                // Convert to OData compatible name.
                FieldNameText := ODataUtility.ExternalizeName(PageControlField.ControlName);
                if FieldsTable.Get(PageControlField.TableNo, PageControlField.FieldNo) then
                    // Page field is based on table (fieldsTable)
                    InsertRecord(FieldsTable.TableNo, FieldsTable."No.", FieldNameText, ColumnVisible)
                else
                    // Page field is NOT based on table 
                    InsertRecord(PageControlField.TableNo, PageControlField.ControlId, FieldNameText, ColumnVisible);
            until PageControlField.Next() = 0;
    end;

    local procedure InsertRecord(TableNo: Integer; FieldNo: Integer; FieldName: Text; IncludeParam: Boolean)
    begin
        if ColumnList.Contains(FieldNo) then
            exit;

        Rec.Init();
        Rec.Validate("Data Item", TableNo);
        Rec.Validate("Field Number", FieldNo);
        Rec.Validate("Field Name", CopyStr(FieldName, 1));
        if (ActionType = ActionType::"Create a copy of an existing data set") or
           (ActionType = ActionType::"Edit an existing data set")
        then begin
            if SourceColumnExists(TableNo, FieldNo) then
                Rec.Include := true;
        end else
            Rec.Include := IncludeParam;
        repeat
            Rec."Entry ID" := Rec."Entry ID" + 1;
        until Rec.Insert(true);

        ColumnList.Add(FieldNo);
    end;

    procedure DeleteColumns()
    begin
        Clear(Rec);
        Rec.DeleteAll();
    end;

    local procedure SourceColumnExists(TableNo: Integer; FieldNumber: Integer): Boolean
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
    begin
        TenantWebService.Init();
        if TenantWebService.Get(SourceObjectType, SourceServiceName) then begin
            TenantWebServiceColumns.Init();
            TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
            TenantWebServiceColumns.SetRange("Field Number", FieldNumber);
            TenantWebServiceColumns.SetRange("Data Item", TableNo);
            if TenantWebServiceColumns.FindFirst() then
                exit(true);
        end;
    end;

    procedure IncludeIsChanged(): Boolean
    var
        LocalDirty: Boolean;
    begin
        LocalDirty := IsModified;
        Clear(IsModified);
        exit(LocalDirty);
    end;

    procedure SetCalledForExcelExport(var SourceRecRef: RecordRef)
    begin
        CalledForExcelExport := true;
        RecRef := SourceRecRef;
    end;

    local procedure CheckFieldFilter()
    var
        FieldRef: FieldRef;
    begin
        if not Rec.Include then begin
            FieldRef := RecRef.Field(Rec."Field Number");
            if FieldRef.GetFilter <> '' then
                Error(CheckFieldErr);
        end;
    end;
}

