// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

enum 5079 "Setup Attachment Storage Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Embedded") { Caption = 'Embedded'; }
    value(1; "Disk File") { Caption = 'Disk File'; }
}
