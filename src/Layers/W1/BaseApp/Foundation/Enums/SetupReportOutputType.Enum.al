// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 483 "Setup Report Output Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "PDF") { Caption = 'PDF'; }
    value(3; "Print") { Caption = 'Print'; }
}
