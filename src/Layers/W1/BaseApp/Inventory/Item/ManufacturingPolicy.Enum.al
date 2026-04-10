// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

enum 5442 "Manufacturing Policy"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Make-to-Stock") { Caption = 'Make-to-Stock'; }
    value(1; "Make-to-Order") { Caption = 'Make-to-Order'; }
}
