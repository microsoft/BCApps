// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5361 "CRM Uom"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Uom';
    Description = 'Unit of measure.';
    ExternalName = 'uom';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; UoMId; Guid)
        {
            Caption = 'Unit';
            Description = 'Unique identifier of the unit.';
            ExternalAccess = Insert;
            ExternalName = 'uomid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; BaseUoM; Guid)
        {
            Caption = 'Base Unit';
            Description = 'Choose the base or primary unit on which the unit is based.';
            ExternalName = 'baseuom';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uom".UoMId;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Description = 'Type a descriptive title or name for the unit of measure.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(4; UoMScheduleId; Guid)
        {
            Caption = 'Unit Schedule';
            Description = 'Choose the ID of the unit group that the unit is associated with.';
            ExternalAccess = Insert;
            ExternalName = 'uomscheduleid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uomschedule".UoMScheduleId;
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Description = 'Unit quantity for the product.';
            ExternalName = 'quantity';
            ExternalType = 'Decimal';
        }
        field(6; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the unit was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(7; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the unit.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(8; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the unit.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(9; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the unit was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(10; IsScheduleBaseUoM; Boolean)
        {
            Caption = 'Is Schedule Base Unit';
            Description = 'Tells whether the unit is the base unit for the associated unit group.';
            ExternalAccess = Read;
            ExternalName = 'isschedulebaseuom';
            ExternalType = 'Boolean';
        }
        field(11; BaseUoMName; Text[100])
        {
            CalcFormula = lookup("CRM Uom".Name where(UoMId = field(BaseUoM)));
            Caption = 'BaseUoMName';
            Description = 'Name of the base unit for the product, such as a two-liter bottle.';
            ExternalAccess = Read;
            ExternalName = 'baseuomname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(12; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(13; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(14; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the unit.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(15; OrganizationId; Guid)
        {
            Caption = 'Organization ';
            Description = 'Unique identifier of the organization associated with the unit of measure.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(16; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(17; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(18; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the uom.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(19; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(20; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the uom.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(21; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; UoMId)
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name)
        {
        }
    }
}

