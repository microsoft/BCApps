// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

enum 5970 "Service Contract Change Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Line Added") { Caption = 'Line Added'; }
    value(1; "Line Deleted") { Caption = 'Line Deleted'; }
    value(2; "Contract Signed") { Caption = 'Contract Signed'; }
    value(3; "Contract Canceled") { Caption = 'Contract Canceled'; }
    value(4; "Manual Update") { Caption = 'Manual Update'; }
    value(5; "Price Update") { Caption = 'Price Update'; }
}
