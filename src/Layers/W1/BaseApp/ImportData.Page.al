// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

page 9900 "Import Data"
{
    Caption = 'Import from a Data File';
    DeleteAllowed = false;
    Editable = true;
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
                field(FileName; FileName)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'File Name';
                    DrillDown = false;
                    Editable = true;
                    Lookup = false;
                    ToolTip = 'Specifies the name and location of the .navdata file that you want to import data from.';

                    trigger OnAssistEdit()
                    var
                        TempCompany: Record Company temporary;
                    begin
                        if not DataFileInformation(
                             true,
                             FileName,
                             Description,
                             ContainsApplication,
                             ContainsApplicationData,
                             ContainsGlobalData,
                             OriginalTenantId,
                             ExportDate,
                             TempCompany)
                        then
                            exit;

                        Rec.DeleteAll();
                        ContainsCompanies := TempCompany.FindSet();
                        if ContainsCompanies then
                            repeat
                                Rec := TempCompany;
                                Rec.Insert();
                            until TempCompany.Next() = 0;

                        IncludeApplicationData := false;
                        IncludeGlobalData := false;
                        IncludeAllCompanies := ContainsCompanies;

                        MarkAll();
                    end;

                    trigger OnValidate()
                    var
                        TempCompany: Record Company temporary;
                    begin
                        if not DataFileInformation(
                             false,
                             FileName,
                             Description,
                             ContainsApplication,
                             ContainsApplicationData,
                             ContainsGlobalData,
                             OriginalTenantId,
                             ExportDate,
                             TempCompany)
                        then
                            exit;

                        Rec.DeleteAll();
                        ContainsCompanies := TempCompany.FindSet();
                        if ContainsCompanies then
                            repeat
                                Rec := TempCompany;
                                Rec.Insert();
                            until TempCompany.Next() = 0;

                        IncludeApplicationData := false;
                        IncludeGlobalData := false;
                        IncludeAllCompanies := ContainsCompanies;

                        MarkAll();
                    end;
                }
                field(TenantId; TenantId())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tenant ID';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the tenant that is accessed when you run objects from the development environment. If your solution is not set up to deploy in a multitenant deployment architecture, leave the parameter empty.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies a description of the data to be imported.';
                }
                field(ExportDate; ExportDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date of Export';
                    Editable = false;
                    ToolTip = 'Specifies when the data was exported.';
                }
                group(Import)
                {
                    Caption = 'Import';
                    field(IncludeAllCompanies; IncludeAllCompanies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'All Companies';
                        Editable = ContainsCompanies;
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
                        Editable = ContainsGlobalData;
                        ToolTip = 'Specifies that data that is common to all companies will be imported into the database. This includes the report list, user IDs, and printer selections, but no company-specific business data.';
                    }
                    field(IncludeApplicationData; IncludeApplicationData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application Data';
                        Editable = ContainsApplicationData;
                        ToolTip = 'Specifies that the data that defines the application in the database is imported. This includes the permissions, permission sets, profiles, and style sheets.';
                    }
                }
                repeater(Control8)
                {
                    ShowCaption = false;
                    field(Selected; Selected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Import';
                        ToolTip = 'Specifies that data will be imported.';

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
        OriginalTenantId := '';
        ContainsApplication := false;
        ContainsApplicationData := false;
        ContainsGlobalData := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then begin
            if IncludeApplicationData or IncludeGlobalData then
                if not Confirm(OverwriteQst, false) then
                    exit(false);

            if ImportData(
                 false,
                 FileName,
                 IncludeApplicationData,
                 IncludeGlobalData,
                 TempSelectedCompany)
            then begin
                Message(CompletedMsg);
                exit(true)
            end;
            exit(false);
        end;
    end;

    var
        TempSelectedCompany: Record Company temporary;
        FileName: Text;
        Description: Text;
        OriginalTenantId: Text;
        ExportDate: DateTime;
        Selected: Boolean;
        ContainsApplication: Boolean;
        ContainsApplicationData: Boolean;
        ContainsGlobalData: Boolean;
        ContainsCompanies: Boolean;
        IncludeAllCompanies: Boolean;
        IncludeApplicationData: Boolean;
        IncludeGlobalData: Boolean;
        OnPremiseOnlyErr: Label 'This functionality is supported only in Business Central on-premises.';
        OverwriteQst: Label 'Application data, global data, or both types of data will be overwritten. Are you sure that you want to continue?';
        CompletedMsg: Label 'The data was imported successfully.';

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

