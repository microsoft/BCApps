// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5385 "CRM Annotation"
{
    // Dynamics CRM Version: 9.1.0.643

    Caption = 'Note';
    Description = 'Note that is attached to one or more objects, including other notes.';
    ExternalName = 'annotation';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; AnnotationId; Guid)
        {
            Caption = 'Note';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the note.';
            ExternalAccess = Insert;
            ExternalName = 'annotationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; ObjectId; Guid)
        {
            Caption = 'Regarding';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the object with which the note is associated.';
            ExternalAccess = Insert;
            ExternalName = 'objectid';
            ExternalType = 'Lookup';
            TableRelation = if (ObjectTypeCode = const(opportunity)) "CRM Opportunity".OpportunityId
            else
            if (ObjectTypeCode = const(product)) "CRM Product".ProductId
            else
            if (ObjectTypeCode = const(incident)) "CRM Incident".IncidentId
            else
            if (ObjectTypeCode = const(quote)) "CRM Quote".QuoteId
            else
            if (ObjectTypeCode = const(salesorder)) "CRM Salesorder".SalesOrderId
            else
            if (ObjectTypeCode = const(invoice)) "CRM Invoice".InvoiceId
            else
            if (ObjectTypeCode = const(contract)) "CRM Contract".ContractId;
        }
        field(3; Subject; Text[250])
        {
            Caption = 'Title';
            DataClassification = SystemMetadata;
            Description = 'Subject associated with the note.';
            ExternalName = 'subject';
            ExternalType = 'String';
        }
        field(4; IsDocument; Boolean)
        {
            Caption = 'Is Document';
            DataClassification = SystemMetadata;
            Description = 'Specifies whether the note is an attachment.';
            ExternalName = 'isdocument';
            ExternalType = 'Boolean';
        }
        field(5; NoteText; BLOB)
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            Description = 'Text of the note.';
            ExternalName = 'notetext';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(6; MimeType; Text[250])
        {
            Caption = 'Mime Type';
            DataClassification = SystemMetadata;
            Description = 'MIME type of the note''s attachment.';
            ExternalName = 'mimetype';
            ExternalType = 'String';
        }
        field(7; LangId; Text[2])
        {
            Caption = 'Language ID';
            DataClassification = SystemMetadata;
            Description = 'Language identifier for the note.';
            ExternalName = 'langid';
            ExternalType = 'String';
        }
        field(8; DocumentBody; Text[250])
        {
            Caption = 'Document';
            DataClassification = SystemMetadata;
            Description = 'Contents of the note''s attachment.';
            ExternalName = 'documentbody';
            ExternalType = 'String';
        }
        field(9; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the note was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(10; FileSize; Integer)
        {
            Caption = 'File Size (Bytes)';
            DataClassification = SystemMetadata;
            Description = 'File size of the note.';
            ExternalAccess = Read;
            ExternalName = 'filesize';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(11; FileName; Text[250])
        {
            Caption = 'File Name';
            DataClassification = SystemMetadata;
            Description = 'File name of the note.';
            ExternalName = 'filename';
            ExternalType = 'String';
        }
        field(12; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the note was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(13; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            DataClassification = SystemMetadata;
            Description = 'Version number of the note.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(14; StepId; Text[32])
        {
            Caption = 'Step Id';
            DataClassification = SystemMetadata;
            Description = 'workflow step id associated with the note.';
            ExternalName = 'stepid';
            ExternalType = 'String';
        }
        field(15; OverriddenCreatedOn; DateTime)
        {
            Caption = 'Record Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(16; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(17; ObjectTypeCode; Option)
        {
            Caption = 'ObjectTypeCode';
            DataClassification = SystemMetadata;
            Description = 'Type of entity with which the note is associated.';
            ExternalAccess = Insert;
            ExternalName = 'objecttypecode';
            ExternalType = 'EntityName';
            OptionCaption = ' ,lead,product,bookableresource,bookableresourcebooking,bookableresourcebookingheader,bookableresourcecategoryassn,bookableresourcecharacteristic,bookableresourcegroup,campaign,list,contract,contractdetail,entitlement,entitlementchannel,entitlementtemplate,equipment,incident,resourcespec,service,invoice,opportunity,quote,salesorder,competitor', Locked = true;
            OptionMembers = " ",lead,product,bookableresource,bookableresourcebooking,bookableresourcebookingheader,bookableresourcecategoryassn,bookableresourcecharacteristic,bookableresourcegroup,campaign,list,contract,contractdetail,entitlement,entitlementchannel,entitlementtemplate,equipment,incident,resourcespec,service,invoice,opportunity,quote,salesorder,competitor;
        }
    }

    keys
    {
        key(Key1; AnnotationId)
        {
            Clustered = true;
        }
        key(Key2; Subject)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Subject)
        {
        }
    }
}

