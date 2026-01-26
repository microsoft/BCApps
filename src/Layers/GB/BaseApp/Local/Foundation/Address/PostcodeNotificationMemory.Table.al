#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 10501 "Postcode Notification Memory"
{
    Caption = 'Postcode Notification Memory';
    DataClassification = CustomerContent;
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
    ObsoleteReason = 'Table has been moved to the GetAddress.io UK Postcodes.';

    fields
    {
        field(1; UserId; Code[50])
        {
            Caption = 'UserId';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; UserId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif

