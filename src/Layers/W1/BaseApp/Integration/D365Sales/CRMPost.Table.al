// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5344 "CRM Post"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Post';
    Description = 'An activity feed post.';
    ExternalName = 'post';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(2; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(3; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(4; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(5; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(6; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization associated with the solution.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Organization".OrganizationId;
        }
        field(7; OrganizationIdName; Text[160])
        {
            CalcFormula = lookup("CRM Organization".Name where(OrganizationId = field(OrganizationId)));
            Caption = 'OrganizationIdName';
            ExternalAccess = Read;
            ExternalName = 'organizationidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(8; PostId; Guid)
        {
            Caption = 'Post';
            Description = 'Unique identifier for entity instances';
            ExternalAccess = Insert;
            ExternalName = 'postid';
            ExternalType = 'Uniqueidentifier';
        }
        field(9; RegardingObjectId; Guid)
        {
            Caption = 'Regarding';
            Description = 'Choose the parent record for the post to identify the customer, opportunity, case, or other record that the post most closely relates to.';
            ExternalAccess = Insert;
            ExternalName = 'regardingobjectid';
            ExternalType = 'Lookup';
            TableRelation = if (RegardingObjectTypeCode = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (RegardingObjectTypeCode = const(account)) "CRM Account".AccountId
            else
            if (RegardingObjectTypeCode = const(contact)) "CRM Contact".ContactId
            else
            if (RegardingObjectTypeCode = const(opportunity)) "CRM Opportunity".OpportunityId
            else
            if (RegardingObjectTypeCode = const(post)) "CRM Post".PostId
            else
            if (RegardingObjectTypeCode = const(transactioncurrency)) "CRM Transactioncurrency".TransactionCurrencyId
            else
            if (RegardingObjectTypeCode = const(pricelevel)) "CRM Pricelevel".PriceLevelId
            else
            if (RegardingObjectTypeCode = const(productpricelevel)) "CRM Productpricelevel".ProductPriceLevelId
            else
            if (RegardingObjectTypeCode = const(product)) "CRM Product".ProductId
            else
            if (RegardingObjectTypeCode = const(incident)) "CRM Incident".IncidentId
            else
            if (RegardingObjectTypeCode = const(incidentresolution)) "CRM Incidentresolution".ActivityId
            else
            if (RegardingObjectTypeCode = const(quote)) "CRM Quote".QuoteId
            else
            if (RegardingObjectTypeCode = const(quotedetail)) "CRM Quotedetail".QuoteDetailId
            else
            if (RegardingObjectTypeCode = const(salesorder)) "CRM Salesorder".SalesOrderId
            else
            if (RegardingObjectTypeCode = const(salesorderdetail)) "CRM Salesorderdetail".SalesOrderDetailId
            else
            if (RegardingObjectTypeCode = const(invoice)) "CRM Invoice".InvoiceId
            else
            if (RegardingObjectTypeCode = const(invoicedetail)) "CRM Invoicedetail".InvoiceDetailId
            else
            if (RegardingObjectTypeCode = const(contract)) "CRM Contract".ContractId
            else
            if (RegardingObjectTypeCode = const(team)) "CRM Team".TeamId
            else
            if (RegardingObjectTypeCode = const(customeraddress)) "CRM Customeraddress".CustomerAddressId
            else
            if (RegardingObjectTypeCode = const(uom)) "CRM Uom".UoMId
            else
            if (RegardingObjectTypeCode = const(uomschedule)) "CRM Uomschedule".UoMScheduleId
            else
            if (RegardingObjectTypeCode = const(organization)) "CRM Organization".OrganizationId
            else
            if (RegardingObjectTypeCode = const(businessunit)) "CRM Businessunit".BusinessUnitId
            else
            if (RegardingObjectTypeCode = const(discount)) "CRM Discount".DiscountId
            else
            if (RegardingObjectTypeCode = const(discounttype)) "CRM Discounttype".DiscountTypeId;
        }
        field(10; RegardingObjectTypeCode; Option)
        {
            Caption = 'RegardingObjectTypeCode';
            Description = 'Type of the RegardingObject';
            ExternalAccess = Insert;
            ExternalName = 'regardingobjecttypecode';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,account,contact,opportunity,post,transactioncurrency,pricelevel,productpricelevel,product,incident,incidentresolution,quote,quotedetail,salesorder,salesorderdetail,invoice,invoicedetail,contract,team,customeraddress,uom,uomschedule,organization,businessunit,discount,discounttype';
            OptionMembers = " ",systemuser,account,contact,opportunity,post,transactioncurrency,pricelevel,productpricelevel,product,incident,incidentresolution,quote,quotedetail,salesorder,salesorderdetail,invoice,invoicedetail,contract,team,customeraddress,uom,uomschedule,organization,businessunit,discount,discounttype;
        }
        field(11; Source; Option)
        {
            Caption = 'Source';
            Description = 'Select whether the post was created manually or automatically.';
            ExternalAccess = Insert;
            ExternalName = 'source';
            ExternalType = 'Picklist';
            InitValue = ManualPost;
            OptionCaption = 'Auto Post,Manual Post';
            OptionOrdinalValues = 1, 2;
            OptionMembers = AutoPost,ManualPost;
        }
        field(12; Text; Text[250])
        {
            Caption = 'Text';
            Description = 'Shows the text of a post. If this is a manual post, it appears in plain text. If this is an auto post, it appears in XML.';
            ExternalAccess = Insert;
            ExternalName = 'text';
            ExternalType = 'String';
        }
        field(13; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(14; Type; Option)
        {
            Caption = 'Type';
            Description = 'Select the post type.';
            ExternalAccess = Insert;
            ExternalName = 'type';
            ExternalType = 'Picklist';
            InitValue = "Check-in";
            OptionCaption = 'Check-in,Idea,News,Private Message,Question,Re-post,Status';
            OptionOrdinalValues = 1, 2, 3, 4, 5, 6, 7;
            OptionMembers = "Check-in",Idea,News,PrivateMessage,Question,"Re-post",Status;
        }
        field(15; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(16; RegardingObjectOwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Unique identifier of the user or team who owns the regarding object.';
            ExternalAccess = Read;
            ExternalName = 'regardingobjectownerid';
            ExternalType = 'Owner';
            TableRelation = if (RegardingObjectOwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (RegardingObjectOwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(17; RegardingObjectOwnerIdType; Option)
        {
            Caption = 'RegardingObjectOwnerIdType';
            Description = 'Type of the RegardingObjectOwnerId';
            ExternalAccess = Read;
            ExternalName = 'regardingobjectowneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(18; RegardingObjectOwningBusinessU; Guid)
        {
            Caption = 'Regarding object owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the regarding object.';
            ExternalAccess = Read;
            ExternalName = 'regardingobjectowningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(19; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who modified the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(20; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(21; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who modified the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(22; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(23; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
    }

    keys
    {
        key(Key1; PostId)
        {
            Clustered = true;
        }
        key(Key2; Text)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Text)
        {
        }
    }
}

