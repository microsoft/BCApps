// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7221 "EA Corp Card Auth Type"
{
    Access = Internal;
    Caption = 'Corp Card Auth Type';

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; OAuth2)
    {
        Caption = 'OAuth2';
    }
    value(2; ApiKey)
    {
        Caption = 'API Key';
    }
    value(3; Basic)
    {
        Caption = 'Basic';
    }
    value(4; Cert)
    {
        Caption = 'Certificate';
    }
}