// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using System.Utilities;

page 9255 "Tasks Matrix"
{
    Caption = 'Tasks Matrix';
    DataCaptionExpression = Format(SelectStr(OutputOption + 1, Text001));
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "RM Matrix Management";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Campaign: Record Campaign;
                        SalesPurchPerson: Record "Salesperson/Purchaser";
                        Contact: Record Contact;
                        Team: Record Team;
                    begin
                        case TableOption of
                            TableOption::Salesperson:
                                begin
                                    SalesPurchPerson.Get(Rec."No.");
                                    PAGE.RunModal(0, SalesPurchPerson);
                                end;
                            TableOption::Team:
                                begin
                                    Team.Get(Rec."No.");
                                    PAGE.RunModal(0, Team);
                                end;
                            TableOption::Campaign:
                                begin
                                    Campaign.Get(Rec."No.");
                                    PAGE.RunModal(0, Campaign);
                                end;
                            TableOption::Contact:
                                begin
                                    Contact.Get(Rec."No.");
                                    PAGE.RunModal(0, Contact);
                                end;
                        end;
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the name of the task.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[1];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[2];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[3];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[4];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[5];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[6];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[7];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[8];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[9];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[10];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[11];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[12];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[13];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[14];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[15];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[16];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[17];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[18];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[19];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[20];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[21];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[22];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[23];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[24];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[25];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[26];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[27];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[28];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[29];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[30];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[31];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = RelationshipMgmt;
                    CaptionClass = '3,' + ColumnCaptions[32];
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MatrixOnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        if (Rec.Type = Rec.Type::Person) and (TableOption = TableOption::Contact) then
            NameIndent := 1
        else
            NameIndent := 0;

        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_NoOfMatrixColumns do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;

        FormatLine();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRec(TableOption, Rec, Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(TableOption, Rec, Steps));
    end;

    trigger OnOpenPage()
    begin
        MATRIX_NoOfMatrixColumns := ArrayLen(MATRIX_CellData);
        if IncludeClosed then
            Rec.SetRange("Task Closed Filter")
        else
            Rec.SetRange("Task Closed Filter", false);

        if StatusFilter <> StatusFilter::" " then
            Rec.SetRange("Task Status Filter", StatusFilter - 1)
        else
            Rec.SetRange("Task Status Filter");

        if PriorityFilter <> PriorityFilter::" " then
            Rec.SetRange("Priority Filter", PriorityFilter - 1)
        else
            Rec.SetRange("Priority Filter");

        ValidateFilter();
        ValidateTableOption();
    end;

    var
        Task: Record "To-do";
        MatrixRecords: array[32] of Record Date;
        Salesperson: Record "Salesperson/Purchaser";
        Cont: Record Contact;
        Team: Record Team;
        Campaign: Record Campaign;
        OutputOption: Option "No. of Tasks","Contact No.";
        TableOption: Option Salesperson,Team,Campaign,Contact;
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
        PriorityFilter: Option " ",Low,Normal,High;
        IncludeClosed: Boolean;
        StyleIsStrong: Boolean;
        FilterSalesPerson: Code[250];
        FilterTeam: Code[250];
        FilterCampaign: Code[250];
        FilterContact: Code[250];
#pragma warning disable AA0074
        Text001: Label 'No. of Tasks,Contact No.';
#pragma warning restore AA0074
        MATRIX_NoOfMatrixColumns: Integer;
        MATRIX_CellData: array[32] of Text[1024];
        ColumnCaptions: array[32] of Text[1024];
        ColumnDateFilters: array[32] of Text[50];
        NameIndent: Integer;
        MultipleTxt: Label 'Multiple';

    local procedure SetFilters()
    begin
        if StatusFilter <> StatusFilter::" " then begin
            Rec.SetRange("Task Status Filter", StatusFilter - 1);
            Task.SetRange(Status, StatusFilter - 1);
        end else begin
            Rec.SetRange("Task Status Filter");
            Task.SetRange(Status);
        end;

        Task.SetFilter("System To-do Type", '%1|%2', Rec."System Task Type Filter"::Organizer,
          Rec."System Task Type Filter"::"Salesperson Attendee");

        if IncludeClosed then
            Task.SetRange(Closed)
        else
            Task.SetRange(Closed, false);

        if PriorityFilter <> PriorityFilter::" " then begin
            Rec.SetRange("Priority Filter", PriorityFilter - 1);
            Task.SetRange(Priority, PriorityFilter - 1);
        end else begin
            Rec.SetRange("Priority Filter");
            Task.SetRange(Priority);
        end;

        case TableOption of
            TableOption::Salesperson:
                begin
                    Rec.SetRange("Salesperson Filter", Rec."No.");
                    Rec.SetFilter(
                      "System Task Type Filter", '%1|%2',
                      Rec."System Task Type Filter"::Organizer,
                      Rec."System Task Type Filter"::"Salesperson Attendee");
                end;
            TableOption::Team:
                begin
                    Rec.SetRange("Team Filter", Rec."No.");
                    Rec.SetRange("System Task Type Filter", Rec."System Task Type Filter"::Team);
                end;
            TableOption::Campaign:
                begin
                    Rec.SetRange("Campaign Filter", Rec."No.");
                    Rec.SetRange("System Task Type Filter", Rec."System Task Type Filter"::Organizer);
                end;
            TableOption::Contact:
                if Rec.Type = Rec.Type::Company then begin
                    Rec.SetRange("Contact Filter");
                    Rec.SetRange("Contact Company Filter", Rec."Company No.");
                    Rec.SetRange(
                      "System Task Type Filter", Rec."System Task Type Filter"::"Contact Attendee");
                end else begin
                    Rec.SetRange("Contact Filter", Rec."No.");
                    Rec.SetRange("Contact Company Filter");
                    Rec.SetRange(
                      "System Task Type Filter", Rec."System Task Type Filter"::"Contact Attendee");
                end;
        end;

        OnAfterSetFilters(Rec, Task, TableOption);
    end;

    local procedure FindRec(TableOpt: Option Salesperson,Teams,Campaign,Contact; var RMMatrixMgt: Record "RM Matrix Management"; Which: Text[250]): Boolean
    var
        Found: Boolean;
    begin
        case TableOpt of
            TableOpt::Salesperson:
                begin
                    RMMatrixMgt."No." := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(Salesperson.Code));
                    Salesperson.Code := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(Salesperson.Code));
                    Found := Salesperson.Find(Which);
                    if Found then
                        CopySalesPersonToBuf(Salesperson, RMMatrixMgt);
                end;
            TableOpt::Teams:
                begin
                    RMMatrixMgt."No." := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(Team.Code));
                    Team.Code := RMMatrixMgt."No.";
                    Found := Team.Find(Which);
                    if Found then
                        CopyTeamToBuf(Team, RMMatrixMgt);
                end;
            TableOpt::Campaign:
                begin
                    Campaign."No." := RMMatrixMgt."No.";
                    Found := Campaign.Find(Which);
                    if Found then
                        CopyCampaignToBuf(Campaign, RMMatrixMgt);
                end;
            TableOpt::Contact:
                begin
                    Cont."Company Name" := RMMatrixMgt."Company Name";
                    Cont.Type := RMMatrixMgt.Type;
                    Cont.Name := CopyStr(RMMatrixMgt.Name, 1, MaxStrLen(Cont.Name));
                    Cont."No." := RMMatrixMgt."No.";
                    Cont."Company No." := RMMatrixMgt."Company No.";
                    Found := Cont.Find(Which);
                    if Found then
                        CopyContactToBuf(Cont, RMMatrixMgt);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(TableOpt: Option Salesperson,Teams,Campaign,Contact; var RMMatrixMgt: Record "RM Matrix Management"; Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        case TableOpt of
            TableOpt::Salesperson:
                begin
                    RMMatrixMgt."No." := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(Salesperson.Code));
                    Salesperson.Code := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(Salesperson.Code));
                    ResultSteps := Salesperson.Next(Steps);
                    if ResultSteps <> 0 then
                        CopySalesPersonToBuf(Salesperson, RMMatrixMgt);
                end;
            TableOpt::Teams:
                begin
                    RMMatrixMgt."No." := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(Team.Code));
                    Team.Code := RMMatrixMgt."No.";
                    ResultSteps := Team.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyTeamToBuf(Team, RMMatrixMgt);
                end;
            TableOpt::Campaign:
                begin
                    Campaign."No." := RMMatrixMgt."No.";
                    ResultSteps := Campaign.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCampaignToBuf(Campaign, RMMatrixMgt);
                end;
            TableOpt::Contact:
                begin
                    Cont."Company Name" := RMMatrixMgt."Company Name";
                    Cont.Type := RMMatrixMgt.Type;
                    Cont.Name := CopyStr(RMMatrixMgt.Name, 1, MaxStrLen(Cont.Name));
                    Cont."No." := RMMatrixMgt."No.";
                    Cont."Company No." := RMMatrixMgt."Company No.";
                    ResultSteps := Cont.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyContactToBuf(Cont, RMMatrixMgt);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopySalesPersonToBuf(var Salesperson: Record "Salesperson/Purchaser"; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := Salesperson.Code;
        RMMatrixMgt.Type := RMMatrixMgt.Type::Person;
        RMMatrixMgt.Name := Salesperson.Name;
        RMMatrixMgt."No." := Salesperson.Code;
        RMMatrixMgt."Company No." := '';
    end;

    local procedure CopyCampaignToBuf(var Campaign: Record Campaign; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := Campaign."No.";
        RMMatrixMgt.Type := RMMatrixMgt.Type::Person;
        RMMatrixMgt.Name := CopyStr(Campaign.Description, 1, MaxStrLen(RMMatrixMgt.Name));
        RMMatrixMgt."No." := Campaign."No.";
        RMMatrixMgt."Company No." := '';
    end;

    local procedure CopyContactToBuf(var Cont: Record Contact; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := CopyStr(Cont."Company Name", 1, MaxStrLen(RMMatrixMgt."Company Name"));
        RMMatrixMgt.Type := Cont.Type;
        RMMatrixMgt.Name := CopyStr(Cont.Name, 1, MaxStrLen(RMMatrixMgt.Name));
        RMMatrixMgt."No." := Cont."No.";
        RMMatrixMgt."Company No." := Cont."Company No.";
    end;

    local procedure CopyTeamToBuf(var TheTeam: Record Team; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := TheTeam.Code;
        RMMatrixMgt.Type := RMMatrixMgt.Type::Person;
        RMMatrixMgt.Name := TheTeam.Name;
        RMMatrixMgt."No." := TheTeam.Code;
        RMMatrixMgt."Company No." := '';
    end;

    local procedure ValidateTableOption()
    begin
        Rec.SetRange("Contact Company Filter");
        case TableOption of
            TableOption::Salesperson:
                begin
                    Rec.SetFilter("Team Filter", FilterTeam);
                    Rec.SetFilter("Campaign Filter", FilterCampaign);
                    Rec.SetFilter("Contact Filter", FilterContact);
                    ValidateFilter();
                end;
            TableOption::Team:
                begin
                    Rec.SetFilter("Salesperson Filter", FilterSalesPerson);
                    Rec.SetFilter("Campaign Filter", FilterCampaign);
                    Rec.SetFilter("Contact Filter", FilterContact);
                    ValidateFilter();
                end;
            TableOption::Campaign:
                begin
                    Rec.SetFilter("Salesperson Filter", FilterSalesPerson);
                    Rec.SetFilter("Team Filter", FilterTeam);
                    Rec.SetFilter("Contact Filter", FilterContact);
                    ValidateFilter();
                end;
            TableOption::Contact:
                begin
                    Rec.SetFilter("Salesperson Filter", FilterSalesPerson);
                    Rec.SetFilter("Team Filter", FilterTeam);
                    Rec.SetFilter("Campaign Filter", FilterCampaign);
                    ValidateFilter();
                end;
        end;
    end;

    local procedure ValidateFilter()
    begin
        case TableOption of
            TableOption::Salesperson:
                UpdateSalesPersonFilter();
            TableOption::Team:
                UpdateTeamFilter();
            TableOption::Campaign:
                UpdateCampaignFilter();
            TableOption::Contact:
                UpdateContactFilter();
        end;
        CurrPage.Update(false);
    end;

    local procedure UpdateSalesPersonFilter()
    begin
        Salesperson.Reset();
        Salesperson.SetFilter(Code, FilterSalesPerson);
        Salesperson.SetFilter("Team Filter", FilterTeam);
        Salesperson.SetFilter("Campaign Filter", FilterCampaign);
        Salesperson.SetFilter("Contact Company Filter", FilterContact);
        Salesperson.SetFilter("Task Status Filter", Rec.GetFilter("Task Status Filter"));
        Salesperson.SetFilter("Closed Task Filter", Rec.GetFilter("Task Closed Filter"));
        Salesperson.SetFilter("Priority Filter", Rec.GetFilter("Priority Filter"));
        Salesperson.SetRange("Task Entry Exists", true);
    end;

    local procedure UpdateCampaignFilter()
    begin
        Campaign.Reset();
        Campaign.SetFilter("No.", FilterCampaign);
        Campaign.SetFilter("Salesperson Filter", FilterSalesPerson);
        Campaign.SetFilter("Team Filter", FilterTeam);
        Campaign.SetFilter("Contact Company Filter", FilterContact);
        Campaign.SetFilter("Task Status Filter", Rec.GetFilter("Task Status Filter"));
        Campaign.SetFilter("Task Closed Filter", Rec.GetFilter("Task Closed Filter"));
        Campaign.SetFilter("Priority Filter", Rec.GetFilter("Priority Filter"));
        Campaign.SetRange("Task Entry Exists", true);
    end;

    local procedure UpdateContactFilter()
    begin
        Cont.Reset();
        Cont.SetCurrentKey("Company Name", "Company No.", Type, Name);
        Cont.SetFilter("Company No.", FilterContact);
        Cont.SetFilter("Campaign Filter", FilterCampaign);
        Cont.SetFilter("Salesperson Filter", FilterSalesPerson);
        Cont.SetFilter("Team Filter", FilterTeam);
        Cont.SetFilter("Task Status Filter", Rec.GetFilter("Task Status Filter"));
        Cont.SetFilter("Task Closed Filter", Rec.GetFilter("Task Closed Filter"));
        Cont.SetFilter("Priority Filter", Rec.GetFilter("Priority Filter"));
        Cont.SetRange("Task Entry Exists", true);
    end;

    local procedure UpdateTeamFilter()
    begin
        Team.Reset();
        Team.SetFilter(Code, FilterTeam);
        Team.SetFilter("Campaign Filter", FilterCampaign);
        Team.SetFilter("Salesperson Filter", FilterSalesPerson);
        Team.SetFilter("Contact Company Filter", FilterContact);
        Team.SetFilter("Task Status Filter", Rec.GetFilter("Task Status Filter"));
        Team.SetFilter("Task Closed Filter", Rec.GetFilter("Task Closed Filter"));
        Team.SetFilter("Priority Filter", Rec.GetFilter("Priority Filter"));
        Team.SetRange("Task Entry Exists", true);
    end;

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; TableOptionLocal: Option Salesperson,Team,Campaign,Contact; ColumnDateFilter: array[32] of Text[50]; OutputOptionLocal: Option "No. of Tasks","Contact No."; FilterSalesPersonLocal: Code[250]; FilterTeamLocal: Code[250]; FilterCampaignLocal: Code[250]; FilterContactLocal: Code[250]; StatusFilterLocal: Option " ","Not Started","In Progress",Completed,Waiting,Postponed; IncludeClosedLocal: Boolean; PriorityFilterLocal: Option " ",Low,Normal,High)
    var
        i: Integer;
    begin
        CopyArray(ColumnCaptions, MatrixColumns1, 1);
        for i := 1 to 32 do
            MatrixRecords[i].Copy(MatrixRecords1[i]);
        TableOption := TableOptionLocal;
        CopyArray(ColumnDateFilters, ColumnDateFilter, 1);
        OutputOption := OutputOptionLocal;
        FilterSalesPerson := FilterSalesPersonLocal;
        FilterTeam := FilterTeamLocal;
        FilterCampaign := FilterCampaignLocal;
        FilterContact := FilterContactLocal;
        StatusFilter := StatusFilterLocal;
        IncludeClosed := IncludeClosedLocal;
        PriorityFilter := PriorityFilterLocal;
        SetFilters();
    end;

    local procedure MatrixOnDrillDown(ColumnID: Integer)
    var
        SkipRun: Boolean;
    begin
        Task.SetRange(Date, MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End");
        case TableOption of
            TableOption::Salesperson:
                Task.SetFilter("Salesperson Code", Rec."No.");
            TableOption::Team:
                Task.SetFilter("Team Code", Rec."No.");
            TableOption::Campaign:
                Task.SetFilter("Campaign No.", Rec."No.");
            TableOption::Contact:
                Task.SetFilter("Contact No.", Rec."No.");
        end;
        Task.SetFilter("Salesperson Code", Rec.GetFilter("Salesperson Filter"));
        Task.SetFilter("Team Code", Rec.GetFilter("Team Filter"));
        Task.SetFilter("Contact Company No.", Rec.GetFilter("Contact Company Filter"));
        Task.SetFilter(Status, Rec.GetFilter("Task Status Filter"));
        Task.SetFilter(Closed, Rec.GetFilter("Task Closed Filter"));
        Task.SetFilter(Priority, Rec.GetFilter("Priority Filter"));
        Task.SetFilter("System To-do Type", Rec.GetFilter("System Task Type Filter"));

        SkipRun := false;
        OnMatrixOnDrillDownOnBeforeRunTaskList(Rec, Task, SkipRun);
        if not SkipRun then
            PAGE.RunModal(PAGE::"Task List", Task);
    end;

    local procedure MATRIX_OnAfterGetRecord(Matrix_ColumnOrdinal: Integer)
    begin
        SetFilters();
        Rec.SetRange("Date Filter", MatrixRecords[Matrix_ColumnOrdinal]."Period Start", MatrixRecords[Matrix_ColumnOrdinal]."Period End");
        Rec.CalcFields("No. of Tasks");
        if OutputOption <> OutputOption::"Contact No." then begin
            if Rec."No. of Tasks" = 0 then
                MATRIX_CellData[Matrix_ColumnOrdinal] := ''
            else
                MATRIX_CellData[Matrix_ColumnOrdinal] := Format(Rec."No. of Tasks");
        end else begin
            if Rec.GetFilter("Team Filter") <> '' then
                Task.SetFilter("Team Code", Rec.GetFilter("Team Filter"));
            if Rec.GetFilter("Salesperson Filter") <> '' then
                Task.SetFilter("Salesperson Code", Rec.GetFilter("Salesperson Filter"));
            if Rec.GetFilter("Campaign Filter") <> '' then
                Task.SetFilter("Campaign No.", Rec.GetFilter("Campaign Filter"));
            if Rec.GetFilter("Contact Filter") <> '' then
                Task.SetFilter("Contact No.", Rec."Contact Filter");
            if Rec.GetFilter("Date Filter") <> '' then
                Task.SetFilter(Date, Rec.GetFilter("Date Filter"));
            if Rec.GetFilter("Task Status Filter") <> '' then
                Task.SetFilter(Status, Rec.GetFilter("Task Status Filter"));
            if Rec.GetFilter("Priority Filter") <> '' then
                Task.SetFilter(Priority, Rec.GetFilter("Priority Filter"));
            if Rec.GetFilter("Task Closed Filter") <> '' then
                Task.SetFilter(Closed, Rec.GetFilter("Task Closed Filter"));
            if Rec.GetFilter("Contact Company Filter") <> '' then
                Task.SetFilter("Contact Company No.", Rec.GetFilter("Contact Company Filter"));
            if Rec."No. of Tasks" = 0 then
                MATRIX_CellData[Matrix_ColumnOrdinal] := ''
            else
                if Rec."No. of Tasks" > 1 then
                    MATRIX_CellData[Matrix_ColumnOrdinal] := MultipleTxt
                else begin
                    Task.FindFirst();
                    if Task."Contact No." <> '' then
                        MATRIX_CellData[Matrix_ColumnOrdinal] := Task."Contact No."
                    else
                        MATRIX_CellData[Matrix_ColumnOrdinal] := MultipleTxt
                end;
        end;
    end;

    local procedure FormatLine()
    begin
        StyleIsStrong := Rec.Type = Rec.Type::Company;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetFilters(var RMMatrixManagement: Record "RM Matrix Management"; var Task: Record "To-do"; TableOption: Option Salesperson,Team,Campaign,Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatrixOnDrillDownOnBeforeRunTaskList(var RMMatrixManagement: Record "RM Matrix Management"; var Task: Record "To-do"; var SkipRun: Boolean)
    begin
    end;
}

