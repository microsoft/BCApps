// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

enum 904 "Assemble-to-Order Link Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ''; }
    value(1; "Sale") { Caption = 'Sale'; }
    value(2; "Job") { Caption = 'Project'; }
}
