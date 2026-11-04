// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if SERVICEMANAGEMENT_BE
namespace Microsoft.Service.Document;

tableextension 11300 "Service Header BE" extends "Service Header"
{
    fields
    {
        field(11310; "Enterprise No."; Text[50])
        {
            Caption = 'Enterprise No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
    }
}
#endif
