// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Environment;

page 694 "Report Inbox Companies API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'reportInbox';
    APIVersion = 'v1.0';
    EntityName = 'reportInboxCompany';
    EntitySetName = 'reportInboxCompanies';
    EntityCaption = 'Report Inbox Company';
    EntitySetCaption = 'Report Inbox Companies';
    SourceTable = "Report Inbox Company Buffer";
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
                field(companyNameLower; Rec."Company Name Lower") { }
                field(entryCount; Rec."Entry Count") { }
                field(unreadCount; Rec."Unread Count") { }
                field(lastCreatedDateTime; Rec."Last Created Date-Time") { }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CompanyRec: Record Company;
        View: Text;
    begin
        if Initialized then
            exit(Rec.Find(Which));

        View := Rec.GetView();
        Rec.Reset();

        if CompanyRec.FindSet() then
            repeat
                AddCompany(CompanyRec.Name);
            until CompanyRec.Next() = 0;

        Rec.SetView(View);
        Initialized := true;
        exit(Rec.Find(Which));
    end;

    var
        Initialized: Boolean;

    local procedure AddCompany(CompanyNameToRead: Text[30])
    var
        ReportInbox: Record "Report Inbox";
        CompanyRec: Record Company;
    begin
        if not ReportInbox.ChangeCompany(CompanyNameToRead) then
            exit;
        if not ReportInbox.ReadPermission then
            exit;

        ReportInbox.SetCurrentKey("User ID", "Created Date-Time");
        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));

        Rec.Init();
        Rec."Entry Count" := ReportInbox.Count();
        if Rec."Entry Count" = 0 then
            exit;

        Rec."Company Name" := CompanyNameToRead;
        Rec."Company Name Lower" := CompanyNameToRead.ToLower();
        if CompanyRec.Get(CompanyNameToRead) then
            Rec.Id := CompanyRec.SystemId;
        if ReportInbox.FindLast() then
            Rec."Last Created Date-Time" := ReportInbox."Created Date-Time";
        ReportInbox.SetRange(Read, false);
        Rec."Unread Count" := ReportInbox.Count();
        Rec.Insert();
    end;
}
