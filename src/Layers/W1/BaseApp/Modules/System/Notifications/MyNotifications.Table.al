namespace System.Environment.Configuration;

using System;
using System.Automation;
using System.Reflection;
using System.Utilities;
using System.Xml;

table 1518 "My Notifications"
{
    Caption = 'My Notifications';
    InherentEntitlements = riX;
    InherentPermissions = riX;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Id"; Code[50])
        {
            Caption = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            NotBlank = true;
        }
        field(2; "Notification Id"; Guid)
        {
            Caption = 'Notification Id';
            Editable = false;
            NotBlank = true;
        }
        field(3; "Apply to Table Id"; Integer)
        {
            Caption = 'Apply to Table Id';
            Editable = false;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            begin
                if Enabled <> xRec.Enabled then
                    OnStateChanged("Notification Id", Enabled);
            end;
        }
        field(5; "Apply to Table Filter"; BLOB)
        {
            Caption = 'Filter';
        }
        field(6; Name; Text[128])
        {
            Caption = 'Notification';
            Editable = false;
            NotBlank = true;
        }
        field(7; Description; BLOB)
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "User Id", "Notification Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ViewFilterDetailsTxt: Label '(View filter details)';
        DefineFiltersTxt: Label 'Define filters...';

    procedure Disable(NotificationId: Guid): Boolean
    begin
        if Get(UserId, NotificationId) then begin
            Validate(Enabled, false);
            Modify();
            exit(true)
        end;
        exit(false);
    end;

    procedure SetStatus(NotificationId: Guid; Enable: Boolean): Boolean
    begin
        if Get(UserId, NotificationId) then begin
            Validate(Enabled, Enable);
            Modify();
            exit(true)
        end;
        exit(false);
    end;

    local procedure IsFilterEnabled(): Boolean
    var
        AllObj: Record AllObj;
    begin
        AllObj.SETRANGE("Object Type", AllObj."Object Type"::Table);
        AllObj.SETRANGE("Object ID", "Apply to Table Id");
        exit(("Apply to Table Id" <> 0) and Enabled and (not AllObj.IsEmpty()));
    end;

    local procedure InitRecord(NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text) Result: Boolean
    var
        OutStream: OutStream;
    begin
        if not Get(UserId, NotificationId) then begin
            Init();
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Notification Id" := NotificationId;
            Enabled := true;
            Name := NotificationName;
            Description.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.Write(DescriptionText);
            Result := true;
        end else
            if NotificationName <> Name then begin
                Name := NotificationName;
                Description.CreateOutStream(OutStream, TextEncoding::UTF8);
                OutStream.Write(DescriptionText);
                Modify(false);
                Result := false;
            end;
    end;

    procedure InsertDefault(NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text; DefaultState: Boolean)
    begin
        if Rec.WritePermission then
            if InitRecord(NotificationId, NotificationName, DescriptionText) then begin
                Enabled := DefaultState;
                Insert();
            end;
    end;

    procedure InsertDefaultWithTableNum(NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text; TableNum: Integer)
    begin
        if Rec.WritePermission then
            if InitRecord(NotificationId, NotificationName, DescriptionText) then begin
                "Apply to Table Id" := TableNum;
                Insert();
            end;
    end;

    procedure InsertDefaultWithTableNumAndFilter(NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text; TableNum: Integer; Filters: Text)
    var
        FiltersOutStream: OutStream;
        NewRecord: Boolean;
    begin
        if Rec.WritePermission then begin
            NewRecord := InitRecord(NotificationId, NotificationName, DescriptionText);
            if "Apply to Table Id" = 0 then begin
                "Apply to Table Id" := TableNum;
                "Apply to Table Filter".CreateOutStream(FiltersOutStream);
                FiltersOutStream.Write(GetXmlFromTableView(TableNum, Filters));
                if NewRecord then
                    Insert()
                else
                    Modify();
            end;
        end;
    end;

    procedure GetDescription() Ret: Text
    var
        InStream: InStream;
    begin
        if Rec.ReadPermission then begin
            CalcFields(Description);
            if not Description.HasValue() then
                exit;
            Description.CreateInStream(InStream, TextEncoding::UTF8);
            InStream.Read(Ret);
        end;
    end;

    local procedure GetFilteredRecord(var RecordRef: RecordRef; Filters: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FiltersOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FiltersOutStream);
        FiltersOutStream.Write(Filters);

        RecordRef.Open("Apply to Table Id");
        RequestPageParametersHelper.ConvertParametersToFilters(RecordRef, TempBlob);
    end;

    procedure GetFiltersAsDisplayText(): Text
    var
        RecordRef: RecordRef;
    begin
        if not IsFilterEnabled() then
            exit;

        GetFilteredRecord(RecordRef, GetFiltersAsText());

        if RecordRef.GetFilters <> '' then
            exit(RecordRef.GetFilters);

        exit(ViewFilterDetailsTxt);
    end;

    local procedure GetFiltersAsText() Filters: Text
    var
        FiltersInStream: InStream;
    begin
        if not IsFilterEnabled() then
            exit;

        CalcFields("Apply to Table Filter");
        if not "Apply to Table Filter".HasValue() then
            exit;
        "Apply to Table Filter".CreateInStream(FiltersInStream);
        FiltersInStream.Read(Filters);
    end;

    procedure GetXmlFromTableView(TableID: Integer; View: Text): Text
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        DataItemXmlNode: DotNet XmlNode;
        DataItemsXmlNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
        ReportParametersXmlNode: DotNet XmlNode;
    begin
        XmlDoc := XmlDoc.XmlDocument();

        XMLDOMMgt.AddRootElement(XmlDoc, 'ReportParameters', ReportParametersXmlNode);
        XMLDOMMgt.AddDeclaration(XmlDoc, '1.0', 'utf-8', 'yes');

        XMLDOMMgt.AddElement(ReportParametersXmlNode, 'DataItems', '', '', DataItemsXmlNode);
        XMLDOMMgt.AddElement(DataItemsXmlNode, 'DataItem', View, '', DataItemXmlNode);
        XMLDOMMgt.AddAttribute(DataItemXmlNode, 'name', StrSubstNo('Table%1', TableID));

        exit(XmlDoc.InnerXml);
    end;

    procedure OpenFilterSettings() Changed: Boolean
    var
        DummyMyNotifications: Record "My Notifications";
        RecordRef: RecordRef;
        FiltersOutStream: OutStream;
        NewFilters: Text;
    begin
        if not IsFilterEnabled() then
            exit;

        if RunDynamicRequestPage(NewFilters,
             GetFiltersAsText(),
             "Apply to Table Id")
        then begin
            GetFilteredRecord(RecordRef, NewFilters);
            if RecordRef.GetFilters = '' then
                "Apply to Table Filter" := DummyMyNotifications."Apply to Table Filter"
            else begin
                "Apply to Table Filter".CreateOutStream(FiltersOutStream);
                FiltersOutStream.Write(NewFilters);
            end;
            Modify();
            Changed := true;
        end;
    end;

    local procedure RunDynamicRequestPage(var ReturnFilters: Text; Filters: Text; TableNum: Integer) FiltersSet: Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
    begin
        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, DefineFiltersTxt, TableNum) then
            exit(false);

        if Filters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(
                 FilterPageBuilder, Filters, DefineFiltersTxt, TableNum)
            then
                exit(false);

        FilterPageBuilder.PageCaption := DefineFiltersTxt;
        if not FilterPageBuilder.RunModal() then
            exit(false);

        ReturnFilters :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, DefineFiltersTxt, TableNum);

        FiltersSet := true;
    end;

    procedure IsEnabledForRecord(NotificationId: Guid; "Record": Variant): Boolean
    var
        RecordRef: RecordRef;
        RecordRefPassed: RecordRef;
        Filters: Text;
    begin
        if not IsEnabledRec(NotificationId, Record) then
            exit(false);

        if not Record.IsRecord then
            exit(true);

        RecordRefPassed.GetTable(Record);
        RecordRefPassed.FilterGroup(2);
        RecordRefPassed.SetRecFilter();
        RecordRefPassed.FilterGroup(0);

        if Get(UserId, NotificationId) then;

        Filters := GetFiltersAsText();
        if Filters = '' then
            exit(true);

        GetFilteredRecord(RecordRef, Filters);
        RecordRefPassed.SetView(RecordRef.GetView());
        exit(not RecordRefPassed.IsEmpty);
    end;

    procedure IsEnabled(NotificationId: Guid): Boolean
    var
        DummyRecord: Variant;
    begin
        exit(IsEnabledRec(NotificationId, DummyRecord));
    end;

    local procedure IsEnabledRec(NotificationId: Guid; "Record": Variant): Boolean
    var
        IsNotificationEnabled: Boolean;
    begin
        IsNotificationEnabled := true;

        if Get(UserId, NotificationId) then
            IsNotificationEnabled := Enabled;

        OnAfterIsNotificationEnabled(NotificationId, IsNotificationEnabled, Record);

        exit(IsNotificationEnabled);
    end;

    [IntegrationEvent(false, false)]
    procedure OnStateChanged(NotificationId: Guid; NewEnabledState: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterIsNotificationEnabled(NotificationId: Guid; var IsNotificationEnabled: Boolean; "Record": Variant)
    begin
    end;
}

