// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 692 "Report Inbox File API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'automate';
    APIVersion = 'v1.0';
    EntityName = 'reportInboxFile';
    EntitySetName = 'reportInboxFiles';
    EntityCaption = 'Report Inbox File';
    EntitySetCaption = 'Report Inbox Files';
    SourceTable = "Report Inbox File Buffer";
    ODataKeyFields = Id;
    DataAccessIntent = ReadOnly;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.Id) { }
                field(fileName; Rec."File Name") { }
                field(byteSize; Rec."Byte Size") { }
                field(documentContent; Rec.Content) { }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        ReportInbox: Record "Report Inbox";
        InStr: InStream;
        OutStr: OutStream;
        IdFilter: Text;
    begin
        if Loaded then
            exit(FileFound and Rec.Find(Which));
        Loaded := true;

        IdFilter := Rec.GetFilter(Id);
        if IdFilter = '' then
            Error(KeyRequiredErr);

        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetFilter(SystemId, IdFilter);
        if not ReportInbox.FindFirst() then
            exit(false);

        ReportInbox.CalcFields("Report Output", "Report Name");
        Rec.Init();
        Rec.Id := ReportInbox.SystemId;
        Rec."File Name" := CopyStr(ReportInbox.GetFileNameWithExtension(), 1, MaxStrLen(Rec."File Name"));
        Rec."Byte Size" := ReportInbox."Report Output".Length();
        if ReportInbox."Report Output".HasValue() then begin
            ReportInbox."Report Output".CreateInStream(InStr);
            Rec.Content.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end;
        Rec.Insert();
        FileFound := true;
        exit(true);
    end;

    var
        Loaded: Boolean;
        FileFound: Boolean;
        KeyRequiredErr: Label 'Specify a single report inbox entry by its systemId, for example reportInboxFiles(<systemId>)/documentContent. Use the reportInboxItems endpoint to discover a systemId.';
}
