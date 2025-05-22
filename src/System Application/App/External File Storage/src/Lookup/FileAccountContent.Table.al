// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

table 9455 "File Account Content"
{
    Caption = 'File Account Content';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    Extensible = false;

    fields
    {
        field(1; "Type"; Enum "Ext. File Storage File Type")
        {
            Caption = 'Type';
        }
        field(2; Name; Text[2048])
        {
            Caption = 'Name';
        }
        field(10; "Parent Directory"; Text[2048])
        {
            Caption = 'Parent Directory';
        }
    }
    keys
    {
        key(PK; "Type", Name)
        {
            Clustered = true;
        }
    }
}
