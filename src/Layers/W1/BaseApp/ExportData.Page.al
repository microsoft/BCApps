// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Environment;

page 9901 "Export Data"
{
    Caption = 'Export to a Data File';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    SourceTable = Company;
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the data to be exported.';
                }
                group(Export)
                {
                    Caption = 'Export';
                    field(IncludeAllCompanies; IncludeAllCompanies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'All Companies';
                        ToolTip = 'Specifies that data in all the companies will be imported into the database.';

                        trigger OnValidate()
                        begin
                            MarkAll();
                        end;
                    }
                    field(IncludeGlobalData; IncludeGlobalData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Global Data';
                        ToolTip = 'Specifies that data that is common to all companies will be exported from the database. This includes the report list, user IDs, and printer selections, but no company-specific business data.';
                    }
                    field(IncludeApplicationData; IncludeApplicationData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application Data';
                        ToolTip = 'Specifies that the data that defines the application in the database is exported. This includes the permissions, permission sets, profiles, and style sheets.';
                    }
                    field(IncludeApplication; IncludeApplication)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application';
                        ToolTip = 'Specifies that all application objects are exported. Data is not included. This is similar to exporting all objects to an .fob file.';
                    }
                }
                repeater(Control8)
                {
                    ShowCaption = false;
                    field(Selected; Selected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export';
                        ToolTip = 'Specifies that data is exported.';

                        trigger OnValidate()
                        begin
                            if Selected then begin
                                TempSelectedCompany := Rec;
                                if TempSelectedCompany.Insert() then;
                            end else begin
                                IncludeAllCompanies := false;
                                if TempSelectedCompany.Get(Rec.Name) then
                                    TempSelectedCompany.Delete();
                            end;
                        end;
                    }
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Name';
                        ToolTip = 'Specifies the name of a company that has been created in the current database.';
                        Width = 30;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Selected := TempSelectedCompany.Get(Rec.Name);
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS() then
            error(OnPremiseOnlyErr);
        FileName := 'ExportData.navdata';
    end;

    trigger OnOpenPage()
    var
        Company: Record Company;
    begin
        IncludeApplication := false;
        IncludeApplicationData := false;
        IncludeGlobalData := true;
        IncludeAllCompanies := true;

        if Company.FindSet() then
            repeat
                Rec := Company;
                Rec.Insert();
            until Company.Next() = 0;

        MarkAll();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Description <> '' then
            FileName := StrSubstNo(FileNameLbl, CopyStr(Description, 1, 250));
        if CloseAction = ACTION::OK then begin
            if ExportData(
                 true,
                 FileName,
                 Description,
                 IncludeApplication,
                 IncludeApplicationData,
                 IncludeGlobalData,
                 TempSelectedCompany)
            then begin
                Message(CompletedMsg);
                exit(true)
            end;
            exit(false)
        end;

        exit(true);
    end;

    var
        TempSelectedCompany: Record Company temporary;
        FileName: Text;
        Description: Text;
        IncludeApplication: Boolean;
        IncludeApplicationData: Boolean;
        IncludeGlobalData: Boolean;
        IncludeAllCompanies: Boolean;
        Selected: Boolean;
        OnPremiseOnlyErr: Label 'This functionality is supported only in Business Central on-premises.';
        CompletedMsg: Label 'The data was exported successfully.';
        FileNameLbl: Label '%1.navdata', Locked = true;

    local procedure MarkAll()
    begin
        TempSelectedCompany.DeleteAll();
        if IncludeAllCompanies then
            if Rec.FindSet() then
                repeat
                    TempSelectedCompany := Rec;
                    TempSelectedCompany.Insert();
                until Rec.Next() = 0;

        CurrPage.Update(false);
    end;
}

