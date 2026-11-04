// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if SERVICEMANAGEMENT_IT
namespace Microsoft.Service.Contract;

using Microsoft.Utilities;

tableextension 12151 "Service Contract Header IT" extends "Service Contract Header"
{
    fields
    {
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
            TableRelation = "Activity Code".Code;
        }
    }
}
#endif
