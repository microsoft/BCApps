// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Threading;

codeunit 7204 "CDS Setup Defaults"
{

    trigger OnRun()
    begin
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        JobQueueCategoryLbl: Label 'BCI INTEG', Locked = true;
        OptionJobQueueCategoryLbl: Label 'BCI OPTION', Locked = true;
        CustomerContactJobQueueCategoryLbl: Label 'BCI CUST', Locked = true;
        CustomerTableMappingNameTxt: Label 'CUSTOMER', Locked = true;
        VendorTableMappingNameTxt: Label 'VENDOR', Locked = true;
        JobQueueEntryNameTok: Label ' %1 - %2 synchronization job.', Comment = '%1 = The Integration Table Name to synchronized (ex. CUSTOMER), %2 = CRM product name';
        UncoupleJobQueueEntryNameTok: Label ' %1 uncouple job.', Comment = '%1 = Integration mapping description, for example, CUSTOMER <-> CRM Account';
        CoupleJobQueueEntryNameTok: Label ' %1 coupling job.', Comment = '%1 = Integration mapping description, for example, CUSTOMER <-> CRM Account';
        IntegrationTablePrefixTok: Label 'Dynamics CRM', Comment = 'Product name', Locked = true;
        CDSCustomerConfigTemplateCodeTok: Label 'BCICUSTOME', Comment = 'Config. Template code for Dataverse Accounts created from Customers. Max length 10.', Locked = true;
        CDSVendorConfigTemplateCodeTok: Label 'BCIVENDOR', Comment = 'Config. Template code for Dataverse Accounts created from Vendors. Max length 10.', Locked = true;
        CRMAccountConfigTemplateDescTxt: Label 'New accounts were created in Sales.', Comment = 'Max. length 50.';
        CustomerConfigTemplateCodeTok: Label 'BCICUST', Comment = 'Customer template code for new customers created from Dataverse data. Max length 10.', Locked = true;
        VendorConfigTemplateCodeTok: Label 'BCIVEND', Comment = 'Vendor template code for new vendors created from Dataverse data. Max length 10.', Locked = true;
        PersonTok: Label 'Person', Comment = 'Non-localized option name for Contact Type Person.', Locked = true;
        CustomerConfigTemplateDescTxt: Label 'New customers were created during synch.', Comment = 'Max. length 50.';
        VendorConfigTemplateDescTxt: Label 'New vendors were created during synch.', Comment = 'Max. length 50.';

    procedure ResetConfiguration(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        IsHandled: Boolean;
        IsTeamOwnershipModel: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetConfiguration(CDSConnectionSetup, IsHandled);
        if IsHandled then
            exit;

        CDSIntegrationMgt.RegisterConnection();
        CDSIntegrationMgt.ActivateConnection();

        IsTeamOwnershipModel := CDSIntegrationMgt.IsTeamOwnershipModelSelected();

        ResetSalesPeopleSystemUserMapping('SALESPEOPLE', IsTeamOwnershipModel, true);
        ResetCustomerAccountMapping(CustomerTableMappingNameTxt, IsTeamOwnershipModel, true);
        ResetVendorAccountMapping(VendorTableMappingNameTxt, IsTeamOwnershipModel, true);
        ResetContactContactMapping('CONTACT', IsTeamOwnershipModel, true);
        ResetCurrencyTransactionCurrencyMapping('CURRENCY', true);
        ResetPaymentTermsMapping('PAYMENT TERMS');
        ResetShipmentMethodMapping('SHIPMENT METHOD');
        ResetShippingAgentMapping('SHIPPING AGENT');
        CDSConnectionSetup.SetBaseCurrencyData();

        SetCustomIntegrationsTableMappings(CDSConnectionSetup);
        AddExtraIntegrationFieldMappings();
    end;

    [Scope('OnPrem')]
    procedure ResetSalesPeopleSystemUserMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetSalesPeopleSystemUserMapping(IntegrationTableMappingName, ShouldRecreateJobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser",
          CRMSystemuser.FieldNo(SystemUserId), CRMSystemuser.FieldNo(ModifiedOn),
          '', '', true);

        CRMSystemuser.Reset();
        CRMSystemuser.SetRange(IsDisabled, false);
        CRMSystemuser.SetRange(IsLicensed, true);
        CRMSystemuser.SetRange(IsIntegrationUser, false);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Systemuser", CRMSystemuser.TableCaption(), CRMSystemuser.GetView()));
        IntegrationTableMapping.Modify();

        // Email > InternalEMailAddress
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo("E-Mail"),
          CRMSystemuser.FieldNo(InternalEMailAddress),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // Name > FullName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo(Name),
          CRMSystemuser.FieldNo(FullName),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // Phone No. > MobilePhone
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo("Phone No."),
          CRMSystemuser.FieldNo(MobilePhone),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        OnAfterResetSalesPeopleSystemUserMapping(IntegrationTableMappingName);

        if not IsTeamOwnershipModel then
            RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 1440);
    end;

    [Scope('OnPrem')]
    procedure ResetCustomerAccountMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetCustomerAccountMapping(IntegrationTableMappingName, ShouldRecreateJobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Customer, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          ResetBCAccountConfigTemplate(Database::Customer), ResetCDSAccountConfigTemplate(Database::Customer), true);

        Customer.SetRange(Blocked, Customer.Blocked::" ");
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Customer, Customer.TableCaption(), Customer.GetView()));

        CRMAccount.SetRange(StateCode, CRMAccount.StateCode::Active);
        CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMAccount.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Account", CRMAccount.TableCaption(), CRMAccount.GetView()));
        if not IsTeamOwnershipModel then
            IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT'
        else
            IntegrationTableMapping."Dependency Filter" := 'CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';

        IntegrationTableMapping.Modify();

        if not IsTeamOwnershipModel then begin
            // OwnerIdType::systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMAccount.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMAccount.OwnerIdType::systemuser), false, false);

            // Salesperson Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Customer.FieldNo("Salesperson Code"),
              CRMAccount.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(Name),
          CRMAccount.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Contact > Address1_PrimaryContactName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(Contact),
          CRMAccount.FieldNo(Address1_PrimaryContactName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false); // We do not validate contact name.

        // Address > Address1_Line1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(Address),
          CRMAccount.FieldNo(Address1_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address 2 > Address1_Line2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Address 2"),
          CRMAccount.FieldNo(Address1_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Post Code > Address1_PostalCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Post Code"),
          CRMAccount.FieldNo(Address1_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // City > Address1_City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(City),
          CRMAccount.FieldNo(Address1_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Country > Address1_Country
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Country/Region Code"),
          CRMAccount.FieldNo(Address1_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false);

        // County > Address1_StateOrProvince
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(County),
          CRMAccount.FieldNo(Address1_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Currency Code"),
          CRMAccount.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Email > EmailAddress1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("E-Mail"),
          CRMAccount.FieldNo(EMailAddress1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Fax No > Fax
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Fax No."),
          CRMAccount.FieldNo(Fax),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Home Page > WebSiteUrl
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Home Page"),
          CRMAccount.FieldNo(WebSiteURL),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Phone No. > Telephone1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Phone No."),
          CRMAccount.FieldNo(Telephone1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipment Method Code > address1_freighttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Shipment Method Code"),
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Shipping Agent Code"),
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Payment Terms Code"),
          CRMAccount.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Credit Limit (LCY) > creditlimit
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Credit Limit (LCY)"),
          CRMAccount.FieldNo(CreditLimit),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Primary Contact No." > PrimaryContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Primary Contact No."),
          CRMAccount.FieldNo(PrimaryContactId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);
        SetIntegrationFieldMappingClearValueOnFailedSync();

        OnAfterResetCustomerAccountMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetVendorAccountMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        Vendor: Record Vendor;
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetVendorAccountMapping(IntegrationTableMappingName, ShouldRecreateJobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Vendor, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          ResetBCAccountConfigTemplate(Database::Vendor), ResetCDSAccountConfigTemplate(Database::Vendor), true);

        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Vendor, Vendor.TableCaption(), Vendor.GetView()));

        CRMAccount.SetRange(StateCode, CRMAccount.StateCode::Active);
        CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Vendor);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMAccount.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Account", CRMAccount.TableCaption(), CRMAccount.GetView()));
        if not IsTeamOwnershipModel then
            IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT'
        else
            IntegrationTableMapping."Dependency Filter" := 'CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';

        IntegrationTableMapping.Modify();

        if not IsTeamOwnershipModel then begin
            // OwnerIdType::systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMAccount.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMAccount.OwnerIdType::systemuser), false, false);

            // Purchaser Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Vendor.FieldNo("Purchaser Code"),
              CRMAccount.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(Name),
          CRMAccount.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Contact > Address1_PrimaryContactName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(Contact),
          CRMAccount.FieldNo(Address1_PrimaryContactName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false); // We do not validate contact name.

        // Address > Address1_Line1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(Address),
          CRMAccount.FieldNo(Address1_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address 2 > Address1_Line2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Address 2"),
          CRMAccount.FieldNo(Address1_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Post Code > Address1_PostalCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Post Code"),
          CRMAccount.FieldNo(Address1_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // City > Address1_City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(City),
          CRMAccount.FieldNo(Address1_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Country > Address1_Country
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Country/Region Code"),
          CRMAccount.FieldNo(Address1_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false);

        // County > Address1_StateOrProvince
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(County),
          CRMAccount.FieldNo(Address1_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Currency Code"),
          CRMAccount.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Email > EmailAddress1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("E-Mail"),
          CRMAccount.FieldNo(EMailAddress1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Fax No > Fax
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Fax No."),
          CRMAccount.FieldNo(Fax),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Home Page > WebSiteUrl
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Home Page"),
          CRMAccount.FieldNo(WebSiteURL),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Phone No. > Telephone1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Phone No."),
          CRMAccount.FieldNo(Telephone1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipment Method Code > address1_freighttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Shipment Method Code"),
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Shipping Agent Code"),
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Payment Terms Code"),
          CRMAccount.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Primary Contact No." > PrimaryContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Primary Contact No."),
          CRMAccount.FieldNo(PrimaryContactId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);
        SetIntegrationFieldMappingClearValueOnFailedSync();

        OnAfterResetVendorAccountMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetContactContactMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetContactContactMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Contact, DATABASE::"CRM Contact",
          CRMContact.FieldNo(ContactId), CRMContact.FieldNo(ModifiedOn),
          '', '', true);

        Contact.Reset();
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("Company No.", '<>''''');
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Contact, Contact.TableCaption(), Contact.GetView()));

        CRMContact.Reset();
        CRMContact.SetFilter(ParentCustomerId, '<>''%1''', EmptyGuid);
        CRMContact.SetRange(StateCode, CRMContact.StateCode::Active);
        CRMContact.SetRange(ParentCustomerIdType, CRMContact.ParentCustomerIdType::account);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMContact.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Contact", CRMContact.TableCaption(), CRMContact.GetView()));
        IntegrationTableMapping."Dependency Filter" := 'CUSTOMER|VENDOR';
        IntegrationTableMapping.Modify();

        if not IsTeamOwnershipModel then begin
            // OwnerIdType::systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMContact.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMContact.OwnerIdType::systemuser), false, false);

            // Salesperson Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Contact.FieldNo("Salesperson Code"),
              CRMContact.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Currency Code"),
          CRMContact.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address > Address1_Line1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Address),
          CRMContact.FieldNo(Address1_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address 2 > Address1_Line2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Address 2"),
          CRMContact.FieldNo(Address1_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Post Code > Address1_PostalCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Post Code"),
          CRMContact.FieldNo(Address1_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // City > Address1_City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(City),
          CRMContact.FieldNo(Address1_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Country/Region Code > Address1_Country
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Country/Region Code"),
          CRMContact.FieldNo(Address1_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false);

        // County > Address1_StateOrProvince
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(County),
          CRMContact.FieldNo(Address1_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Email > EmailAddress1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("E-Mail"),
          CRMContact.FieldNo(EMailAddress1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Fax No. > Fax
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Fax No."),
          CRMContact.FieldNo(Fax),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // First Name > FirstName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("First Name"),
          CRMContact.FieldNo(FirstName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Middle Name > MiddleName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Middle Name"),
          CRMContact.FieldNo(MiddleName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Surname > LastName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Surname),
          CRMContact.FieldNo(LastName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Home Page > WebSiteUrl
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Home Page"),
          CRMContact.FieldNo(WebSiteUrl),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Mobile Phone No. > MobilePhone
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Mobile Phone No."),
          CRMContact.FieldNo(MobilePhone),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Pager > Pager
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Pager),
          CRMContact.FieldNo(Pager),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Phone No. > Telephone1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Phone No."),
          CRMContact.FieldNo(Telephone1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Type
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Type), 0,
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          PersonTok, true, false);

        // CRMContact.ParentCustomerIdType::account
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMContact.FieldNo(ParentCustomerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMContact.ParentCustomerIdType::account), false, false);

        OnAfterResetContactContactMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetCurrencyTransactionCurrencyMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetCurrencyTransactionCurrencyMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Currency, DATABASE::"CRM Transactioncurrency",
          CRMTransactioncurrency.FieldNo(TransactionCurrencyId),
          CRMTransactioncurrency.FieldNo(ModifiedOn),
          '',
          '',
          true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;
        IntegrationTableMapping.Modify();

        // Code > ISOCurrencyCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Currency.FieldNo(Code),
          CRMTransactioncurrency.FieldNo(ISOCurrencyCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Symbol > CurrencySymbol
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Currency.FieldNo(Symbol),
          CRMTransactioncurrency.FieldNo(CurrencySymbol),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Description > CurrencyName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Currency.FieldNo(Description),
          CRMTransactioncurrency.FieldNo(CurrencyName),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.SetRange("Field No.", Currency.FieldNo(Code));
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetPaymentTermsMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        PaymentTerms: Record "Payment Terms";
        CRMAccount: Record "CRM Account";
        FieldMappingDirection: Option;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetPaymentTermsMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Payment Terms", DATABASE::"CRM Account",
          CRMAccount.FieldNo(PaymentTermsCodeEnum), 0,
          '', '', true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;
        IntegrationTableMapping.Modify();

        FieldMappingDirection := IntegrationFieldMapping.Direction::ToIntegrationTable;

        // Code > "CRM Account".PaymentTermsCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PaymentTerms.FieldNo(Code),
          CRMAccount.FieldNo(PaymentTermsCodeEnum),
          FieldMappingDirection,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
    end;

    [Scope('OnPrem')]
    procedure ResetShipmentMethodMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ShipmentMethod: Record "Shipment Method";
        CRMAccount: Record "CRM Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetShipmentMethodMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Shipment Method", DATABASE::"CRM Account",
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), 0,
          '', '', true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;
        IntegrationTableMapping.Modify();

        // Code > "CRM Account".Address1_FreightTermsCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ShipmentMethod.FieldNo(Code),
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
    end;

    [Scope('OnPrem')]
    procedure ResetShippingAgentMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ShippingAgent: Record "Shipping Agent";
        CRMAccount: Record "CRM Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetShippingAgentMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Shipping Agent", DATABASE::"CRM Account",
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), 0,
          '', '', true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;
        IntegrationTableMapping.Modify();

        // Code > "CRM Account".Address1_ShippingMethodCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ShippingAgent.FieldNo(Code),
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        UncoupleCodeunitId: Integer;
        Direction: Integer;
    begin
        Direction := GetDefaultDirection(TableNo);
        if Direction in [IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::Bidirectional] then
            if CDSIntegrationMgt.HasCompanyIdField(IntegrationTableNo) then
                UncoupleCodeunitId := Codeunit::"CDS Int. Table Uncouple";
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo,
          IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode,
          SynchOnlyCoupledRecords, Direction, IntegrationTablePrefixTok,
          Codeunit::"CRM Integration Table Synch.", UncoupleCodeunitId);
    end;

    local procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
          ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    local procedure SetIntegrationFieldMappingClearValueOnFailedSync()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast();
        IntegrationFieldMapping."Clear Value on Failed Sync" := true;
        IntegrationFieldMapping.Modify();
    end;

    local procedure SetIntegrationFieldMappingNotNull()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast();
        IntegrationFieldMapping."Not Null" := true;
        IntegrationFieldMapping.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateUncoupleJobQueueEntry(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    begin
        exit(CreateJobQueueEntry(IntegrationTableMapping, Codeunit::"Int. Uncouple Job Runner", StrSubstNo(UncoupleJobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription())));
    end;

    [Scope('OnPrem')]
    procedure CreateCoupleJobQueueEntry(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    begin
        exit(CreateJobQueueEntry(IntegrationTableMapping, Codeunit::"Int. Coupling Job Runner", StrSubstNo(CoupleJobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription())));
    end;

    procedure CreateJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    begin
        exit(CreateJobQueueEntry(IntegrationTableMapping, StrSubstNo(JobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription(), CRMProductName.CDSServiceName())));
    end;

    internal procedure CreateJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"; ServiceName: Text): Boolean
    begin
        exit(CreateJobQueueEntry(IntegrationTableMapping, Codeunit::"Integration Synch. Job Runner", StrSubstNo(JobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription(), ServiceName)));
    end;

    local procedure CreateJobQueueEntry(var IntegrationTableMapping: Record "Integration Table Mapping"; JobCodeunitId: Integer; JobDescription: Text): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartTime: DateTime;
    begin
        StartTime := CurrentDateTime() + 1000;
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", JobCodeunitId);
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.SetFilter("Earliest Start Date/Time", '<=%1', StartTime);
        if not JobQueueEntry.IsEmpty() then begin
            JobQueueEntry.DeleteTasks();
            Commit();
        end;

        JobQueueEntry.Init();
        Clear(JobQueueEntry.ID); // "Job Queue - Enqueue" is to define new ID
        JobQueueEntry."Earliest Start Date/Time" := StartTime;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := JobCodeunitId;
        JobQueueEntry."Record ID to Process" := IntegrationTableMapping.RecordId();
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry."Notify On Success" := false;
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryLbl;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueEntry.Description := CopyStr(JobDescription, 1, MaxStrLen(JobQueueEntry.Description));
        OnCreateJobQueueEntryOnBeforeJobQueueEnqueue(JobQueueEntry, IntegrationTableMapping, JobCodeunitId, JobDescription);
        exit(Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry))
    end;

    local procedure RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer)
    begin
        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, IntervalInMinutes, ShouldRecreateJobQueueEntry, InactivityTimeoutPeriod, CRMProductName.CDSServiceName(), true);
    end;

    local procedure RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer)
    begin
        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, IntervalInMinutes, ShouldRecreateJobQueueEntry, InactivityTimeoutPeriod, CRMProductName.CDSServiceName(), false);
    end;

    internal procedure RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer; ServiceName: Text; IsOption: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        JobQueueEntry.DeleteTasks();

        JobQueueEntry.InitRecurringJob(IntervalInMinutes);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Integration Synch. Job Runner";
        JobQueueEntry."Record ID to Process" := IntegrationTableMapping.RecordId();
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(JobQueueEntryNameTok, IntegrationTableMapping.Name, ServiceName), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Maximum No. of Attempts to Run" := 10;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueEntry."Inactivity Timeout Period" := InactivityTimeoutPeriod;
        if IsOption then
            JobQueueEntry."Job Queue Category Code" := OptionJobQueueCategoryLbl;
        if IntegrationTableMapping."Table ID" in [Database::Customer, Database::Vendor, Database::Contact] then
            JobQueueEntry."Job Queue Category Code" := CustomerContactJobQueueCategoryLbl;
        if ShouldRecreateJobQueueEntry then
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry)
        else
            JobQueueEntry.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", 'OnGetCDSTableNo', '', false, false)]
    local procedure ReturnProxyTableNoOnGetCDSTableNo(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        case BCTableNo of
            DATABASE::Contact:
                CDSTableNo := DATABASE::"CRM Contact";
            DATABASE::Currency:
                CDSTableNo := DATABASE::"CRM Transactioncurrency";
            DATABASE::Customer,
            DATABASE::Vendor:
                CDSTableNo := DATABASE::"CRM Account";
            DATABASE::"Salesperson/Purchaser":
                CDSTableNo := DATABASE::"CRM Systemuser";
            DATABASE::"Payment Terms":
                CDSTableNo := DATABASE::"CRM Payment Terms";
            DATABASE::"Shipment Method":
                CDSTableNo := DATABASE::"CRM Freight Terms";
            DATABASE::"Shipping Agent":
                CDSTableNo := DATABASE::"CRM Shipping Method";
        end;

        if CDSTableNo <> 0 then
            handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", 'OnAddEntityTableMapping', '', false, false)]
    local procedure AddProxyTablesOnAddEntityTableMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        CRMSetupDefaults.AddEntityTableMapping('account', Database::Vendor, TempNameValueBuffer);
    end;

    procedure GetDefaultDirection(NAVTableID: Integer): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        case NAVTableID of
            DATABASE::Contact,
          DATABASE::Customer:
                exit(IntegrationTableMapping.Direction::Bidirectional);
            DATABASE::Currency,
          DATABASE::"Payment Terms",
          DATABASE::"Shipment Method",
          DATABASE::"Shipping Agent":
                exit(IntegrationTableMapping.Direction::ToIntegrationTable);
            DATABASE::"Salesperson/Purchaser":
                exit(IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    local procedure GetTableFilterFromView(TableID: Integer; Caption: Text; View: Text): Text
    var
        FilterBuilder: FilterPageBuilder;
    begin
        FilterBuilder.AddTable(Caption, TableID);
        FilterBuilder.SetView(Caption, View);
        exit(FilterBuilder.GetView(Caption, false));
    end;

    procedure GetPrioritizedMappingList(var NameValueBuffer: Record "Name/Value Buffer")
    // TO DO: This is needed for "Synchronize Modified Records" that we should add
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        NextPriority: Integer;
    begin
        NextPriority := 1;

        // 1) From CRM Systemusers
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, 0, DATABASE::"CRM Systemuser");
        // 2) From Currency
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Currency, 0);
        // 3) To/From Customers/CRM Accounts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Customer, DATABASE::"CRM Account");
        // 4)  Vendor
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Vendor, DATABASE::"CRM Account");
        // 5) To/From Contacts/CRM Contacts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Contact, DATABASE::"CRM Contact");

        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetFilter("Parent Name", '=''''');
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet() then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, NextPriority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure AddPrioritizedMappingsToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; TableID: Integer; IntegrationTableID: Integer)
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if TableID > 0 then
            IntegrationTableMapping.SetRange("Table ID", TableID);
        if IntegrationTableID > 0 then
            IntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableID);
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet() then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, Priority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure AddPrioritizedMappingToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; MappingName: Code[20])
    begin
        NameValueBuffer.SetRange(Value, MappingName);

        if not NameValueBuffer.FindFirst() then begin
            NameValueBuffer.Init();
            NameValueBuffer.ID := Priority;
            NameValueBuffer.Name := Format(Priority);
            NameValueBuffer.Value := MappingName;
            NameValueBuffer.Insert();
            Priority := Priority + 1;
        end;

        NameValueBuffer.Reset();
    end;

    local procedure ResetCDSAccountConfigTemplate(TableNo: Integer): Code[10]
    var
        AccountConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CRMAccount: Record "CRM Account";
        TemplateCode: Code[10];
        CustomerTypeCode: Option;
    begin
        case TableNo of
            Database::Customer:
                begin
                    TemplateCode := CDSCustomerConfigTemplateCodeTok;
                    CustomerTypeCode := CRMAccount.CustomerTypeCode::Customer;
                end;
            Database::Vendor:
                begin
                    TemplateCode := CDSVendorConfigTemplateCodeTok;
                    CustomerTypeCode := CRMAccount.CustomerTypeCode::Vendor;
                end;
            else
                exit('');
        end;

        ConfigTemplateLine.SetRange(
          "Data Template Code", CopyStr(TemplateCode, 1, MaxStrLen(AccountConfigTemplateHeader.Code)));
        ConfigTemplateLine.DeleteAll();
        AccountConfigTemplateHeader.SetRange(
          Code, CopyStr(TemplateCode, 1, MaxStrLen(AccountConfigTemplateHeader.Code)));
        AccountConfigTemplateHeader.DeleteAll();

        AccountConfigTemplateHeader.Init();
        AccountConfigTemplateHeader.Code := CopyStr(TemplateCode, 1, MaxStrLen(AccountConfigTemplateHeader.Code));
        AccountConfigTemplateHeader.Description :=
          CopyStr(CRMAccountConfigTemplateDescTxt, 1, MaxStrLen(AccountConfigTemplateHeader.Description));
        AccountConfigTemplateHeader."Table ID" := DATABASE::"CRM Account";
        AccountConfigTemplateHeader.Insert();
        ConfigTemplateLine.Init();
        ConfigTemplateLine."Data Template Code" := AccountConfigTemplateHeader.Code;
        ConfigTemplateLine."Line No." := 1;
        ConfigTemplateLine.Type := ConfigTemplateLine.Type::Field;
        ConfigTemplateLine."Table ID" := DATABASE::"CRM Account";
        ConfigTemplateLine."Field ID" := CRMAccount.FieldNo(CustomerTypeCode);
        ConfigTemplateLine."Field Name" := CRMAccount.FieldName(CustomerTypeCode);
        ConfigTemplateLine."Default Value" := Format(CustomerTypeCode);
        ConfigTemplateLine."Language ID" := GlobalLanguage();
        ConfigTemplateLine.Insert();

        exit(TemplateCode);
    end;

    local procedure ResetBCAccountConfigTemplate(TableNo: Integer): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        BCAccountConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        BCAccountConfigTemplateLine: Record "Config. Template Line";
        Customer: Record Customer;
        Vendor: Record Vendor;
        FoundTemplateCode: Code[10];
        ConfigTemplateCode: Code[10];
        ConfigTemplateDesc: Text;
        CurrencyFieldNo: Integer;
    begin
        case TableNo of
            Database::Customer:
                begin
                    ConfigTemplateCode := CustomerConfigTemplateCodeTok;
                    ConfigTemplateDesc := CustomerConfigTemplateDescTxt;
                    CurrencyFieldNo := Customer.FieldNo("Currency Code");
                end;
            Database::Vendor:
                begin
                    ConfigTemplateCode := VendorConfigTemplateCodeTok;
                    ConfigTemplateDesc := VendorConfigTemplateDescTxt;
                    CurrencyFieldNo := Vendor.FieldNo("Currency Code");
                end;
            else
                exit('');
        end;

        BCAccountConfigTemplateLine.SetRange(
          "Data Template Code", CopyStr(ConfigTemplateCode, 1, MaxStrLen(BCAccountConfigTemplateLine."Data Template Code")));
        BCAccountConfigTemplateLine.DeleteAll();
        BCAccountConfigTemplateHeader.SetRange(
          Code, CopyStr(ConfigTemplateCode, 1, MaxStrLen(BCAccountConfigTemplateHeader.Code)));
        BCAccountConfigTemplateHeader.DeleteAll();

        // Base the customer config template off the first customer template with currency code '' (LCY);
        ConfigTemplateHeader.SetRange("Table ID", TableNo);
        if ConfigTemplateHeader.FindSet() then
            repeat
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Field ID", CurrencyFieldNo);
                ConfigTemplateLine.SetFilter("Default Value", '');
                if ConfigTemplateLine.FindFirst() then begin
                    FoundTemplateCode := ConfigTemplateHeader.Code;
                    break;
                end;
            until ConfigTemplateHeader.Next() = 0;

        if FoundTemplateCode = '' then
            exit('');

        BCAccountConfigTemplateHeader.Init();
        BCAccountConfigTemplateHeader.TransferFields(ConfigTemplateHeader, false);
        BCAccountConfigTemplateHeader.Code := CopyStr(ConfigTemplateCode, 1, MaxStrLen(BCAccountConfigTemplateHeader.Code));
        BCAccountConfigTemplateHeader.Description :=
          CopyStr(ConfigTemplateDesc, 1, MaxStrLen(BCAccountConfigTemplateHeader.Description));
        BCAccountConfigTemplateHeader.Insert();

        ConfigTemplateLine.Reset();
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindSet();
        repeat
            if not (ConfigTemplateLine."Field ID" = CurrencyFieldNo) then begin
                BCAccountConfigTemplateLine.Init();
                BCAccountConfigTemplateLine.TransferFields(ConfigTemplateLine, true);
                BCAccountConfigTemplateLine."Data Template Code" := BCAccountConfigTemplateHeader.Code;
                BCAccountConfigTemplateLine.Insert();
            end;
        until ConfigTemplateLine.Next() = 0;

        exit(ConfigTemplateCode);
    end;

    [Scope('OnPrem')]
    procedure RunCoupleSalespeoplePage()
    var
        CRMSystemuser: Record "CRM Systemuser";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMSystemuserList: Page "CRM Systemuser List";
        IntTableFilter: Text;
    begin
        IntTableFilter :=
          LookupCRMTables.GetIntegrationTableFilter(DATABASE::"CRM Systemuser", DATABASE::"Salesperson/Purchaser");
        CRMSystemuser.SetView(IntTableFilter);
        CRMSystemuserList.SetTableView(CRMSystemuser);
        CRMSystemuserList.Initialize(true);
        CRMSystemuserList.Run();
    end;

    [Scope('Cloud')]
    procedure GetCustomerTableMappingName(): Text
    begin
        exit(CustomerTableMappingNameTxt);
    end;

    [Scope('Cloud')]
    procedure GetVendorTableMappingName(): Text
    begin
        exit(VendorTableMappingNameTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnEnableIntegration', '', false, false)]
    local procedure HandleOnEnableIntegration()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CDSConnectionSetup.Get();
        case CDSConnectionSetup."Ownership Model" of
            CDSConnectionSetup."Ownership Model"::Person:
                if IntegrationTableMapping.Get('SALESPEOPLE') then begin
                    RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
                    if IntegrationTableMapping.Get(VendorTableMappingNameTxt) then begin
                        IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
                        IntegrationTableMapping.Modify();
                    end;
                    if IntegrationTableMapping.Get(CustomerTableMappingNameTxt) then begin
                        IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
                        IntegrationTableMapping.Modify();
                    end;
                end;
            CDSConnectionSetup."Ownership Model"::Team:
                if IntegrationTableMapping.Get('SALESPEOPLE') then begin
                    JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                    JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
                    JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                    JobQueueEntry.DeleteTasks();
                    IntegrationTableMapping.Delete(true);
                    if IntegrationTableMapping.Get(VendorTableMappingNameTxt) then begin
                        IntegrationTableMapping."Dependency Filter" := 'CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
                        IntegrationTableMapping.Modify();
                    end;
                    if IntegrationTableMapping.Get(CustomerTableMappingNameTxt) then begin
                        IntegrationTableMapping."Dependency Filter" := 'CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT';
                        IntegrationTableMapping.Modify();
                    end;
                end;
        end;
    end;

    procedure ResetOptionMappingConfiguration()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        if IntegrationTableMapping.Get('PAYMENT TERMS') then begin
            IntegrationTableMapping."Synch. Only Coupled Records" := true;
            IntegrationTableMapping."Coupling Codeunit ID" := Codeunit::"CDS Int. Option Couple";
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
            IntegrationTableMapping.Modify();
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.ModifyAll(Direction, IntegrationFieldMapping.Direction::ToIntegrationTable);
            RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
        end;
        if IntegrationTableMapping.Get('SHIPMENT METHOD') then begin
            IntegrationTableMapping."Synch. Only Coupled Records" := true;
            IntegrationTableMapping."Coupling Codeunit ID" := Codeunit::"CDS Int. Option Couple";
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
            IntegrationTableMapping.Modify();
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.ModifyAll(Direction, IntegrationFieldMapping.Direction::ToIntegrationTable);
            RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
        end;
        if IntegrationTableMapping.Get('SHIPPING AGENT') then begin
            IntegrationTableMapping."Synch. Only Coupled Records" := true;
            IntegrationTableMapping."Coupling Codeunit ID" := Codeunit::"CDS Int. Option Couple";
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
            IntegrationTableMapping.Modify();
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.ModifyAll(Direction, IntegrationFieldMapping.Direction::ToIntegrationTable);
            RecreateOptionJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetCustomIntegrationsTableMappings(CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        OnAfterResetConfiguration(CDSConnectionSetup);
    end;

    internal procedure AddExtraIntegrationFieldMappings()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindSet() then
            repeat
                CRMIntegrationManagement.AddExtraFieldMappings(IntegrationTableMapping);
            until IntegrationTableMapping.Next() = 0;

        OnAfterAddExtraIntegrationFieldMappings(CRMIntegrationManagement, IntegrationTableMapping);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetSalesPeopleSystemUserMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetCustomerAccountMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetVendorAccountMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetContactContactMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetConfiguration(var CDSConnectionSetup: Record "CDS Connection Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetContactContactMapping(var IntegrationTableMappingName: Code[20]; var ShouldRecreateJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetCurrencyTransactionCurrencyMapping(var IntegrationTableMappingName: Code[20]; var ShouldRecreateJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetCustomerAccountMapping(var IntegrationTableMappingName: Code[20]; var ShouldRecreateJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetPaymentTermsMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetShipmentMethodMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetShippingAgentMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesPeopleSystemUserMapping(var IntegrationTableMappingName: Code[20]; var ShouldRecreateJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetVendorAccountMapping(var IntegrationTableMappingName: Code[20]; var ShouldRecreateJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobQueueEntryOnBeforeJobQueueEnqueue(var JobQueueEntry: Record "Job Queue Entry"; var IntegrationTableMapping: Record "Integration Table Mapping"; JobCodeunitId: Integer; JobDescription: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddExtraIntegrationFieldMappings(var CRMIntegrationManagement: Codeunit "CRM Integration Management"; var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
    end;
}

