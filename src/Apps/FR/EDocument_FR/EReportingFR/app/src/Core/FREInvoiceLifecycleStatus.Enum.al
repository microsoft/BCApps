// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10973 "FR E-Invoice Lifecycle Status"
{
    Extensible = false;

    value(0; Collected)
    {
        Caption = 'Collected';
    }
    value(1; "Negative Collected")
    {
        Caption = 'Negative Collected';
    }
    value(2; Refused)
    {
        Caption = 'Refused';
    }
    value(3; Submitted)
    {
        Caption = 'Submitted';
    }
    value(4; Rejected)
    {
        Caption = 'Rejected';
    }
    value(5; Accepted)
    {
        Caption = 'Accepted';
    }
}