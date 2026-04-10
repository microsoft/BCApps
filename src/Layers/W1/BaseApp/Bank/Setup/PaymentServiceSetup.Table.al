// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.IO;
using System.Reflection;

/// <summary>
/// Configures external payment service providers for online payment processing.
/// Manages integration settings for services like PayPal, Microsoft Wallet, and WorldPay.
/// </summary>
/// <remarks>
/// Supports multiple payment providers with individual configuration and enable/disable control.
/// Integrates with sales documents to offer payment options to customers.
/// Extensible through OnCanChangePaymentService and related integration events.
/// </remarks>
table 1060 "Payment Service Setup"
{
    Caption = 'Payment Service Setup';
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Payment Reporting Argument" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the payment service configuration.
        /// </summary>
        field(1; "No."; Text[250])
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Display name of the payment service provider.
        /// Shown to users in payment selection interfaces.
        /// </summary>
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the payment service.';
            NotBlank = true;
        }
        /// <summary>
        /// Detailed description of the payment service and its capabilities.
        /// Provides additional information about the payment provider to users.
        /// </summary>
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the payment service.';
            NotBlank = true;
        }
        /// <summary>
        /// Controls whether this payment service is active and available for use.
        /// When disabled, the service will not appear in payment options.
        /// </summary>
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies that the payment service is enabled.';
        }
        /// <summary>
        /// Determines if this payment service should be included on all sales documents by default.
        /// When enabled, automatically adds this service to new and existing invoices.
        /// </summary>
        field(5; "Always Include on Documents"; Boolean)
        {
            Caption = 'Always Include on Documents';
            ToolTip = 'Specifies that the payment service is always available in the Payment Service field on outgoing sales documents.';

            trigger OnValidate()
            var
                SalesHeader: Record "Sales Header";
            begin
                if Confirm(UpdateExistingInvoicesQst) then begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    if SalesHeader.FindSet(true) then
                        repeat
                            SalesHeader.SetDefaultPaymentServices();
                            SalesHeader.Modify();
                        until SalesHeader.Next() = 0;
                end;
            end;
        }
        /// <summary>
        /// Record ID pointing to the specific setup record for this payment service.
        /// Links to provider-specific configuration tables.
        /// </summary>
        field(6; "Setup Record ID"; RecordID)
        {
            Caption = 'Setup Record ID';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Page ID for the payment service setup configuration page.
        /// Allows users to access provider-specific setup options.
        /// </summary>
        field(7; "Setup Page ID"; Integer)
        {
            Caption = 'Setup Page ID';
        }
        /// <summary>
        /// URL link to the payment service provider's terms of service.
        /// Provides legal and usage information for the payment service.
        /// </summary>
        field(8; "Terms of Service"; Text[250])
        {
            Caption = 'Terms of Service';
            ToolTip = 'Specifies a link to the Terms of Service page for the payment service.';
            Editable = false;
            ExtendedDatatype = URL;
        }
        /// <summary>
        /// Indicates whether the payment service is currently available for use.
        /// May be controlled by system conditions or external service status.
        /// </summary>
        field(100; Available; Boolean)
        {
            Caption = 'Available';
            ToolTip = 'Specifies that the icon and link to the payment service will be inserted on the outgoing sales document.';
        }
        /// <summary>
        /// Codeunit ID that handles the business logic for this payment service.
        /// Contains provider-specific implementation for payment processing.
        /// </summary>
        field(101; "Management Codeunit ID"; Integer)
        {
            Caption = 'Management Codeunit ID';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePaymentServiceSetup(true);
    end;

    var
        NoPaymentMethodsSelectedTxt: Label 'No payment service is made available.';
        SetupPaymentServicesQst: Label 'No payment services have been set up.\\Do you want to set up a payment service?';
        SetupExistingServicesOrCreateNewQst: Label 'One or more payment services are set up, but none are enabled.\\Do you want to:';
        CreateOrUpdateOptionQst: Label 'Set Up a Payment Service,Create a New Payment Service';
        UpdateExistingInvoicesQst: Label 'Do you want to update the ongoing Sales Invoices with this Payment Service information?';
        ReminderToSendAgainMsg: Label 'The payment service was successfully changed.\\The invoice recipient will see the change when you send, or resend, the invoice.';

    /// <summary>
    /// Opens the setup card page for this payment service configuration.
    /// Allows users to modify provider-specific settings and parameters.
    /// </summary>
    procedure OpenSetupCard()
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SetupRecordRef: RecordRef;
        SetupRecordVariant: Variant;
    begin
        if not DataTypeManagement.GetRecordRef("Setup Record ID", SetupRecordRef) then
            exit;

        SetupRecordVariant := SetupRecordRef;
        PAGE.RunModal("Setup Page ID", SetupRecordVariant);
    end;

    /// <summary>
    /// Creates payment reporting arguments for a specific document and its associated payment services.
    /// Generates the data needed for payment provider integration and customer communication.
    /// </summary>
    /// <param name="PaymentReportingArgument">Temporary table to populate with payment service arguments</param>
    /// <param name="DocumentRecordVariant">Source document record (typically Sales Header or Invoice)</param>
    procedure CreateReportingArgs(var PaymentReportingArgument: Record "Payment Reporting Argument"; DocumentRecordVariant: Variant)
    var
        DummySalesHeader: Record "Sales Header";
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        DataTypeMgt: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        PaymentServiceFieldRef: FieldRef;
        SetID: Integer;
        LastKey: Integer;
    begin
        PaymentReportingArgument.Reset();
        PaymentReportingArgument.DeleteAll();

        DataTypeMgt.GetRecordRef(DocumentRecordVariant, DocumentRecordRef);
        DataTypeMgt.FindFieldByName(DocumentRecordRef, PaymentServiceFieldRef, DummySalesHeader.FieldName("Payment Service Set ID"));

        SetID := PaymentServiceFieldRef.Value();

        GetEnabledPaymentServices(TempPaymentServiceSetup);
        LoadSet(TempPaymentServiceSetup, SetID);
        TempPaymentServiceSetup.SetRange(Available, true);

        if not TempPaymentServiceSetup.FindFirst() then
            exit;

        repeat
            LastKey := PaymentReportingArgument.Key;
            Clear(PaymentReportingArgument);
            PaymentReportingArgument.Key := LastKey + 1;
            PaymentReportingArgument.Validate("Document Record ID", DocumentRecordRef.RecordId);
            PaymentReportingArgument.Validate("Setup Record ID", TempPaymentServiceSetup."Setup Record ID");
            PaymentReportingArgument.Insert(true);
            CODEUNIT.Run(TempPaymentServiceSetup."Management Codeunit ID", PaymentReportingArgument);
        until TempPaymentServiceSetup.Next() = 0;
    end;

    /// <summary>
    /// Retrieves payment services configured to be always included on documents.
    /// Returns a set ID for enabled payment services that are set to be included by default.
    /// </summary>
    /// <param name="SetID">Output parameter containing the set ID for default payment services</param>
    /// <returns>True if default payment services were found, false otherwise</returns>
    procedure GetDefaultPaymentServices(var SetID: Integer): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
    begin
        OnRegisterPaymentServices(TempPaymentServiceSetup);
        TempPaymentServiceSetup.SetRange("Always Include on Documents", true);
        TempPaymentServiceSetup.SetRange(Enabled, true);

        if not TempPaymentServiceSetup.FindFirst() then
            exit(false);

        TransferToRecordSetBuffer(TempPaymentServiceSetup, TempRecordSetBuffer);
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);
        if SetID = 0 then
            SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        exit(true);
    end;

    /// <summary>
    /// Presents payment service selection dialog to user and returns the selected set ID.
    /// Handles the complete workflow for selecting payment services including setup prompts.
    /// </summary>
    /// <param name="SetID">Input/output parameter for the payment service set ID</param>
    /// <returns>True if user selected payment services, false if cancelled</returns>
    procedure SelectPaymentService(var SetID: Integer): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        if not GetEnabledPaymentServices(TempPaymentServiceSetup) then begin
            if not AskUserToSetupNewPaymentService(TempPaymentServiceSetup) then
                exit(false);

            // If user has setup the service then just select that one
            if TempPaymentServiceSetup.Count = 1 then begin
                TempPaymentServiceSetup.FindFirst();
                SetID := SaveSet(TempPaymentServiceSetup);
                exit(true);
            end;
        end;

        if SetID <> 0 then
            LoadSet(TempPaymentServiceSetup, SetID);

        TempPaymentServiceSetup.Reset();
        TempPaymentServiceSetup.SetRange(Enabled, true);

        if not (PAGE.RunModal(PAGE::"Select Payment Service", TempPaymentServiceSetup) = ACTION::LookupOK) then
            exit(false);

        TempPaymentServiceSetup.SetRange(Available, true);
        if TempPaymentServiceSetup.FindFirst() then
            SetID := SaveSet(TempPaymentServiceSetup)
        else
            Clear(SetID);

        exit(true);
    end;

    local procedure GetEnabledPaymentServices(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Boolean
    begin
        TempPaymentServiceSetup.Reset();
        TempPaymentServiceSetup.DeleteAll();
        OnRegisterPaymentServices(TempPaymentServiceSetup);
        TempPaymentServiceSetup.SetRange(Enabled, true);
        exit(TempPaymentServiceSetup.FindSet());
    end;

    local procedure TransferToRecordSetBuffer(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; var TempRecordSetBuffer: Record "Record Set Buffer" temporary)
    var
        CurrentKey: Integer;
    begin
        TempPaymentServiceSetup.FindFirst();

        repeat
            CurrentKey := TempRecordSetBuffer.No;
            Clear(TempRecordSetBuffer);
            TempRecordSetBuffer.No := CurrentKey + 1;
            TempRecordSetBuffer."Value RecordID" := TempPaymentServiceSetup."Setup Record ID";
            TempRecordSetBuffer.Insert();
        until TempPaymentServiceSetup.Next() = 0;
    end;

    /// <summary>
    /// Saves a temporary payment service setup collection as a persistent set.
    /// Converts temporary payment service records into a record set that can be referenced by ID.
    /// </summary>
    /// <param name="TempPaymentServiceSetup">Temporary payment service setup records to save as a set</param>
    /// <returns>Set ID for the saved payment service collection</returns>
    procedure SaveSet(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Integer
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
    begin
        TransferToRecordSetBuffer(TempPaymentServiceSetup, TempRecordSetBuffer);
        exit(RecordSetManagement.SaveSet(TempRecordSetBuffer));
    end;

    /// <summary>
    /// Loads a payment service set into temporary records based on the provided set ID.
    /// Marks payment services as available based on their inclusion in the specified set.
    /// </summary>
    /// <param name="TempPaymentServiceSetup">Temporary payment service setup records to load into</param>
    /// <param name="SetID">Set ID identifying which payment services to load</param>
    procedure LoadSet(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; SetID: Integer)
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
    begin
        if not TempPaymentServiceSetup.FindFirst() then
            exit;

        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        if not TempRecordSetBuffer.FindFirst() then begin
            TempPaymentServiceSetup.ModifyAll(Available, false);
            exit;
        end;

        repeat
            TempRecordSetBuffer.SetRange("Value RecordID", TempPaymentServiceSetup."Setup Record ID");
            if TempRecordSetBuffer.FindFirst() then begin
                TempPaymentServiceSetup.Available := true;
                TempPaymentServiceSetup.Modify();
            end;
        until TempPaymentServiceSetup.Next() = 0;
    end;

    /// <summary>
    /// Returns a comma-separated text string of selected payment service names.
    /// Provides user-friendly display of payment services included in a set.
    /// </summary>
    /// <param name="SetID">Set ID identifying which payment services to include in text</param>
    /// <returns>Comma-separated list of payment service names, or 'No payment service is made available' if none selected</returns>
    procedure GetSelectedPaymentsText(SetID: Integer) SelectedPaymentServices: Text
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        SelectedPaymentServices := NoPaymentMethodsSelectedTxt;

        if SetID = 0 then
            exit;

        OnRegisterPaymentServices(TempPaymentServiceSetup);
        LoadSet(TempPaymentServiceSetup, SetID);

        TempPaymentServiceSetup.SetRange(Available, true);
        if not TempPaymentServiceSetup.FindSet() then
            exit;

        Clear(SelectedPaymentServices);
        repeat
            SelectedPaymentServices += StrSubstNo(',%1', TempPaymentServiceSetup.Name);
        until TempPaymentServiceSetup.Next() = 0;

        SelectedPaymentServices := CopyStr(SelectedPaymentServices, 2);
    end;

    /// <summary>
    /// Determines if payment service configuration can be changed for a given document.
    /// Validates document status and payment method compatibility for payment service modifications.
    /// </summary>
    /// <param name="DocumentVariant">Document record to check for payment service change eligibility</param>
    /// <returns>True if payment service can be changed, false if document is closed or incompatible</returns>
    procedure CanChangePaymentService(DocumentVariant: Variant) Result: Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        PaymentMethodCodeFieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        DataTypeManagement.GetRecordRef(DocumentVariant, DocumentRecordRef);
        IsHandled := false;
        OnCanChangePaymentServiceOnAfterGetRecordRef(DocumentVariant, DocumentRecordRef, Result, IsHandled);
        if IsHandled then
            exit(Result);
        case DocumentRecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Copy(DocumentVariant);
                    SalesInvoiceHeader.CalcFields(Closed, "Remaining Amount");
                    if SalesInvoiceHeader.Closed or (SalesInvoiceHeader."Remaining Amount" = 0) then
                        exit(false);
                end
            else
                if DataTypeManagement.FindFieldByName(
                        DocumentRecordRef, PaymentMethodCodeFieldRef, SalesInvoiceHeader.FieldName("Payment Method Code"))
                then
                    if not CanUsePaymentMethod(Format(PaymentMethodCodeFieldRef.Value)) then
                        exit(false);
        end;

        exit(true);
    end;

    local procedure CanUsePaymentMethod(PaymentMethodCode: Code[10]) Result: Boolean
    var
        PaymentMethod: Record "Payment Method";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanUsePaymentMethod(PaymentMethodCode, Result, IsHandled);
        if IsHandled then
            exit;

        if not PaymentMethod.Get(PaymentMethodCode) then
            exit(true);

        exit(PaymentMethod."Bal. Account No." = '');
    end;

    /// <summary>
    /// Enables changing payment service configuration for a posted sales invoice.
    /// Updates the payment service set ID on the posted invoice and provides user feedback.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Posted sales invoice header to update with new payment service</param>
    procedure ChangePaymentServicePostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        SetID := SalesInvoiceHeader."Payment Service Set ID";
        if PaymentServiceSetup.SelectPaymentService(SetID) then begin
            SalesInvoiceHeader.Validate("Payment Service Set ID", SetID);
            SalesInvoiceHeader.Modify(true);
            if GuiAllowed and (Format(SalesInvoiceHeader."Payment Service Set ID") <> '') then
                Message(ReminderToSendAgainMsg);
        end;
    end;

    local procedure AskUserToSetupNewPaymentService(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Boolean
    var
        TempNotEnabledPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
        SetupOrCreatePaymentService: Option ,"Setup Payment Services","Create New";
        SelectedOption: Integer;
        DefinedPaymentServiceExist: Boolean;
    begin
        if not GuiAllowed then
            exit(false);

        OnRegisterPaymentServiceProviders(TempPaymentServiceSetupProviders);
        if not TempPaymentServiceSetupProviders.FindFirst() then
            exit(false);

        // Check if there are payment services that are not enabled
        OnRegisterPaymentServices(TempNotEnabledPaymentServiceSetupProviders);
        DefinedPaymentServiceExist := TempNotEnabledPaymentServiceSetupProviders.FindFirst();

        if DefinedPaymentServiceExist then begin
            SelectedOption := StrMenu(CreateOrUpdateOptionQst, 1, SetupExistingServicesOrCreateNewQst);
            case SelectedOption of
                SetupOrCreatePaymentService::"Setup Payment Services":
                    PAGE.RunModal(PAGE::"Payment Services");
                SetupOrCreatePaymentService::"Create New":
                    NewPaymentService();
                else
                    exit(false);
            end;
            exit(GetEnabledPaymentServices(TempPaymentServiceSetup));
        end;

        // Ask to create a new service
        if Confirm(SetupPaymentServicesQst) then begin
            NewPaymentService();
            exit(GetEnabledPaymentServices(TempPaymentServiceSetup));
        end;

        exit(false);
    end;

    /// <summary>
    /// Checks if payment services are available for display in user interfaces.
    /// Determines visibility of payment service functionality based on registered providers.
    /// </summary>
    /// <returns>True if payment service providers are registered and should be visible, false otherwise</returns>
    procedure IsPaymentServiceVisible(): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        exit(not TempPaymentServiceSetup.IsEmpty);
    end;

    /// <summary>
    /// Initiates creation of a new payment service through the setup workflow.
    /// Handles provider selection and setup dialog presentation to the user.
    /// </summary>
    /// <returns>True if payment service was successfully created, false if cancelled or failed</returns>
    procedure NewPaymentService(): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
    begin
        OnRegisterPaymentServiceProviders(TempPaymentServiceSetupProviders);
        case TempPaymentServiceSetupProviders.Count of
            0:
                exit(false);
            1:
                begin
                    TempPaymentServiceSetupProviders.FindFirst();
                    OnCreatePaymentService(TempPaymentServiceSetupProviders);
                    exit(true);
                end;
            else begin
                Commit();
                if PAGE.RunModal(PAGE::"Select Payment Service Type", TempPaymentServiceSetup) = ACTION::LookupOK then begin
                    OnCreatePaymentService(TempPaymentServiceSetup);
                    exit(true);
                end;
                exit(false);
            end;
        end;
    end;

    /// <summary>
    /// Assigns the primary key for a payment service setup record based on its setup record ID.
    /// Ensures unique identification of payment service configurations.
    /// </summary>
    /// <param name="PaymentServiceSetup">Payment service setup record to assign primary key to</param>
    procedure AssignPrimaryKey(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
        PaymentServiceSetup."No." := Format(PaymentServiceSetup."Setup Record ID");
    end;

    /// <summary>
    /// Deletes the underlying payment service setup record referenced by the Setup Record ID.
    /// Performs cleanup of related configuration data when removing payment services.
    /// </summary>
    /// <param name="RunTrigger">Whether to execute delete triggers on the referenced setup record</param>
    procedure DeletePaymentServiceSetup(RunTrigger: Boolean)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SetupRecordRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef("Setup Record ID", SetupRecordRef);
        SetupRecordRef.Delete(RunTrigger);
    end;

    /// <summary>
    /// Opens the Terms of Service URL in the default browser or application.
    /// Enables users to review payment service provider terms and conditions.
    /// </summary>
    procedure TermsOfServiceDrillDown()
    begin
        if "Terms of Service" <> '' then
            HyperLink("Terms of Service");
    end;

    /// <summary>
    /// Integration event for registering available payment services in the system.
    /// Enables extensions to add custom payment service configurations.
    /// </summary>
    /// <param name="PaymentServiceSetup">Temporary record for collecting payment service registrations</param>
    /// <remarks>
    /// Raised during payment service discovery to allow extensions to register their services.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnRegisterPaymentServices(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
    end;

    /// <summary>
    /// Integration event for registering payment service providers and their capabilities.
    /// Allows extensions to define new payment provider types and configurations.
    /// </summary>
    /// <param name="PaymentServiceSetup">Record for provider registration and setup</param>
    /// <remarks>
    /// Raised when building the list of available payment service providers.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnRegisterPaymentServiceProviders(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if a payment method can be used.
    /// Enables custom validation logic for payment method availability.
    /// </summary>
    /// <param name="PaymentMethodCode">Payment method code being validated</param>
    /// <param name="Result">Whether the payment method can be used (can be modified by subscribers)</param>
    /// <param name="IsHandled">Set to true to skip standard validation logic</param>
    /// <remarks>
    /// Raised from CanUsePaymentMethod function before standard payment method validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanUsePaymentMethod(PaymentMethodCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event for custom payment service creation logic.
    /// Allows extensions to perform additional setup when creating payment services.
    /// </summary>
    /// <param name="PaymentServiceSetup">Payment service setup record being created</param>
    /// <remarks>
    /// Raised when a new payment service is being created through the setup process.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnCreatePaymentService(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
    end;

    /// <summary>
    /// Integration event raised when removing payment services from all documents.
    /// Enables custom cleanup logic when disabling payment service integration.
    /// </summary>
    /// <remarks>
    /// Raised when globally disabling payment service inclusion on documents.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnDoNotIncludeAnyPaymentServicesOnAllDocuments()
    begin
    end;

    /// <summary>
    /// Integration event raised after determining document context for payment service changes.
    /// Enables custom validation logic for payment service modification permissions.
    /// </summary>
    /// <param name="DocumentVariant">Document record being evaluated</param>
    /// <param name="DocumentRecordRef">Record reference for the document</param>
    /// <param name="Result">Whether payment service can be changed (can be modified by subscribers)</param>
    /// <param name="IsHandled">Set to true to skip standard validation logic</param>
    /// <remarks>
    /// Raised from CanChangePaymentService function after getting document record reference.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCanChangePaymentServiceOnAfterGetRecordRef(DocumentVariant: Variant; DocumentRecordRef: RecordRef; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

