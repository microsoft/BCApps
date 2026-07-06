// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Apps;
using System.Reflection;

page 9880 "Database Access Intent List"
{
    PageType = List;
    ApplicationArea = All;
    AdditionalSearchTerms = 'Replicated database,Read Only access';
    UsageCategory = Administration;
    Permissions = TableData "Object Access Intent Override" = rimd;
    SourceTable = AllObjWithCaption;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(ObjType; Rec."Object Type")
                {
                    ApplicationArea = All;
                    Caption = 'Object Type';
                    Tooltip = 'Specifies the object type.';
                    Editable = false;
                }
                field(ObjID; Rec."Object ID")
                {
                    ApplicationArea = All;
                    Caption = 'Object ID';
                    Tooltip = 'Specifies the object number.';
                    Editable = false;
                }
                field(ObjName; Rec."Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Object Name';
                    Tooltip = 'Specifies the object name.';
                    Editable = false;
                }
                field(ObjCaption; Rec."Object Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Object Caption';
                    Tooltip = 'Specifies the object caption as shown to the user.';
                    Editable = false;
                }
                field(AccessIntent; TempObjectAccessIntentOverride."Access Intent")
                {
                    ApplicationArea = All;
                    Caption = 'Access Intent';
                    Tooltip = 'Specifies the database access intent. Objects that only read from the database can be set to Read Only in order to utilize replicated databases.';
                    OptionCaption = 'Default,Read Only,Allow Write';
                    trigger OnValidate()
                    begin
                        if TempObjectAccessIntentOverride."Access Intent" = TempObjectAccessIntentOverride."Access Intent"::Default then begin
                            ObjectAccessIntentOverride := TempObjectAccessIntentOverride;
                            if ObjectAccessIntentOverride.find() then
                                if ObjectAccessIntentOverride.delete() then;
                            if TempObjectAccessIntentOverride.delete() then;
                        end else begin
                            ObjectAccessIntentOverride := TempObjectAccessIntentOverride;
                            if ObjectAccessIntentOverride.find() then begin
                                ObjectAccessIntentOverride := TempObjectAccessIntentOverride;
                                if ObjectAccessIntentOverride.modify() then;
                                if TempObjectAccessIntentOverride.modify() then;
                            end else begin
                                ObjectAccessIntentOverride := TempObjectAccessIntentOverride;
                                if ObjectAccessIntentOverride.insert() then;
                                if TempObjectAccessIntentOverride.insert() then;
                            end;

                        end;
                    end;
                }
                field(AppName; TempPublishedApplication.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Application Name';
                    Tooltip = 'Specifies the application or extension that the object belongs to.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunObject)
            {
                ApplicationArea = All;
                Image = Process;
                Caption = 'Run Object';
                ToolTip = 'You can try to run the object in order to test whether the selected setting for Access Intent works.';

                trigger OnAction()
                begin
                    case Rec."Object Type" of
                        Rec."Object Type"::Report:
                            Report.RunModal(Rec."Object ID");
                        Rec."Object Type"::Page:
                            Page.RunModal(Rec."Object ID");
                        else
                            message(NotSupportedTypeMsg, Rec."Object Type");
                    end;
                end;
            }
        }
    }

    var
        TempObjectAccessIntentOverride: Record "Object Access Intent Override" temporary;
        ObjectAccessIntentOverride: Record "Object Access Intent Override";
        TempPublishedApplication: Record "Published Application" temporary;
#pragma warning disable AA0470
        NotSupportedTypeMsg: Label 'You cannot run an object of type %1.';
#pragma warning restore AA0470

    trigger OnOpenPage()
    var
        PublishedApplication: Record "Published Application";
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Object Type", '%1|%2|%3', Rec."Object Type"::Page, Rec."Object Type"::Report, Rec."Object Type"::Query);
        Rec.FilterGroup(0);

        if ObjectAccessIntentOverride.FindSet() then
            repeat
                TempObjectAccessIntentOverride := ObjectAccessIntentOverride;
                if TempObjectAccessIntentOverride.Insert() then;
            until ObjectAccessIntentOverride.Next() = 0;

        if PublishedApplication.FindSet() then
            repeat
                TempPublishedApplication := PublishedApplication;
                if TempPublishedApplication.Insert() then;
            until PublishedApplication.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    begin
        if not TempObjectAccessIntentOverride.Get(Rec."Object Type", Rec."Object ID") then begin
            Clear(TempObjectAccessIntentOverride);
            TempObjectAccessIntentOverride."Object Type" := Rec."Object Type";
            TempObjectAccessIntentOverride."Object ID" := Rec."Object ID";
        end;

        if Rec."App Package ID" <> TempPublishedApplication."Package ID" then begin
            TempPublishedApplication.SetRange("Package ID", Rec."App Package ID");
            TempPublishedApplication.SetRange("Tenant Visible", true);
            if not TempPublishedApplication.FindFirst() then
                TempPublishedApplication.Init();
        end;
    end;
}
