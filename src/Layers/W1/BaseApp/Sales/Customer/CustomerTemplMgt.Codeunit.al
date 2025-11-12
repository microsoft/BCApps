// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;
using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 1381 "Customer Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        UpdateExistingValuesQst: Label 'You are about to apply the template to selected records. Data from the template will replace data for the records in fields that do not already contain data. Do you want to continue?';
        OpenBlankCardQst: Label 'Do you want to open the blank customer card?';

    procedure CreateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean; CustomerTemplCode: Code[20]) Result: Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromTemplate(Customer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        IsHandled := true;

        if CustomerTemplCode = '' then begin
            if not SelectCustomerTemplate(CustomerTempl) then
                exit(false);
        end
        else
            CustomerTempl.Get(CustomerTemplCode);

        Customer.SetInsertFromTemplate(true);
        Customer.Init();
        OnCreateCustomerFromTemplateOnBeforeInitCustomerNo(Customer);
        InitCustomerNo(Customer, CustomerTempl);
        Customer."Contact Type" := CustomerTempl."Contact Type";
        Customer.Insert(true);
        Customer.SetInsertFromTemplate(false);

        ApplyCustomerTemplate(Customer, CustomerTempl);

        OnAfterCreateCustomerFromTemplate(Customer, CustomerTempl);
        exit(true);
    end;

    procedure CreateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean): Boolean
    begin
        exit(CreateCustomerFromTemplate(Customer, IsHandled, ''));
    end;

    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        ApplyCustomerTemplate(Customer, CustomerTempl, false);
    end;

    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    begin
        ApplyTemplate(Customer, CustomerTempl, UpdateExistingValues);
        InsertDimensions(Customer."No.", CustomerTempl.Code, Database::Customer, Database::"Customer Templ.");
        Customer.Get(Customer."No.");

        OnAfterApplyCustomerTemplate(Customer, CustomerTempl);
    end;

    procedure ApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    var
        CustomerRecRef: RecordRef;
        EmptyCustomerRecRef: RecordRef;
        CustomerTemplRecRef: RecordRef;
        EmptyCustomerTemplRecRef: RecordRef;
        CustomerFldRef: FieldRef;
        EmptyCustomerFldRef: FieldRef;
        CustomerTemplFldRef: FieldRef;
        EmptyCustomerTemplFldRef: FieldRef;
        IsHandled: Boolean;
        i: Integer;
        FieldExclusionList: List of [Integer];
    begin
        IsHandled := false;
        OnBeforeApplyTemplate(Customer, CustomerTempl, IsHandled, UpdateExistingValues);
        if IsHandled then
            exit;

        CustomerRecRef.GetTable(Customer);
        EmptyCustomerRecRef.Open(Database::Customer);
        EmptyCustomerRecRef.Init();
        CustomerTemplRecRef.GetTable(CustomerTempl);
        EmptyCustomerTemplRecRef.Open(Database::"Customer Templ.");
        EmptyCustomerTemplRecRef.Init();

        FillFieldExclusionList(FieldExclusionList);

        for i := 3 to CustomerTemplRecRef.FieldCount do begin
            CustomerTemplFldRef := CustomerTemplRecRef.FieldIndex(i);
            if TemplateFieldCanBeProcessed(CustomerTemplFldRef.Number, FieldExclusionList) then begin
                CustomerFldRef := CustomerRecRef.Field(CustomerTemplFldRef.Number);
                EmptyCustomerFldRef := EmptyCustomerRecRef.Field(CustomerTemplFldRef.Number);
                EmptyCustomerTemplFldRef := EmptyCustomerTemplRecRef.Field(CustomerTemplFldRef.Number);
                if (not UpdateExistingValues and (CustomerFldRef.Value = EmptyCustomerFldRef.Value) and (CustomerTemplFldRef.Value <> EmptyCustomerTemplFldRef.Value)) or
                   (UpdateExistingValues and (CustomerTemplFldRef.Value <> EmptyCustomerTemplFldRef.Value))
                then
                    CustomerFldRef.Value := CustomerTemplFldRef.Value();
            end;
        end;
        CustomerRecRef.SetTable(Customer);
        if CustomerTempl."Invoice Disc. Code" <> '' then
            Customer."Invoice Disc. Code" := CustomerTempl."Invoice Disc. Code";
        Customer.Validate("Payment Method Code", CustomerTempl."Payment Method Code");
        OnApplyTemplateOnBeforeCustomerModify(Customer, CustomerTempl, UpdateExistingValues);
        Customer.Modify(true);
    end;

    procedure SelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact): Boolean
    begin
        OnBeforeSelectCustomerTemplateFromContact(CustomerTempl, Contact);

        CustomerTempl.SetRange("Contact Type", Contact.Type);
        exit(SelectCustomerTemplate(CustomerTempl));
    end;

    procedure SelectCustomerTemplate(var CustomerTempl: Record "Customer Templ.") Result: Boolean
    var
        SelectCustomerTemplList: Page "Select Customer Templ. List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectCustomerTemplate(CustomerTempl, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CustomerTempl.Count = 1 then begin
            CustomerTempl.FindFirst();
            exit(true);
        end;

        if (CustomerTempl.Count > 1) and GuiAllowed then begin
            SelectCustomerTemplList.SetTableView(CustomerTempl);
            SelectCustomerTemplList.LookupMode(true);
            if SelectCustomerTemplList.RunModal() = Action::LookupOK then begin
                SelectCustomerTemplList.GetRecord(CustomerTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(DestNo: Code[20]; SourceNo: Code[20]; DestTableId: Integer; SourceTableId: Integer)
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", SourceTableId);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", DestTableId);
                DestDefaultDimension.Validate("No.", DestNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if (DestDefaultDimension."Value Posting" = DestDefaultDimension."Value Posting"::"Code Mandatory")
                and (SourceDefaultDimension."Allowed Values Filter" <> '') then
                    DestDefaultDimension.Validate("Allowed Values Filter", SourceDefaultDimension."Allowed Values Filter");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure CustomerTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        CustomerTempl: Record "Customer Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not CustomerTempl.IsEmpty);
    end;

    procedure InsertCustomerFromTemplate(var Customer: Record Customer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertCustomerFromTemplate(Customer, Result, IsHandled);
    end;

    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnTemplatesAreNotEmpty(Result, IsHandled);
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    procedure UpdateCustomerFromTemplate(var Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnUpdateCustomerFromTemplate(Customer, IsHandled);
    end;

    local procedure UpdateFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateFromTemplate(Customer, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(CustomerTempl, IsHandled) then
            exit;

        if not GetUpdateExistingValuesParam() then
            exit;

        ApplyCustomerTemplate(Customer, CustomerTempl, true);
    end;

    procedure UpdateCustomersFromTemplate(var Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnUpdateCustomersFromTemplate(Customer, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateMultipleFromTemplate(Customer, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(CustomerTempl, IsHandled) then
            exit;

        if Customer.FindSet() then
            repeat
                ApplyCustomerTemplate(Customer, CustomerTempl, GetUpdateExistingValuesParam());
            until Customer.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean): Boolean
    begin
        IsHandled := true;

        if not SelectCustomerTemplate(CustomerTempl) then
            exit(false);

        exit(true);
    end;

    procedure SaveAsTemplate(Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnSaveAsTemplate(Customer, IsHandled);
    end;

    procedure CreateTemplateFromCustomer(Customer: Record Customer; var IsHandled: Boolean)
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateTemplateFromCustomer(Customer, IsHandled);
        if IsHandled then
            exit;

        IsHandled := true;

        InsertTemplateFromCustomer(CustomerTempl, Customer);
        InsertDimensions(CustomerTempl.Code, Customer."No.", Database::"Customer Templ.", Database::Customer);
        OnCreateTemplateFromCustomerOnAfterInsertTemplateFromCustomer(CustomerTempl, Customer);
        CustomerTempl.Get(CustomerTempl.Code);
        ShowCustomerTemplCard(CustomerTempl);
    end;

    local procedure InsertTemplateFromCustomer(var CustomerTempl: Record "Customer Templ."; Customer: Record Customer)
    var
        SavedCustomerTempl: Record "Customer Templ.";
    begin
        CustomerTempl.Init();
        CustomerTempl.Code := GetCustomerTemplCode();
        SavedCustomerTempl := CustomerTempl;
        CustomerTempl.TransferFields(Customer);
        CustomerTempl.Code := SavedCustomerTempl.Code;
        CustomerTempl.Description := SavedCustomerTempl.Description;
        CustomerTempl.Insert();
    end;

    local procedure GetCustomerTemplCode() CustomerTemplCode: Code[20]
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
    begin
        if CustomerTempl.FindLast() and (IncStr(CustomerTempl.Code) <> '') then
            CustomerTemplCode := CustomerTempl.Code
        else
            CustomerTemplCode := CopyStr(Customer.TableCaption(), 1, 4) + '000001';

        while CustomerTempl.Get(CustomerTemplCode) do
            CustomerTemplCode := IncStr(CustomerTemplCode);
    end;

    local procedure ShowCustomerTemplCard(CustomerTempl: Record "Customer Templ.")
    var
        CustomerTemplCard: Page "Customer Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        CustomerTemplCard.SetRecord(CustomerTempl);
        CustomerTemplCard.LookupMode := true;
        if CustomerTemplCard.RunModal() = Action::LookupCancel then begin
            CustomerTempl.Get(CustomerTempl.Code);
            CustomerTempl.Delete(true);
        end;
    end;

    procedure ShowTemplates()
    var
        IsHandled: Boolean;
    begin
        OnShowTemplates(IsHandled);
    end;

    local procedure ShowCustomerTemplList(var IsHandled: Boolean)
    begin
        IsHandled := true;
        Page.Run(Page::"Customer Templ. List");
    end;

    procedure InitCustomerNo(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    var
        NoSeries: Codeunit "No. Series";
    begin
        if CustomerTempl."No. Series" = '' then
            exit;

        Customer."No. Series" := CustomerTempl."No. Series";
        if Customer."No." <> '' then begin
            NoSeries.TestManual(Customer."No. Series");
            exit;
        end;

        NoSeries.TestAutomatic(Customer."No. Series");
        Customer."No." := NoSeries.GetNextNo(Customer."No. Series");
    end;

    local procedure TemplateFieldCanBeProcessed(FieldNumber: Integer; FieldExclusionList: List of [Integer]): Boolean
    var
        CustomerField: Record Field;
        CustomerTemplateField: Record Field;
    begin
        if FieldExclusionList.Contains(FieldNumber) or (FieldNumber > 2000000000) then
            exit(false);

        if not (CustomerField.Get(Database::Customer, FieldNumber) and CustomerTemplateField.Get(Database::"Customer Templ.", FieldNumber)) then
            exit(false);

        if (CustomerField.Class <> CustomerField.Class::Normal) or (CustomerTemplateField.Class <> CustomerTemplateField.Class::Normal) or
            (CustomerField.Type <> CustomerTemplateField.Type) or (CustomerField.FieldName <> CustomerTemplateField.FieldName) or
            (CustomerField.Len <> CustomerTemplateField.Len) or
            (CustomerField.ObsoleteState = CustomerField.ObsoleteState::Removed) or
            (CustomerTemplateField.ObsoleteState = CustomerTemplateField.ObsoleteState::Removed)
        then
            exit(false);

        exit(true);
    end;

    local procedure FillFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        FieldExclusionList.Add(CustomerTempl.FieldNo("Invoice Disc. Code"));
        FieldExclusionList.Add(CustomerTempl.FieldNo("No. Series"));
        FieldExclusionList.Add(CustomerTempl.FieldNo("Payment Method Code"));

        OnAfterFillFieldExclusionList(FieldExclusionList);
    end;

    local procedure GetUpdateExistingValuesParam() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUpdateExistingValuesParam(Result, IsHandled);
        if not IsHandled then
            Result := ConfirmManagement.GetResponseOrDefault(UpdateExistingValuesQst, false);
    end;

    procedure IsOpenBlankCardConfirmed() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenBlankCardConfirmed(Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ConfirmManagement.GetResponse(OpenBlankCardQst, false));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeCustomerModify(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean; UpdateExistingValues: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCustomerFromTemplate(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomersFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomerFromTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustomerTemplate(var CustomerTempl: Record "Customer Templ."; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromTemplate(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromCustomer(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnInsertCustomerFromTemplate', '', false, false)]
    local procedure OnInsertCustomerFromTemplateHandler(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateCustomerFromTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyHandler(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CustomerTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnUpdateCustomerFromTemplate', '', false, false)]
    local procedure OnUpdateCustomerFromTemplateHandler(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateFromTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnUpdateCustomersFromTemplate', '', false, false)]
    local procedure OnUpdateCustomersFromTemplateHandler(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnSaveAsTemplate', '', false, false)]
    local procedure OnSaveAsTemplateHandler(Customer: Record Customer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        CreateTemplateFromCustomer(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnShowTemplates', '', false, false)]
    local procedure OnShowTemplatesHandler(var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        ShowCustomerTemplList(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateExistingValuesParam(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenBlankCardConfirmed(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerFromTemplateOnBeforeInitCustomerNo(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTemplateFromCustomerOnAfterInsertTemplateFromCustomer(var CustomerTempl: Record "Customer Templ."; Customer: Record Customer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Template Management", 'OnBeforeInsertRecordWithKeyFields', '', false, false)]
    local procedure OnBeforeInsertRecordWithKeyFieldsHandler(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    begin
        FillCustomerKeyFromInitSeries(RecRef, ConfigTemplateHeader);
    end;

    procedure FillCustomerKeyFromInitSeries(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    var
        Customer: Record Customer;
        NoSeries: Codeunit "No. Series";
        FldRef: FieldRef;
    begin
        if RecRef.Number = Database::Customer then begin
            if ConfigTemplateHeader."Instance No. Series" = '' then
                exit;

            NoSeries.TestAutomatic(ConfigTemplateHeader."Instance No. Series");

            FldRef := RecRef.Field(Customer.FieldNo("No."));
            FldRef.Value := NoSeries.GetNextNo(ConfigTemplateHeader."Instance No. Series");
            FldRef := RecRef.Field(Customer.FieldNo("No. Series"));
            FldRef.Value := ConfigTemplateHeader."Instance No. Series";
        end;
    end;
}
