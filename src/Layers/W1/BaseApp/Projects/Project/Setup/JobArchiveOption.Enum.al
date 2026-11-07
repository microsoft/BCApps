// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

enum 1005 "Job Archive Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Never) { Caption = 'Never'; }
    value(1; Question) { Caption = 'Question'; }
    value(2; Always) { Caption = 'Always'; }
}
