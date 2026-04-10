// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using System.Utilities;

/// <summary>
/// Stores icon images associated with different sales document types and statuses.
/// </summary>
table 2100 "Sales Document Icon"
{
    Caption = 'Sales Document Icon';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of sales document status for which the icon is displayed.
        /// </summary>
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Quote,Draft Invoice,Unpaid Invoice,Canceled Invoice,Paid Invoice,Overdue Invoice';
            OptionMembers = Quote,"Draft Invoice","Unpaid Invoice","Canceled Invoice","Paid Invoice","Overdue Invoice";
        }
        /// <summary>
        /// Contains the icon image displayed for the sales document status.
        /// </summary>
        field(2; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
        /// <summary>
        /// Specifies the reference code for the media resource containing the icon.
        /// </summary>
        field(3; "Media Resources Ref"; Code[50])
        {
            Caption = 'Media Resources Ref';
        }
    }

    keys
    {
        key(Key1; Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Sets the document icon from an input stream.
    /// </summary>
    /// <param name="MediaResourceRef">The reference code for the media resource.</param>
    /// <param name="MediaInstream">The input stream containing the icon data.</param>
    [Scope('OnPrem')]
    procedure SetIconFromInstream(MediaResourceRef: Code[50]; MediaInstream: InStream)
    var
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if not MediaResourcesMgt.InsertMediaFromInstream(MediaResourceRef, MediaInstream) then
            exit;

        Validate("Media Resources Ref", MediaResourceRef);
        Modify(true);
    end;

    /// <summary>
    /// Sets the document icon from a file.
    /// </summary>
    /// <param name="MediaResourceRef">The reference code for the media resource.</param>
    /// <param name="FileName">The file path of the icon to import.</param>
    [Scope('OnPrem')]
    procedure SetIconFromFile(MediaResourceRef: Code[50]; FileName: Text)
    var
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if not MediaResourcesMgt.InsertMediaSetFromFile(MediaResourceRef, FileName) then
            exit;

        Validate("Media Resources Ref", MediaResourceRef);
        Modify(true);
    end;
}

