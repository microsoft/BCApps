// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Represents a SharePoint list as returned by Microsoft Graph API.
/// </summary>
table 9130 "SharePoint Graph List"
{
    Access = Public;
    TableType = Temporary;
    DataClassification = SystemMetadata; // Data classification is SystemMetadata as the table is temporary

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
            DataClassification = CustomerContent;
            Description = 'Unique identifier of the list';
        }
        field(2; DisplayName; Text[250])
        {
            Caption = 'Display Name';
            DataClassification = CustomerContent;
            Description = 'Name of the list for display purposes';
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            Description = 'Name of the list';
        }
        field(4; Description; Text[2048])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            Description = 'Description of the list';
        }
        field(5; WebUrl; Text[2048])
        {
            Caption = 'Web URL';
            DataClassification = CustomerContent;
            Description = 'URL to view the list in a web browser';
        }
        field(6; Template; Text[100])
        {
            Caption = 'Template';
            DataClassification = CustomerContent;
            Description = 'List template used to create this list (genericList, documentLibrary, etc.)';
        }
        field(7; ListItemEntityType; Text[250])
        {
            Caption = 'List Item Entity Type';
            DataClassification = CustomerContent;
            Description = 'Entity type name for list items in this list';
        }
        field(8; DriveId; Text[250])
        {
            Caption = 'Drive ID';
            DataClassification = CustomerContent;
            Description = 'Drive ID (for document libraries)';
        }
        field(9; LastModifiedDateTime; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = CustomerContent;
            Description = 'Date and time when the list was last modified';
        }
        field(10; CreatedDateTime; DateTime)
        {
            Caption = 'Created Date Time';
            DataClassification = CustomerContent;
            Description = 'Date and time when the list was created';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }
}