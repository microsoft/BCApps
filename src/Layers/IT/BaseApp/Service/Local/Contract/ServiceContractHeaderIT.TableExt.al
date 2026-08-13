// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Utilities;

tableextension 12151 "Service Contract Header IT" extends "Service Contract Header"
{
    fields
    {
#if not CLEAN29
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
            TableRelation = "Activity Code".Code;
            ObsoleteReason = 'Replaced by the Business Activity Code field.';
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
        }
#endif
    }
}