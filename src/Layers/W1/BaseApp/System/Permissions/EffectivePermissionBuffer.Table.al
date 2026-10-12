// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

table 9884 "Effective Permission Buffer"
{
    Caption = 'Effective Permission Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; Company; Text[30])
        {
            Caption = 'Company Name';
            ToolTip = 'Specifies the company name.';
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the user security ID.';
        }
        field(3; "User Name"; Code[50])
        {
            Caption = 'User Name';
            ToolTip = 'Specifies the user name.';
        }
        field(4; "Object Type"; Option)
        {
            Caption = 'Object Type';
            ToolTip = 'Specifies the object type.';
            OptionMembers = "Table Data","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System",,,,,,,,,;
            OptionCaption = 'Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System,,,,,,,,,';
        }
        field(5; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            ToolTip = 'Specifies the object ID.';
        }
        field(6; "Object Name"; Text[249])
        {
            Caption = 'Object Name';
            ToolTip = 'Specifies the object name.';
        }
        field(7; "Read Permission"; Option)
        {
            Caption = 'Read Permission';
            ToolTip = 'Specifies information about whether the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(8; "Insert Permission"; Option)
        {
            Caption = 'Insert Permission';
            ToolTip = 'Specifies information about whether the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(9; "Modify Permission"; Option)
        {
            Caption = 'Modify Permission';
            ToolTip = 'Specifies information about whether the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(10; "Delete Permission"; Option)
        {
            Caption = 'Delete Permission';
            ToolTip = 'Specifies information about whether the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(11; "Execute Permission"; Option)
        {
            Caption = 'Execute Permission';
            ToolTip = 'Specifies information about whether the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
    }

    keys
    {
        key(PK; Company, "User Name", "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }
}