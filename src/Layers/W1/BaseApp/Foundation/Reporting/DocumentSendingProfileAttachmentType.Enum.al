// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

#pragma warning disable AL0659
enum 63 "Document Sending Profile Attachment Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "PDF") { Caption = 'PDF'; }
    value(1; "Electronic Document") { Caption = 'Electronic Document'; }
    value(2; "PDF & Electronic Document") { Caption = 'PDF & Electronic Document'; }
}
