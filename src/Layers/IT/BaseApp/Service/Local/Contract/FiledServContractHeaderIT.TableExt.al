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
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
            TableRelation = "Activity Code".Code;
        }
    }
}