// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

enum 220 "Business Unit File Format"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Version 4.00 or Later (.xml)") { Caption = 'Version 4.00 or Later (.xml)'; }
    value(1; "Version 3.70 or Earlier (.txt)") { Caption = 'Version 3.70 or Earlier (.txt)'; }
}
