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
        field(8750; "Stored Externally"; Boolean)
        {
            Caption = 'Stored Externally';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies if the file has been stored in external storage.';
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
        field(8753; "Stored Internally"; Boolean)
        {
            Caption = 'Stored in DB';
            DataClassification = SystemMetadata;
            InitValue = true;
            Editable = false;
            ToolTip = 'Specifies if the file is stored in internal database storage.';
        }
        field(8754; "Source Environment Hash"; Text[32])
        {
            Caption = 'Source Environment Hash';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies a hash identifying the tenant, environment, and company that originally uploaded this file to external storage.';
        }
        field(8755; "Skip Delete On Copy"; Boolean)
        {
            Caption = 'Skip Delete On Copy';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether to skip deletion of this attachment from external storage.';
        }
    }

    /// <summary>
    /// Marks the document attachment as not uploaded to external storage.
    /// Clears all external storage related fields.
    /// </summary>
    internal procedure MarkAsNotUploadedToExternal()
    begin
        "Stored Externally" := false;
        "External Upload Date" := 0DT;
        "External File Path" := '';
        Modify();
    end;

    /// <summary>
    /// Marks the document attachment as deleted from internal storage.
    /// Clears the Document Reference ID and sets the stored internally flag to false.
    /// </summary>
    internal procedure MarkAsDeletedInternally()
    begin
        Clear("Document Reference ID");
        "Stored Internally" := false;
        Modify();
    end;
}
