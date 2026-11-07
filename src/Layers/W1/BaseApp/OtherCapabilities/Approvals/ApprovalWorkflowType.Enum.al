// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

enum 466 "Approval Workflow Type"
{
    Extensible = true;

    value(0; Sales)
    {
        Caption = 'Sales';
    }
    value(1; Purchase)
    {
        Caption = 'Purchase';
    }
    value(2; Request)
    {
        Caption = 'Request';
    }
}