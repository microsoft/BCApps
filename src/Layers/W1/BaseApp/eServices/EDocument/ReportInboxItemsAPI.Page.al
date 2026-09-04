// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Environment;

page 690 "Report Inbox Items API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'reportInbox';
    APIVersion = 'v1.0';
    EntityName = 'reportInboxItem';
    EntitySetName = 'reportInboxItems';
    EntityCaption = 'Report Inbox Item';
    EntitySetCaption = 'Report Inbox Items';
    SourceTable = "Report Inbox Item Buffer";
    ODataKeyFields = Id;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Editable = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.Id)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(companyName; Rec."Company Name")
                {
                    Editable = false;
                }
                field(companyNameLower; Rec."Company Name Lower")
                {
                    Editable = false;
                }
                field(includeAllCompanies; Rec."Include All Companies")
                {
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Editable = false;
                }
                field(reportId; Rec."Report ID")
                {
                    Editable = false;
                }
                field(reportName; Rec."Report Name")
                {
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Editable = false;
                }
                field(createdDateTime; Rec."Created Date-Time")
                {
                    Editable = false;
                }
                field(outputType; Rec."Output Type")
                {
                    Editable = false;
                }
                field(read; Rec.Read) { }
                field(fileName; Rec."File Name")
                {
                    Editable = false;
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        ReportInbox: Record "Report Inbox";
    begin
        if not ReportInbox.ChangeCompany(Rec."Company Name") then
            exit(false);
        if not ReportInbox.WritePermission then
            exit(false);

        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetRange(SystemId, Rec.Id);
        if not ReportInbox.FindFirst() then
            exit(false);

        if ReportInbox.Read <> Rec.Read then begin
            ReportInbox.Read := Rec.Read;
            ReportInbox.Modify();
        end;
        exit(true);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        CompanyRec: Record Company;
        View: Text;
        NameFilter: Text;
        LowerNameFilter: Text;
        AllCompanies: Boolean;
    begin
        if Initialized then
            exit(Rec.Find(Which));

        AllCompanies := RequestWantsAllCompanies();
        NameFilter := Rec.GetFilter("Company Name");
        LowerNameFilter := Rec.GetFilter("Company Name Lower");
        View := Rec.GetView();
        Rec.Reset();

        if AllCompanies then begin
            if NameFilter <> '' then
                CompanyRec.SetFilter(Name, NameFilter);
            CompanyRec.SetLoadFields(Name);
            if CompanyRec.FindSet() then
                repeat
                    if CompanyPassesRequestFilter(CompanyRec.Name, NameFilter, LowerNameFilter) then
                        CollectFromCompany(CompanyRec.Name, true);
                until CompanyRec.Next() = 0;
        end else
            CollectFromCompany(CopyStr(CompanyName(), 1, MaxStrLen(Rec."Company Name")), false);

        Rec.SetView(View);
        Initialized := true;
        exit(Rec.Find(Which));
    end;

    var
        Initialized: Boolean;
        ConflictingScopeErr: Label 'A company name was filtered together with includeAllCompanies eq false, and those two ask for opposite things. Filter a company name to search every company you may open and return that one, or filter includeAllCompanies eq false to read only the company in the request — not both.';
        UnrecognisedScopeFilterErr: Label 'The filter %1 on includeAllCompanies could not be interpreted. Use includeAllCompanies eq true to read every company you may open, or omit it to read only the company in the request.', Comment = '%1 = the filter value the caller supplied';

    local procedure CompanyPassesRequestFilter(CompanyNameToTest: Text[30]; NameFilter: Text; LowerNameFilter: Text): Boolean
    var
        TempProbe: Record "Report Inbox Item Buffer";
    begin
        if (NameFilter = '') and (LowerNameFilter = '') then
            exit(true);

        TempProbe.Init();
        TempProbe."Company Name" := CompanyNameToTest;
        TempProbe."Company Name Lower" := CompanyNameToTest.ToLower();
        TempProbe.Insert();

        if NameFilter <> '' then
            TempProbe.SetFilter("Company Name", NameFilter);
        if LowerNameFilter <> '' then
            TempProbe.SetFilter("Company Name Lower", LowerNameFilter);
        exit(not TempProbe.IsEmpty());
    end;

    local procedure RequestWantsAllCompanies(): Boolean
    var
        ScopeFilter: Text;
    begin
        ScopeFilter := Rec.GetFilter("Include All Companies");

        if (Rec.GetFilter("Company Name") <> '') or (Rec.GetFilter("Company Name Lower") <> '') then begin
            if (ScopeFilter <> '') and not FilterAsksForTrue(ScopeFilter) then
                Error(ConflictingScopeErr);
            exit(true);
        end;

        exit(FilterAsksForTrue(ScopeFilter));
    end;

    local procedure FilterAsksForTrue(FilterText: Text): Boolean
    var
        Requested: Boolean;
        NormalisedFilter: Text;
    begin
        if FilterText = '' then
            exit(false);
        if Evaluate(Requested, FilterText) then
            exit(Requested);
        NormalisedFilter := LowerCase(FilterText);
        if (NormalisedFilter = '0') or (NormalisedFilter = 'no') or (NormalisedFilter = 'false') then
            exit(false);
        Error(UnrecognisedScopeFilterErr, FilterText);
    end;

    local procedure CollectFromCompany(CompanyNameToRead: Text[30]; AllCompaniesMode: Boolean)
    var
        ReportInbox: Record "Report Inbox";
    begin
        if not ReportInbox.ChangeCompany(CompanyNameToRead) then
            exit;
        if not ReportInbox.ReadPermission then
            exit;

        ReportInbox.ReadIsolation := IsolationLevel::ReadCommitted;
        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetAutoCalcFields("Report Name");
        if not ReportInbox.FindSet() then
            exit;

        repeat
            Rec.Init();
            Rec.Id := ReportInbox.SystemId;
            Rec."Company Name" := CompanyNameToRead;
            Rec."Company Name Lower" := CompanyNameToRead.ToLower();
            Rec."Include All Companies" := AllCompaniesMode;
            Rec."Entry No." := ReportInbox."Entry No.";
            Rec."Report ID" := ReportInbox."Report ID";
            Rec."Report Name" := ReportInbox."Report Name";
            Rec.Description := ReportInbox.Description;
            Rec."Created Date-Time" := ReportInbox."Created Date-Time";
            Rec."Output Type" := ReportInbox."Output Type";
            Rec.Read := ReportInbox.Read;
            Rec."File Name" := CopyStr(ReportInbox.GetFileNameWithExtension(), 1, MaxStrLen(Rec."File Name"));
            Rec.Insert();
        until ReportInbox.Next() = 0;
    end;
}
