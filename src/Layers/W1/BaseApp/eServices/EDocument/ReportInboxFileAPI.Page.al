// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Environment;

page 692 "Report Inbox File API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'reportInbox';
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
                field(companyName; Rec."Company Name") { }
                field(fileName; Rec."File Name") { }
                field(byteSize; Rec."Byte Size") { }
                field(documentContent; Rec.Content) { }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CompanyRec: Record Company;
        IdFilter: Text;
        CompanyFilter: Text;
    begin
        if Loaded then
            exit(FileFound and Rec.Find(Which));
        Loaded := true;

        IdFilter := Rec.GetFilter(Id);
        if IdFilter = '' then
            Error(KeyRequiredErr);

        CompanyFilter := Rec.GetFilter("Company Name");

        if CompanyFilter = '' then
            FileFound := LoadFromCompany(CopyStr(CompanyName(), 1, MaxStrLen(Rec."Company Name")), IdFilter)
        else begin
            CompanyRec.SetLoadFields(Name);
            CompanyRec.SetFilter(Name, CompanyFilter);
            if CompanyRec.FindSet() then
                repeat
                    FileFound := LoadFromCompany(CompanyRec.Name, IdFilter);
                until (CompanyRec.Next() = 0) or FileFound;
        end;

        exit(FileFound and Rec.Find(Which));
    end;

    local procedure LoadFromCompany(CompanyToRead: Text[30]; IdFilter: Text): Boolean
    var
        ReportInbox: Record "Report Inbox";
        InStr: InStream;
        OutStr: OutStream;
    begin
        if not ReportInbox.ChangeCompany(CompanyToRead) then
            exit(false);
        if not ReportInbox.ReadPermission then
            exit(false);

        ReportInbox.ReadIsolation := IsolationLevel::ReadCommitted;
        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetFilter(SystemId, IdFilter);
        if ReportInbox.Count() > 1 then
            exit(false);
        if not ReportInbox.FindFirst() then
            exit(false);

        ReportInbox.CalcFields("Report Output", "Report Name");
        Rec.Init();
        Rec.Id := ReportInbox.SystemId;
        Rec."Company Name" := CompanyToRead;
        Rec."File Name" := CopyStr(ReportInbox.GetFileNameWithExtension(), 1, MaxStrLen(Rec."File Name"));
        Rec."Byte Size" := ReportInbox."Report Output".Length();
        if ReportInbox."Report Output".HasValue() then begin
            ReportInbox."Report Output".CreateInStream(InStr);
            Rec.Content.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end;
        Rec.Insert();
        exit(true);
    end;

    var
        Loaded: Boolean;
        FileFound: Boolean;
        KeyRequiredErr: Label 'Specify a single report inbox entry by its id, for example reportInboxFiles(<id>)/documentContent. Use the reportInboxItems endpoint to discover an id.';
}
