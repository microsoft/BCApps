// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

enum 1174 "Document Attachment File Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Image") { Caption = 'Image'; }
    value(2; "PDF") { Caption = 'PDF'; }
    value(3; "Word") { Caption = 'Word'; }
    value(4; "Excel") { Caption = 'Excel'; }
    value(5; "PowerPoint") { Caption = 'PowerPoint'; }
    value(6; "Email") { Caption = 'Email'; }
    value(7; "XML") { Caption = 'XML'; }
    value(8; "Other") { Caption = 'Other'; }
}
