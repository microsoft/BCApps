#if not CLEANSCHEMA33
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 10500 "Postcode Notif. Memory"
{
    Caption = 'Postcode Notification Memory';
    DataClassification = CustomerContent;
    ObsoleteReason = 'GetAddress.io UK Postcodes extension is discontinued';
#if not CLEAN30
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '33.0';
#endif

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
