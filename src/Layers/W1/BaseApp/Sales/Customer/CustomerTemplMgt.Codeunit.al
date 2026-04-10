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

/// <summary>
/// Manages customer templates including creation, application, and selection for new customers.
/// </summary>
codeunit 1381 "Customer Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        UpdateExistingValuesQst: Label 'You are about to apply the template to selected records. Data from the template will replace data for the records in fields that do not already contain data. Do you want to continue?';
        OpenBlankCardQst: Label 'Do you want to open the blank customer card?';

    /// <summary>
    /// Creates a new customer record based on the specified customer template.
    /// </summary>
    /// <param name="Customer">Returns the newly created customer record.</param>
    /// <param name="IsHandled">Returns whether the creation was handled by this procedure.</param>
    /// <param name="CustomerTemplCode">Specifies the customer template code to use for creation.</param>
    /// <returns>True if the customer was created successfully, otherwise false.</returns>
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

    /// <summary>
    /// Creates a new customer record by prompting the user to select a customer template.
    /// </summary>
    /// <param name="Customer">Returns the newly created customer record.</param>
    /// <param name="IsHandled">Returns whether the creation was handled by this procedure.</param>
    /// <returns>True if the customer was created successfully, otherwise false.</returns>
    procedure CreateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean): Boolean
    begin
        exit(CreateCustomerFromTemplate(Customer, IsHandled, ''));
    end;

    /// <summary>
    /// Applies a customer template to an existing customer record without updating existing values.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to apply the template to.</param>
    /// <param name="CustomerTempl">Specifies the customer template to apply.</param>
    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        ApplyCustomerTemplate(Customer, CustomerTempl, false);
    end;

    /// <summary>
    /// Applies a customer template to an existing customer record with option to update existing values.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to apply the template to.</param>
    /// <param name="CustomerTempl">Specifies the customer template to apply.</param>
    /// <param name="UpdateExistingValues">Specifies whether to overwrite existing field values with template values.</param>
    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    begin
        ApplyTemplate(Customer, CustomerTempl, UpdateExistingValues);
        InsertDimensions(Customer."No.", CustomerTempl.Code, Database::Customer, Database::"Customer Templ.");
        Customer.Get(Customer."No.");

        OnAfterApplyCustomerTemplate(Customer, CustomerTempl);
    end;

    /// <summary>
    /// Applies template field values to a customer record by comparing and transferring non-empty template values.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to update with template values.</param>
    /// <param name="CustomerTempl">Specifies the customer template containing the values to apply.</param>
    /// <param name="UpdateExistingValues">Specifies whether to overwrite existing field values with template values.</param>
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

    /// <summary>
    /// Selects a customer template filtered by the contact type from the specified contact record.
    /// </summary>
    /// <param name="CustomerTempl">Returns the selected customer template record.</param>
    /// <param name="Contact">Specifies the contact record used to filter available templates by contact type.</param>
    /// <returns>True if a template was selected, otherwise false.</returns>
    procedure SelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact): Boolean
    begin
        OnBeforeSelectCustomerTemplateFromContact(CustomerTempl, Contact);

        CustomerTempl.SetRange("Contact Type", Contact.Type);
        exit(SelectCustomerTemplate(CustomerTempl));
    end;

    /// <summary>
    /// Prompts the user to select a customer template from available templates.
    /// </summary>
    /// <param name="CustomerTempl">Returns the selected customer template record.</param>
    /// <returns>True if a template was selected, otherwise false.</returns>
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

    /// <summary>
    /// Checks if any customer templates exist and if the template feature is enabled.
    /// </summary>
    /// <param name="IsHandled">Returns true if this procedure handled the check.</param>
    /// <returns>True if customer templates exist and the feature is enabled, otherwise false.</returns>
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

    /// <summary>
    /// Inserts a new customer from a template by raising an event for template selection and creation.
    /// </summary>
    /// <param name="Customer">Returns the newly inserted customer record.</param>
    /// <returns>True if the customer was inserted successfully, otherwise false.</returns>
    procedure InsertCustomerFromTemplate(var Customer: Record Customer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertCustomerFromTemplate(Customer, Result, IsHandled);
    end;

    /// <summary>
    /// Checks if any customer templates exist by raising an event to determine template availability.
    /// </summary>
    /// <returns>True if customer templates exist, otherwise false.</returns>
    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnTemplatesAreNotEmpty(Result, IsHandled);
    end;

    /// <summary>
    /// Checks if the customer template feature is enabled.
    /// </summary>
    /// <returns>True if the template feature is enabled, otherwise false.</returns>
    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    /// <summary>
    /// Updates an existing customer record by applying a selected template.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to update with template values.</param>
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

    /// <summary>
    /// Updates multiple customer records by applying a selected template to all records in the filter.
    /// </summary>
    /// <param name="Customer">Specifies the filtered customer records to update with template values.</param>
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

    /// <summary>
    /// Saves the specified customer record as a new customer template.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to save as a template.</param>
    procedure SaveAsTemplate(Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnSaveAsTemplate(Customer, IsHandled);
    end;

    /// <summary>
    /// Creates a new customer template based on the specified customer record.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to create the template from.</param>
    /// <param name="IsHandled">Returns whether the template creation was handled by this procedure.</param>
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

    /// <summary>
    /// Opens the Customer Template List page to display all available customer templates.
    /// </summary>
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

    /// <summary>
    /// Initializes the customer number based on the number series defined in the customer template.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to initialize the number for.</param>
    /// <param name="CustomerTempl">Specifies the customer template containing the number series configuration.</param>
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

    /// <summary>
    /// Prompts the user to confirm opening a blank customer card when no template is selected.
    /// </summary>
    /// <returns>True if the user confirms opening a blank card, otherwise false.</returns>
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

    /// <summary>
    /// Raised after checking if the customer template feature is enabled.
    /// </summary>
    /// <param name="Result">The result indicating whether templates are enabled, which can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after applying a customer template to a customer record.
    /// </summary>
    /// <param name="Customer">The customer record that received the template values.</param>
    /// <param name="CustomerTempl">The customer template that was applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
    end;

    /// <summary>
    /// Raised before modifying the customer record when applying a template.
    /// </summary>
    /// <param name="Customer">The customer record being modified.</param>
    /// <param name="CustomerTempl">The customer template being applied.</param>
    /// <param name="UpdateExistingValues">Indicates whether existing values are being overwritten.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeCustomerModify(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; UpdateExistingValues: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before applying a template to a customer record.
    /// </summary>
    /// <param name="Customer">The customer record to apply the template to.</param>
    /// <param name="CustomerTempl">The customer template to apply.</param>
    /// <param name="IsHandled">Set to true to skip the default template application.</param>
    /// <param name="UpdateExistingValues">Indicates whether to overwrite existing values.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean; UpdateExistingValues: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before selecting a customer template filtered by contact type.
    /// </summary>
    /// <param name="CustomerTempl">The customer template record to be filtered.</param>
    /// <param name="Contact">The contact record used for filtering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact)
    begin
    end;

    /// <summary>
    /// Raised when inserting a customer from a template.
    /// </summary>
    /// <param name="Customer">The customer record being created.</param>
    /// <param name="Result">Returns the result of the operation.</param>
    /// <param name="IsHandled">Set to true to indicate the operation was handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertCustomerFromTemplate(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when checking if customer templates exist.
    /// </summary>
    /// <param name="Result">Returns whether templates exist.</param>
    /// <param name="IsHandled">Set to true to indicate the check was handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when updating a customer from a template.
    /// </summary>
    /// <param name="Customer">The customer record to update.</param>
    /// <param name="IsHandled">Set to true to indicate the operation was handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when updating multiple customers from a template.
    /// </summary>
    /// <param name="Customer">The filtered customer records to update.</param>
    /// <param name="IsHandled">Set to true to indicate the operation was handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomersFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when saving a customer as a template.
    /// </summary>
    /// <param name="Customer">The customer record to save as a template.</param>
    /// <param name="IsHandled">Set to true to indicate the operation was handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when showing the customer templates list.
    /// </summary>
    /// <param name="IsHandled">Set to true to indicate the operation was handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after creating a customer from a template.
    /// </summary>
    /// <param name="Customer">The newly created customer record.</param>
    /// <param name="CustomerTempl">The customer template that was used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomerFromTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
    end;

    /// <summary>
    /// Raised before prompting the user to select a customer template.
    /// </summary>
    /// <param name="CustomerTempl">The customer template record to select from.</param>
    /// <param name="Result">Set to the result to override the selection.</param>
    /// <param name="IsHandled">Set to true to skip the default selection logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustomerTemplate(var CustomerTempl: Record "Customer Templ."; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after filling the list of fields to exclude from template application.
    /// </summary>
    /// <param name="FieldExclusionList">The list of field numbers to exclude from template processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    /// <summary>
    /// Raised before creating a customer from a template.
    /// </summary>
    /// <param name="Customer">The customer record to create.</param>
    /// <param name="Result">Set to the result to override the creation.</param>
    /// <param name="IsHandled">Set to true to skip the default creation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromTemplate(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating a customer from a template.
    /// </summary>
    /// <param name="Customer">The customer record to update.</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating multiple customers from a template.
    /// </summary>
    /// <param name="Customer">The filtered customer records to update.</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating a template from an existing customer record.
    /// </summary>
    /// <param name="Customer">The customer record to create the template from.</param>
    /// <param name="IsHandled">Set to true to skip the default template creation.</param>
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

    /// <summary>
    /// Raised before prompting for the update existing values parameter.
    /// </summary>
    /// <param name="Result">Set to the result to override the prompt.</param>
    /// <param name="IsHandled">Set to true to skip the default prompt.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateExistingValuesParam(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before prompting to confirm opening a blank customer card.
    /// </summary>
    /// <param name="Result">Set to the result to override the confirmation.</param>
    /// <param name="IsHandled">Set to true to skip the default confirmation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenBlankCardConfirmed(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before initializing the customer number when creating from a template.
    /// </summary>
    /// <param name="Customer">The customer record being created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerFromTemplateOnBeforeInitCustomerNo(var Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised after inserting a template record from a customer.
    /// </summary>
    /// <param name="CustomerTempl">The newly created customer template record.</param>
    /// <param name="Customer">The customer record that was used as the source.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateTemplateFromCustomerOnAfterInsertTemplateFromCustomer(var CustomerTempl: Record "Customer Templ."; Customer: Record Customer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Template Management", 'OnBeforeInsertRecordWithKeyFields', '', false, false)]
    local procedure OnBeforeInsertRecordWithKeyFieldsHandler(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    begin
        FillCustomerKeyFromInitSeries(RecRef, ConfigTemplateHeader);
    end;

    /// <summary>
    /// Fills the customer number field from the configuration template number series.
    /// </summary>
    /// <param name="RecRef">Specifies the record reference to the customer record being created.</param>
    /// <param name="ConfigTemplateHeader">Specifies the configuration template containing the number series.</param>
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
