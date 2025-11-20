// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

#pragma warning disable AL0659
enum 353 "Default Dimension Value Posting Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Code Mandatory") { Caption = 'Code Mandatory'; }
    value(2; "Same Code") { Caption = 'Same Code'; }
    value(3; "No Code") { Caption = 'No Code'; }
}
