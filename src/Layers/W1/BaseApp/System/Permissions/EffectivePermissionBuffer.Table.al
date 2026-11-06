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
        field(11; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the user security ID.';
        }
        field(2; "User Name"; Code[50])
        {
            Caption = 'User Name';
            ToolTip = 'Specifies the user name.';
        }
        field(3; "Object Type"; Option)
        {
            Caption = 'Object Type';
            ToolTip = 'Specifies the object type.';
            OptionMembers = "Table Data","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System",,,,,,,,,;
            OptionCaption = 'Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System,,,,,,,,,';
        }
        field(4; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            ToolTip = 'Specifies the object ID.';
        }
        field(5; "Object Name"; Text[30])
        {
            Caption = 'Object Name';
            ToolTip = 'Specifies the object name.';
        }
        field(6; "Read Permission"; Option)
        {
            Caption = 'Read Permission';
            ToolTip = 'Specifies information about whether the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(7; "Insert Permission"; Option)
        {
            Caption = 'Insert Permission';
            ToolTip = 'Specifies information about whether the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(8; "Modify Permission"; Option)
        {
            Caption = 'Modify Permission';
            ToolTip = 'Specifies information about whether the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(9; "Delete Permission"; Option)
        {
            Caption = 'Delete Permission';
            ToolTip = 'Specifies information about whether the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
        field(10; "Execute Permission"; Option)
        {
            Caption = 'Execute Permission';
            ToolTip = 'Specifies information about whether the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
            OptionMembers = " ",Yes,Indirect;
            OptionCaption = ' ,Yes,Indirect';
        }
    }

    keys
    {
        key(PK; "Object Type", "Object ID", Company, "User Name")
        {
            Clustered = true;
        }
    }
}