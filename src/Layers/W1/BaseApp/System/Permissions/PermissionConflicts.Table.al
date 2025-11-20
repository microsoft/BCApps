namespace System.Security.AccessControl;

using System.Reflection;

table 5557 "Permission Conflicts"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(3; "Object Type"; Option)
        {
            DataClassification = SystemMetadata;
            Caption = 'Object Type';
            OptionCaption = 'Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
            OptionMembers = "Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        }
        field(4; "Object ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Object ID';
        }
        field(5; "Object Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = field("Object Type"),
                                                                           "Object ID" = field("Object ID")));
            Caption = 'Object Name';
            FieldClass = FlowField;
        }
        field(6; "Read Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Read Permission';
            InitValue = Direct;
        }
        field(7; "Insert Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Insert Permission';
            InitValue = Direct;
        }
        field(8; "Modify Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Modify Permission';
            InitValue = Direct;
        }
        field(9; "Delete Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Delete Permission';
            InitValue = Direct;
        }
        field(10; "Execute Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Execute Permission';
            InitValue = Direct;
        }
        field(11; "Entitlement Read Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Read Permission';
            InitValue = Direct;
        }
        field(12; "Entitlement Insert Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Insert Permission';
            InitValue = Direct;
        }
        field(13; "Entitlement Modify Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Modify Permission';
            InitValue = Direct;
        }
        field(14; "Entitlement Delete Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Delete Permission';
            InitValue = Direct;
        }
        field(15; "Entitlement Execute Permission"; Enum "Permission")
        {
            DataClassification = SystemMetadata;
            Caption = 'Execute Permission';
            InitValue = Direct;
        }
        field(16; "License Type"; Enum Licenses)
        {
            DataClassification = SystemMetadata;
            Caption = 'License';
        }
        field(17; "User Defined"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'User Defined';
        }
    }

    keys
    {
        key(PK; "Object ID", "Object Type")
        {
            Clustered = true;
        }
    }

}