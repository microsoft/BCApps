// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 5376 "CDS BC Table Relation"
{
    ExternalName = 'dyn365bc_syntheticrelation';
    TableType = CRM;
    Description = 'Contains the relations between physical and virtual tables in Business Central.';
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; dyn365bc_syntheticrelationId; Guid)
        {
            ExternalName = 'dyn365bc_syntheticrelationId';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'The unique identifier of the relation.';
            Caption = 'Synthetic Relation';
            DataClassification = SystemMetadata;
        }
        field(2; dyn365bc_nativeentity; Text[100])
        {
            ExternalName = 'dyn365bc_nativeentity';
            ExternalType = 'String';
            Description = 'The native table name.';
            Caption = 'Native Table';
            DataClassification = SystemMetadata;
        }
        field(3; dyn365bc_nativeentitykey; Text[100])
        {
            ExternalName = 'dyn365bc_nativeentitykey';
            ExternalType = 'String';
            Description = 'The native table key.';
            Caption = 'Native Table Key';
            DataClassification = SystemMetadata;
        }
        field(4; dyn365bc_referencedattribname1; Text[100])
        {
            ExternalName = 'dyn365bc_referencedattribname1';
            ExternalType = 'String';
            Description = 'The name of the first referenced attribute.';
            Caption = 'Referenced Attribute 1';
            DataClassification = SystemMetadata;
        }
        field(5; dyn365bc_referencedattribname2; Text[100])
        {
            ExternalName = 'dyn365bc_referencedattribname2';
            ExternalType = 'String';
            Description = 'The name of the second referenced attribute.';
            Caption = 'Referenced Attribute 2';
            DataClassification = SystemMetadata;
        }
        field(6; dyn365bc_referencedattribname3; Text[100])
        {
            ExternalName = 'dyn365bc_referencedattribname3';
            ExternalType = 'String';
            Description = 'The name of the third referenced attribute.';
            Caption = 'Referenced Attribute 3';
            DataClassification = SystemMetadata;
        }
        field(7; dyn365bc_referencingattribname1; Text[100])
        {
            ExternalName = 'dyn365bc_referencingattribname1';
            ExternalType = 'String';
            Description = 'The name of the first referencing attribute.';
            Caption = 'Referencing Attribute 1';
            DataClassification = SystemMetadata;
        }
        field(8; dyn365bc_referencingattribname2; Text[100])
        {
            ExternalName = 'dyn365bc_referencingattribname2';
            ExternalType = 'String';
            Description = 'The name of the second referencing attribute.';
            Caption = 'Referencing Attribute 2';
            DataClassification = SystemMetadata;
        }
        field(9; dyn365bc_referencingattribname3; Text[100])
        {
            ExternalName = 'dyn365bc_referencingattribname3';
            ExternalType = 'String';
            Description = 'The name of the third referencing attribute.';
            Caption = 'Referencing Attribute 3';
            DataClassification = SystemMetadata;
        }
        field(10; name; Text[100])
        {
            ExternalName = 'name';
            ExternalType = 'String';
            Description = 'The name of the relation.';
            Caption = 'Table Relation Name';
            DataClassification = SystemMetadata;
        }
        field(11; dyn365bc_virtualentity; Text[100])
        {
            ExternalName = 'dyn365bc_virtualentity';
            ExternalType = 'String';
            Description = 'The virtual table name.';
            Caption = 'Virtual Table';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; dyn365bc_syntheticrelationId)
        {
            Clustered = true;
        }
        key(Name; name)
        {
        }
    }
}
