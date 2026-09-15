// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

enum 1023 "Job Planning Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Resource") { Caption = 'Resource'; }
    value(1; Item) { Caption = 'Item'; }
    value(2; "G/L Account") { Caption = 'G/L Account'; }
    value(3; "Text") { Caption = 'Text'; }
}
