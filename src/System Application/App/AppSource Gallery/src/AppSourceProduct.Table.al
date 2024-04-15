// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

/// <summary>
/// Represents an except of a product definition in AppSource.
/// </summary>
table 2515 "AppSource Product"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    TableType = Temporary;

    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; UniqueProductID; Text[200])
        {
            Caption = 'Unique Product ID';
        }
        field(2; DisplayName; Text[250])
        {
            Caption = 'Name';
        }
        field(4; PublisherID; Text[200])
        {
            Caption = 'Publisher ID';
        }
        field(5; PublisherDisplayName; Text[250])
        {
            Caption = 'Publisher Name';
        }
        field(6; PublisherType; Text[200])
        {
            Caption = 'Publisher Type';
        }
        field(8; RatingAverage; Decimal)
        {
            Caption = 'Average Rating';
        }
        field(9; RatingCount; Integer)
        {
            Caption = 'No. Of Ratings';
        }
        field(10; ProductType; Text[200])
        {
            Caption = 'Product Type';
        }
        field(11; AppID; Guid)
        {
            Caption = 'Application Identifier';
        }
        field(12; Popularity; Decimal)
        {
            Caption = 'Popularity';
        }
        field(14; LastModifiedDateTime; DateTime)
        {
            Caption = 'Last Modified Date Time';
        }
    }

    keys
    {
        key(UniqueID; UniqueProductID)
        {

        }
        key(DefaultSorting; DisplayName, PublisherDisplayName)
        {

        }
        key(Rating; RatingAverage, DisplayName, PublisherDisplayName)
        {

        }
        key(Popularity; Popularity, DisplayName, PublisherDisplayName)
        {

        }
        key(LastModified; LastModifiedDateTime, DisplayName, PublisherDisplayName)
        {

        }
        key(PublisherID; PublisherID, DisplayName, PublisherDisplayName)
        {

        }
    }

    fieldgroups
    {
        fieldgroup(Brick; PublisherDisplayName, DisplayName, Popularity, RatingAverage)
        {
        }
    }
}