// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

enum 5916 "Service Doc. Release Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Open") { Caption = 'Open'; }
    value(1; "Released to Ship") { Caption = 'Released to Ship'; }
}
