// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

enum 129 "IC Direction Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Outgoing") { Caption = 'Outgoing'; }
    value(1; "Incoming") { Caption = 'Incoming'; }
}
