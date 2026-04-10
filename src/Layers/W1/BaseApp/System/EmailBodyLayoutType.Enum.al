// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Email;

enum 87 "Email Body Layout Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Custom Report Layout") { Caption = 'Custom Report Layout'; }
    value(1; "HTML Layout") { Caption = 'HTML Layout'; }
}
