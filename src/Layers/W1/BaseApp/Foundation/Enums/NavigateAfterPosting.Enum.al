// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 41 "Navigate After Posting"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Posted Document") { Caption = 'Posted Document'; }
    value(1; "New Document") { Caption = 'New Document'; }
    value(2; "Do Nothing") { Caption = 'Do Nothing'; }
}
