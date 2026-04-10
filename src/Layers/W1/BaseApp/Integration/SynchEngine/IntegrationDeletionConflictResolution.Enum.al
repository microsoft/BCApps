// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

#pragma warning disable AL0659
enum 5337 "Integration Deletion Conflict Resolution"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = ' '; }
    value(1; "Restore Records") { Caption = 'Restore records'; }
    value(2; "Remove Coupling") { Caption = 'Delete coupling'; }
}