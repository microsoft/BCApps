// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Represents a SharePoint drive (document library) as returned by Microsoft Graph API.
/// </summary>
table 9133 "SharePoint Graph Drive"
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
            Description = 'Unique identifier of the drive';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            Description = 'Name of the drive (document library)';
            DataClassification = CustomerContent;
        }
        field(3; DriveType; Text[50])
        {
            Caption = 'Drive Type';
            Description = 'Type of drive (personal, business, documentLibrary)';
        }
        field(4; WebUrl; Text[2048])
        {
            Caption = 'Web URL';
            Description = 'URL to access the drive in a web browser';
        }
        field(5; OwnerName; Text[250])
        {
            Caption = 'Owner Name';
            Description = 'Display name of the drive owner';
            DataClassification = CustomerContent;
        }
        field(6; OwnerEmail; Text[250])
        {
            Caption = 'Owner Email';
            Description = 'Email address of the drive owner';
            DataClassification = CustomerContent;
        }
        field(7; CreatedDateTime; DateTime)
        {
            Caption = 'Created Date Time';
            Description = 'Date and time when the drive was created';
        }
        field(8; LastModifiedDateTime; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Description = 'Date and time when the drive was last modified';
        }
        field(9; Description; Text[2048])
        {
            Caption = 'Description';
            Description = 'Description of the drive';
            DataClassification = CustomerContent;
        }
        field(10; QuotaTotal; BigInteger)
        {
            Caption = 'Quota Total';
            Description = 'Total storage quota in bytes';
        }
        field(11; QuotaUsed; BigInteger)
        {
            Caption = 'Quota Used';
            Description = 'Used storage in bytes';
        }
        field(12; QuotaRemaining; BigInteger)
        {
            Caption = 'Quota Remaining';
            Description = 'Remaining storage quota in bytes';
        }
        field(13; QuotaState; Text[50])
        {
            Caption = 'Quota State';
            Description = 'State of the quota (normal, nearing, critical, exceeded)';
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