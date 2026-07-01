// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Posting;

using Microsoft.Assembly.Document;
using Microsoft.Finance.GeneralLedger.Preview;

codeunit 901 "Assembly-Post (Yes/No)"
{
    TableNo = "Assembly Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        AssemblyHeader.Copy(Rec);
        Code();
        Rec := AssemblyHeader;
    end;

    var
        AssemblyHeader: Record "Assembly Header";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to post the %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        if not Confirm(Text000, false, AssemblyHeader."Document Type") then
            exit;

        CODEUNIT.Run(CODEUNIT::"Assembly-Post", AssemblyHeader);
    end;

    procedure Preview(var AssemblyHeaderToPreview: Record "Assembly Header")
    var
        AssemblyPostYesNo: Codeunit "Assembly-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(AssemblyPostYesNo);
        GenJnlPostPreview.Preview(AssemblyPostYesNo, AssemblyHeaderToPreview);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var AssemblyHeaderToPreview: Record "Assembly Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Assembly Header");
        RecordRefToPreview.Copy(AssemblyHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        AssemblyHeaderToPreview: Record "Assembly Header";
        AssemblyPost: Codeunit "Assembly-Post";
    begin
        AssemblyHeaderToPreview.Copy(RecVar);
        AssemblyPost.SetSuppressCommit(true);
        AssemblyPost.SetPreviewMode(true);
        Result := AssemblyPost.Run(AssemblyHeaderToPreview);
    end;
}

