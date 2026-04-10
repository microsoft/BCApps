// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 113 "Matrix Page Step Type"
{
    Extensible = true;

    value(0; "Initial") { Caption = 'Initial'; }
    value(1; "Previous") { Caption = 'Previous'; }
    value(2; "Same") { Caption = 'Same'; }
    value(3; "Next") { Caption = 'Next'; }
    value(4; "PreviousColumn") { Caption = 'PreviousColumn'; }
    value(5; "NextColumn") { Caption = 'NextColumn'; }
}
