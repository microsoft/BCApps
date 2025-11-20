// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.CRM.Contact;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;
using System.Reflection;

table 5468 "Picture Entity"
{
    Caption = 'Picture Entity';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; Width; Integer)
        {
            Caption = 'Width';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12; Height; Integer)
        {
            Caption = 'Height';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(13; "Mime Type"; Text[100])
        {
            Caption = 'Mime Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; Content; BLOB)
        {
            Caption = 'Content';
            DataClassification = SystemMetadata;
        }
        field(21; "Parent Type"; Enum "Picture Entity Parent Type")
        {
            Caption = 'Parent Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        IdNotProvidedErr: Label 'You must specify a resource ID to get the picture.', Locked = true;
        RequestedRecordDoesNotExistErr: Label 'No resource with the specified ID exists.', Locked = true;
        RequestedRecordIsNotSupportedErr: Label 'Images are not supported for requested entity - %1.', Locked = true;
        EntityNotSupportedErr: Label 'Given parent type is not supported.';
        MultipleParentsFoundErr: Label 'Multiple parents have been found for the specified criteria.';
        MediaExtensionWithNumNameTxt: Label '%1 %2.%3', Locked = true;
        MediaExtensionWithNumFullNameTxt: Label '%1 %2 %3.%4', Locked = true;

    [Scope('OnPrem')]
    procedure LoadData(IdFilter: Text)
    var
        ParentRecordRef: RecordRef;
        MediaID: Guid;
    begin
        FindRecordFromFilter(ParentRecordRef, IdFilter);
        Id := ParentRecordRef.Field(ParentRecordRef.SystemIdNo).Value();

        MediaID := GetMediaID(ParentRecordRef);
        SetValuesFromMediaID(MediaID);
    end;

    procedure LoadDataWithParentType(IdFilter: Text; ParentType: Enum "Picture Entity Parent Type")
    var
        MediaID: Guid;
    begin
        Id := IdFilter;
        "Parent Type" := ParentType;
        MediaID := GetMediaIDWithParentType(Id, ParentType);
        SetValuesFromMediaID(MediaID);
    end;

    [Scope('OnPrem')]
    procedure SavePicture()
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        ParentRecordRef: RecordRef;
        ImageInStream: InStream;
        IsHandled: Boolean;
    begin
        FindRecordFromFilter(ParentRecordRef, StrSubstNo('=%1', Id));
        Content.CreateInStream(ImageInStream);

        case ParentRecordRef.Number of
            DATABASE::Item:
                begin
                    Item.Get(ParentRecordRef.RecordId);
                    Clear(Item.Picture);
                    Item.Picture.ImportStream(ImageInStream, GetDefaultMediaDescription(Item));
                    Item.Modify(true);
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(ParentRecordRef.RecordId);
                    Clear(Customer.Image);
                    Customer.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Customer));
                    Customer.Modify(true);
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(ParentRecordRef.RecordId);
                    Clear(Vendor.Image);
                    Vendor.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Vendor));
                    Vendor.Modify(true);
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(ParentRecordRef.RecordId);
                    Clear(Employee.Image);
                    Employee.Image.ImportStream(
                      ImageInStream, GetDefaultMediaDescription(Employee));
                    Employee.Modify(true);
                end;
            DATABASE::Contact:
                begin
                    Contact.Get(ParentRecordRef.RecordId);
                    Clear(Contact.Image);
                    Contact.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Contact));
                    Contact.Modify(true);
                end;
            else begin
                OnSavePictureElseCase(ParentRecordRef, IsHandled);
                if not IsHandled then
                    ThrowEntityNotSupportedError(ParentRecordRef.Number);
            end;
        end;

        LoadData(StrSubstNo('=%1', Id));
    end;

    procedure SavePictureWithParentType()
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        ImageInStream: InStream;
    begin
        Content.CreateInStream(ImageInStream);

        case "Parent Type" of
            "Parent Type"::Item:
                if Item.GetBySystemId(Id) then begin
                    Clear(Item.Picture);
                    Item.Picture.ImportStream(ImageInStream, GetDefaultMediaDescription(Item));
                    Item.Modify(true);
                end;
            "Parent Type"::Customer:
                if Customer.GetBySystemId(Id) then begin
                    Clear(Customer.Image);
                    Customer.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Customer));
                    Customer.Modify(true);
                end;
            "Parent Type"::Vendor:
                if Vendor.GetBySystemId(Id) then begin
                    Clear(Vendor.Image);
                    Vendor.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Vendor));
                    Vendor.Modify(true);
                end;
            "Parent Type"::Employee:
                if Employee.GetBySystemId(Id) then begin
                    Clear(Employee.Image);
                    Employee.Image.ImportStream(
                      ImageInStream, GetDefaultMediaDescription(Employee));
                    Employee.Modify(true);
                end;
            "Parent Type"::Contact:
                if Contact.GetBySystemId(Id) then begin
                    Clear(Contact.Image);
                    Contact.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Contact));
                    Contact.Modify(true);
                end;
            else
                Error(EntityNotSupportedErr);
        end;

        LoadDataWithParentType(Format(Id), "Parent Type");
    end;

    procedure DeletePicture()
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        ParentRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        FindRecordFromFilter(ParentRecordRef, StrSubstNo('=%1', Id));

        case ParentRecordRef.Number of
            DATABASE::Item:
                begin
                    Item.Get(ParentRecordRef.RecordId);
                    Clear(Item.Picture);
                    Item.Modify(true);
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(ParentRecordRef.RecordId);
                    Clear(Customer.Image);
                    Customer.Modify(true);
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(ParentRecordRef.RecordId);
                    Clear(Vendor.Image);
                    Vendor.Modify(true);
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(ParentRecordRef.RecordId);
                    Clear(Employee.Image);
                    Employee.Modify(true);
                end;
            DATABASE::Contact:
                begin
                    Contact.Get(ParentRecordRef.RecordId);
                    Clear(Contact.Image);
                    Contact.Modify(true);
                end;
            else begin
                IsHandled := false;
                OnDeletePictureElseCase(ParentRecordRef, IsHandled);
                if not IsHandled then
                    ThrowEntityNotSupportedError(ParentRecordRef.Number);
            end;
        end;

        Clear(Rec);
        Id := ParentRecordRef.Field(ParentRecordRef.SystemIdNo).Value();
    end;

    procedure DeletePictureWithParentType()
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        TempId: Guid;
        TempParentType: Enum "Picture Entity Parent Type";
    begin
        case "Parent Type" of
            "Parent Type"::Item:
                if Item.GetBySystemId(Id) then begin
                    Clear(Item.Picture);
                    Item.Modify(true);
                end;
            "Parent Type"::Customer:
                if Customer.GetBySystemId(Id) then begin
                    Clear(Customer.Image);
                    Customer.Modify(true);
                end;
            "Parent Type"::Vendor:
                if Vendor.GetBySystemId(Id) then begin
                    Clear(Vendor.Image);
                    Vendor.Modify(true);
                end;
            "Parent Type"::Employee:
                if Employee.GetBySystemId(Id) then begin
                    Clear(Employee.Image);
                    Employee.Modify(true);
                end;
            "Parent Type"::Contact:
                if Contact.GetBySystemId(Id) then begin
                    Clear(Contact.Image);
                    Contact.Modify(true);
                end;
            else
                Error(EntityNotSupportedErr);
        end;

        TempId := Id;
        TempParentType := "Parent Type";
        Clear(Rec);
        Id := TempId;
        "Parent Type" := TempParentType;
    end;

    local procedure GetMediaIDWithParentType(ParentId: Guid; ParentType: Enum "Picture Entity Parent Type"): Guid
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        MediaID: Guid;
    begin
        case ParentType of
            "Parent Type"::Item:
                if Item.GetBySystemId(ParentId) then
                    if Item.Picture.Count > 0 then
                        MediaID := Item.Picture.Item(1);
            "Parent Type"::Customer:
                if Customer.GetBySystemId(ParentId) then
                    MediaID := Customer.Image.MediaId;
            "Parent Type"::Vendor:
                if Vendor.GetBySystemId(ParentId) then
                    MediaID := Vendor.Image.MediaId;
            "Parent Type"::Employee:
                if Employee.GetBySystemId(ParentId) then
                    MediaID := Employee.Image.MediaId;
            "Parent Type"::Contact:
                if Contact.GetBySystemId(ParentId) then
                    MediaID := Contact.Image.MediaId;
            else
                Error(EntityNotSupportedErr);
        end;

        exit(MediaID);
    end;

    local procedure GetMediaID(var ParentRecordRef: RecordRef): Guid
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        MediaID: Guid;
        IsHandled: Boolean;
    begin
        case ParentRecordRef.Number of
            DATABASE::Item:
                begin
                    Item.Get(ParentRecordRef.RecordId);
                    if Item.Picture.Count > 0 then
                        MediaID := Item.Picture.Item(1);
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(ParentRecordRef.RecordId);
                    MediaID := Customer.Image.MediaId;
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(ParentRecordRef.RecordId);
                    MediaID := Vendor.Image.MediaId;
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(ParentRecordRef.RecordId);
                    MediaID := Employee.Image.MediaId;
                end;
            DATABASE::Contact:
                begin
                    Contact.Get(ParentRecordRef.RecordId);
                    MediaID := Contact.Image.MediaId;
                end;
            else begin
                OnGetMediaIDElseCase(ParentRecordRef, MediaID, IsHandled);
                IsHandled := false;
                if not IsHandled then
                    ThrowEntityNotSupportedError(ParentRecordRef.Number);
            end;
        end;

        exit(MediaID);
    end;

    procedure GetRecordRefFromFilter(IDFilter: Text; var ParentRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        Contact: Record Contact;
        RecordFound: Boolean;
    begin
        Item.SetFilter(SystemId, IDFilter);
        if Item.FindFirst() then begin
            ParentRecordRef.GetTable(Item);
            RecordFound := true;
        end;

        Customer.SetFilter(SystemId, IDFilter);
        if Customer.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Customer);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Vendor.SetFilter(SystemId, IDFilter);
        if Vendor.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Vendor);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Employee.SetFilter(SystemId, IDFilter);
        if Employee.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Employee);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Contact.SetFilter(SystemId, IDFilter);
        if Contact.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Contact);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        OnAfterGetRecordRefFromFilter(IDFilter, ParentRecordRef, RecordFound);
        exit(RecordFound);
    end;

    local procedure SetValuesFromMediaID(MediaID: Guid)
    var
        TenantMedia: Record "Tenant Media";
    begin
        // TODO: This code should be replaced once we get a proper platform support
        // We should not build dependencies to TenantMedia table
        if IsNullGuid(MediaID) then
            exit;

        TenantMedia.SetAutoCalcFields(Content);
        if not TenantMedia.Get(MediaID) then
            exit;

        "Mime Type" := TenantMedia."Mime Type";
        Width := TenantMedia.Width;
        Height := TenantMedia.Height;

        Content := TenantMedia.Content;
    end;

    local procedure FindRecordFromFilter(var ParentRecordRef: RecordRef; IDFilter: Text)
    begin
        if IDFilter = '' then
            Error(IdNotProvidedErr);

        if not GetRecordRefFromFilter(IDFilter, ParentRecordRef) then
            Error(RequestedRecordDoesNotExistErr);
    end;

    local procedure ThrowEntityNotSupportedError(TableID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        if AllObjWithCaption.FindFirst() then;
        Error(RequestedRecordIsNotSupportedErr, AllObjWithCaption."Object Caption");
    end;

    procedure GetDefaultMediaDescription(ParentRecord: Variant): Text
    var
        Item: Record Item;
        Customer: Record Customer;
        Employee: Record Employee;
        Vendor: Record Vendor;
        Contact: Record Contact;
        ParentRecordRef: RecordRef;
        MediaDescription: Text;
        IsHandled: Boolean;
    begin
        ParentRecordRef.GetTable(ParentRecord);

        case ParentRecordRef.Number of
            DATABASE::Item:
                begin
                    ParentRecordRef.SetTable(Item);
                    MediaDescription := StrSubstNo(MediaExtensionWithNumNameTxt, Item."No.", Item.Description, GetDefaultExtension());
                end;
            DATABASE::Customer:
                begin
                    ParentRecordRef.SetTable(Customer);
                    MediaDescription := StrSubstNo(MediaExtensionWithNumNameTxt, Customer."No.", Customer.Name, GetDefaultExtension());
                end;
            DATABASE::Vendor:
                begin
                    ParentRecordRef.SetTable(Vendor);
                    MediaDescription := StrSubstNo(MediaExtensionWithNumNameTxt, Vendor."No.", Vendor.Name, GetDefaultExtension());
                end;
            DATABASE::Employee:
                begin
                    ParentRecordRef.SetTable(Employee);
                    MediaDescription :=
                      StrSubstNo(MediaExtensionWithNumFullNameTxt, Employee."No.", Employee."First Name", Employee."Last Name", GetDefaultExtension());
                end;
            DATABASE::Contact:
                begin
                    ParentRecordRef.SetTable(Contact);
                    MediaDescription := StrSubstNo(MediaExtensionWithNumNameTxt, Contact."No.", Contact.Name, GetDefaultExtension());
                end;
            else begin
                IsHandled := false;
                OnGetDefaultMediaDescriptionElseCase(ParentRecordRef, MediaDescription, IsHandled);
                if not IsHandled then
                    exit('');
            end;
        end;

        exit(MediaDescription);
    end;

    procedure GetDefaultExtension(): Text
    begin
        exit('jpg');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordRefFromFilter(IDFilter: Text; var ParentRecordRef: RecordRef; var RecordFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletePictureElseCase(ParentRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultMediaDescriptionElseCase(ParentRecordRef: RecordRef; var MediaDescription: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMediaIDElseCase(ParentRecordRef: RecordRef; var MediaID: Guid; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSavePictureElseCase(ParentRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;
}

