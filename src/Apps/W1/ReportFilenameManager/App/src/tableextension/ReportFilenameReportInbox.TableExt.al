// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;

tableextension 8125 "Report Filename Report Inbox" extends "Report Inbox"
{
    // A scheduled report is saved into the row's Report Output stream, and at download Base
    // Application builds the name from Report Name or Description (GetFileNameWithoutExtension).
    // The pattern's name is stored here when the row is inserted.

    fields
    {
        field(8125; "File Name"; Text[250])
        {
            Caption = 'File Name';
            ToolTip = 'Specifies the file name this entry downloads under, as decided by the file name patterns when the report was produced. If it is blank, the file gets Business Central''s own file name.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}
