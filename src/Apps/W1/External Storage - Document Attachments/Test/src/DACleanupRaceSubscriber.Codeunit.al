// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.ExternalStorage.DocumentAttachments;
using Microsoft.Foundation.Attachment;
using System.TestLibraries.ExternalFileStorage;
using System.Utilities;

codeunit 136822 "DA Cleanup Race Subscriber"
{
    EventSubscriberInstance = Manual;

    procedure SetMutation(NewMutation: Enum "DA Cleanup Test Mutation")
    begin
        Mutation := NewMutation;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"DA Internal Cleanup Worker", OnAfterReadback, '', false, false)]
    local procedure MutateAfterReadback(AttachmentSystemId: Guid)
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        Setup: Record "DA External Storage Setup";
        Account: Record "Test File Account";
        CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
        Blob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        OriginalName: Text[250];
    begin
        Attachment.GetBySystemId(AttachmentSystemId);
        Entry.Get(AttachmentSystemId);
        case Mutation of
            Mutation::Cancel:
                CleanupManagement.CancelCleanup(AttachmentSystemId);
            Mutation::Path:
                begin
                    Attachment."External File Path" += '.changed';
                    Attachment.Modify();
                end;
            Mutation::Configuration:
                begin
                    Account.Get(Entry."Account ID");
                    OriginalName := Account.Name;
                    Account.Name := 'Changed';
                    Account.Modify();
                    Account.Name := OriginalName;
                    Account.Modify();
                end;
            Mutation::Media:
                begin
                    Blob.CreateOutStream(OutStream);
                    OutStream.WriteText('New internal attachment content');
                    Blob.CreateInStream(InStream);
                    Attachment.ImportAttachment(InStream, 'replacement.txt');
                end;
            Mutation::Lease:
                begin
                    Entry."Lease Token" := CreateGuid();
                    Entry.Modify();
                end;
            Mutation::Policy:
                begin
                    Setup.Get();
                    Setup.TestField("Automatic Verified Cleanup", true);
                    Setup."Automatic Verified Cleanup" := false;
                    Setup.Modify();
                end;
            Mutation::RetireReference:
                Attachment.MarkAsNotUploadedToExternal();
        end;
    end;

    var
        Mutation: Enum "DA Cleanup Test Mutation";
}
