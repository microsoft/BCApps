// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

enum 1004 "Task Billing Method"
{
    Extensible = false;

    value(0; "One customer") { Caption = 'One customer'; }
    value(1; "Multiple customers") { Caption = 'Multiple customers'; }
}
