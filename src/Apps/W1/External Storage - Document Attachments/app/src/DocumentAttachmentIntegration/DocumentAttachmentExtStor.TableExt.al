// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Extends the Document Attachment table with external storage functionality.
/// Adds fields and procedures to track attachments in external storage systems.
/// </summary>
tableextension 8750 "Document Attachment Ext.Stor." extends "Document Attachment"
{
    fields
    {
        field(8750; "Uploaded Externally"; Boolean)
        {
            Caption = 'Uploaded Externally';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies if the file has been uploaded to external storage.';
        }
        field(8751; "External Upload Date"; DateTime)
        {
            Caption = 'External Upload Date';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies when the file was uploaded to external storage.';
        }
        field(8752; "External File Path"; Text[2048])
        {
            Caption = 'External File Path';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the path to the file in external storage.';
        }
        field(8753; "Deleted Internally"; Boolean)
        {
            Caption = 'Deleted Internally';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the value of the Deleted Internally field.';
        }
    }

    /// <summary>
    /// Marks the document attachment as not uploaded to external storage.
    /// Clears all external storage related fields.
    /// </summary>
    internal procedure MarkAsNotUploadedToExternal()
    begin
        "Uploaded Externally" := false;
        "External Upload Date" := 0DT;
        "External File Path" := '';
        Modify();
    end;

    /// <summary>
    /// Marks the document attachment as deleted from internal storage.
    /// Clears the Document Reference ID and sets the deleted internally flag.
    /// </summary>
    internal procedure MarkAsDeletedInternally()
    begin
        Clear("Document Reference ID");
        "Deleted Internally" := true;
        Modify();
    end;
}
