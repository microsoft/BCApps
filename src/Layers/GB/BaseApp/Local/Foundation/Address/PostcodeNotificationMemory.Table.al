#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

#if CLEAN28
#pragma warning disable AS0103, PTE0004 // Accepted: this obsolete compatibility table is retained until schema cleanup and is intentionally excluded from current permission sets. Tracked by AB#640773.
#endif
table 10501 "Postcode Notification Memory"
#if CLEAN28
#pragma warning restore AS0103, PTE0004
#endif
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
