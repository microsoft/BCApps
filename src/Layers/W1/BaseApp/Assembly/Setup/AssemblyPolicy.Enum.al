// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Setup;

enum 910 "Assembly Policy"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Assemble-to-Stock") { Caption = 'Assemble-to-Stock'; }
    value(1; "Assemble-to-Order") { Caption = 'Assemble-to-Order'; }
}
