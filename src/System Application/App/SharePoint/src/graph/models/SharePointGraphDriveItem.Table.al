// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Represents a SharePoint drive item (file or folder) as returned by Microsoft Graph API.
/// </summary>
table 9132 "SharePoint Graph Drive Item"
{
    Access = Public;
    TableType = Temporary;
    DataClassification = SystemMetadata;
    InherentEntitlements = X;
    InherentPermissions = X;
    Extensible = false;

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
            Description = 'Unique identifier of the drive item';
        }
        field(2; DriveId; Text[250])
        {
            Caption = 'Drive Id';
            Description = 'ID of the parent drive';
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            Description = 'Name of the item (file or folder name)';
        }
        field(4; ParentId; Text[250])
        {
            Caption = 'Parent Id';
            Description = 'ID of the parent folder';
        }
        field(5; Path; Text[2048])
        {
            Caption = 'Path';
            Description = 'Path to the item from the drive root';
        }
        field(6; WebUrl; Text[2048])
        {
            Caption = 'Web URL';
            Description = 'URL to view the item in a web browser';
        }
        field(7; DownloadUrl; Text[2048])
        {
            Caption = 'Download URL';
            Description = 'URL to download the item content';
        }
        field(8; CreatedDateTime; DateTime)
        {
            Caption = 'Created Date Time';
            Description = 'Date and time when the item was created';
        }
        field(9; LastModifiedDateTime; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Description = 'Date and time when the item was last modified';
        }
        field(10; Size; BigInteger)
        {
            Caption = 'Size';
            Description = 'Size of the item in bytes';
        }
        field(11; IsFolder; Boolean)
        {
            Caption = 'Is Folder';
            Description = 'Indicates if the item is a folder';
        }
        field(12; FileType; Text[50])
        {
            Caption = 'File Type';
            Description = 'Type/extension of the file';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; DriveId, Id)
        {
        }
    }
}