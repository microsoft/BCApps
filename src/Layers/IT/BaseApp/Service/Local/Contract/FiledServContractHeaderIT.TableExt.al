// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Utilities;

tableextension 12150 "Filed Serv. Contract Header IT" extends "Filed Service Contract Header"
{
    fields
    {
#if not CLEANSCHEMA33
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
#if not CLEAN30
            TableRelation = "Activity Code".Code;
#endif
            ObsoleteReason = 'Replaced by the Business Activity Code field.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
        }
#endif
    }
}