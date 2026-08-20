// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10970 "FR E-Invoice Message Type"
{
    Access = Public;

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
    value(4; "Technical Rejected")
    {
        Caption = 'Technical Rejected';
    }
    value(5; Accepted)
    {
        Caption = 'Accepted';
    }
}