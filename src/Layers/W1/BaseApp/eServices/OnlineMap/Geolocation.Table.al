// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

table 806 Geolocation
{
    Caption = 'Geolocation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; Latitude; Decimal)
        {
            Caption = 'Latitude';
            AutoFormatType = 0;
        }
        field(3; Longitude; Decimal)
        {
            Caption = 'Longitude';
            AutoFormatType = 0;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
