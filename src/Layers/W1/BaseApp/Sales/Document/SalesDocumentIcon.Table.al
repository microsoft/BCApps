// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using System.Utilities;

table 2100 "Sales Document Icon"
{
    Caption = 'Sales Document Icon';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Quote,Draft Invoice,Unpaid Invoice,Canceled Invoice,Paid Invoice,Overdue Invoice';
            OptionMembers = Quote,"Draft Invoice","Unpaid Invoice","Canceled Invoice","Paid Invoice","Overdue Invoice";
        }
        field(2; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
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

