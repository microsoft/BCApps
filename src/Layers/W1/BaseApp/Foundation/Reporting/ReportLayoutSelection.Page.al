// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment;
using System.Environment.Configuration;
using System.Reflection;

page 9652 "Report Layout Selection"
{
    AdditionalSearchTerms = 'customization,document layout';
    ApplicationArea = Basic, Suite;
    Caption = 'Report Layout Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Report Layout Selection";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Company)
            {
                Caption = 'Company';
                field(SelectedCompany; SelectedCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    Importance = Promoted;
                    TableRelation = Company;
                    ToolTip = 'Specifies the name of the company that is used for the report.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the report.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Type';
                    ToolTip = 'Specifies the type of the report layout that is currently used on the report.';

                    trigger OnValidate()
                    begin
                        UpdateRec();
                        Commit();
                        LookupLayout();
                        CurrPage.Update(false);
                    end;
                }
                field("Custom Report Layout Code"; Rec."Custom Report Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Custom Report Layout" where("Report ID" = field("Report ID"));
                    ToolTip = 'Specifies the custom report layout.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ReportLayoutSelection.Validate("Custom Report Layout Code", ReportLayoutSelection."Custom Report Layout Code");
                        UpdateRec();
                        CurrPage.Update(false);
                    end;
                }
                field(CustomLayoutDescription; CustomLayoutDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the layout that is used by the report.';

                    trigger OnValidate()
                    var
                        CustomReportLayout2: Record "Custom Report Layout";
                    begin
                        if Rec.Type = Rec.Type::"Custom Layout" then begin
                            CustomReportLayout2.SetCurrentKey("Report ID", "Company Name", Type);
                            CustomReportLayout2.SetRange("Report ID", ReportLayoutSelection."Report ID");
                            CustomReportLayout2.SetFilter("Company Name", '%1|%2', '', SelectedCompany);
                            CustomReportLayout2.SetFilter(Description, '%1', '@*' + CustomLayoutDescription + '*');
                            if not CustomReportLayout2.FindFirst() then
                                Error(CouldNotFindCustomReportLayoutErr, CustomLayoutDescription);

                            if CustomReportLayout2.Code <> Rec."Custom Report Layout Code" then begin
                                Rec.Validate(Rec."Custom Report Layout Code", CustomReportLayout2.Code);
                                UpdateRec();
                            end;
                        end else
                            ValidateBuiltInReportLayoutDescription();

                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part("Custom Layouts"; "Report Layouts Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Custom Layouts';
                ShowFilter = false;
                SubPageLink = "Report ID" = field("Report ID");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SelectLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Layout';
                Image = "SelectReport";
                Scope = Repeater;
                ShortCutKey = "Shift+F11";
                ToolTip = 'Select one of the layouts that are available for a report.';

                trigger OnAction()
                begin
                    LookupLayout();
                    CurrPage.Update(false);
                end;
            }

            action(RestoreDefaultLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore Default Selection';
                Image = "Report";
                Scope = Repeater;
                ShortCutKey = "Shift+F12";
                ToolTip = 'Restore the default selection for this layout.';

                trigger OnAction()
                var
                    TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
                    EmptyGuid: Guid;
                begin
                    if (TenantReportLayoutSelection.Get(Rec."Report ID", SelectedCompany, EmptyGuid)) then
                        TenantReportLayoutSelection.Delete(true);

                    RestoreDefaultSelection();
                end;
            }

            action(Customizations)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Custom Layouts';
                Image = "Report";
                RunObject = Page "Custom Report Layouts";
                RunPageLink = "Report ID" = field("Report ID");
                ToolTip = 'View or edit the custom layouts that are available for a report.';
            }
            action(RunReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Run Report';
                Image = "Report";
                ToolTip = 'Run a test report.';

                trigger OnAction()
                begin
                    REPORT.RunModal(Rec."Report ID");
                end;
            }
            action(BulkUpdate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update All layouts';
                Image = UpdateXML;
                ToolTip = 'Update specific report layouts or all custom report layouts that might be affected by dataset changes.';

                trigger OnAction()
                var
                    DocumentReportMgt: Codeunit "Document Report Mgt.";
                begin
                    DocumentReportMgt.BulkUpgrade(false);
                end;
            }
            action(TestUpdate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Layout Updates';
                Image = TestReport;
                ToolTip = 'Check if there are any updates detected.';

                trigger OnAction()
                var
                    DocumentReportMgt: Codeunit "Document Report Mgt.";
                begin
                    DocumentReportMgt.BulkUpgrade(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SelectLayout_Promoted; SelectLayout)
                {
                }
                actionref(RestoreDefaultLayout_Promoted; RestoreDefaultLayout)
                {
                }
                actionref(RunReport_Promoted; RunReport)
                {
                }
                actionref(Customizations_Promoted; Customizations)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetRec();
    end;

    trigger OnAfterGetRecord()
    begin
        GetRec();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not IsInitialized then
            InitializeData();
        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        SelectedCompany := CompanyName;
    end;

    var
        ReportLayoutSelection: Record "Report Layout Selection";
        SelectedCompany: Text[30];
        WrongCompanyErr: Label 'You cannot select a layout that is specific to another company.';
        DefaultLbl: Label '(Default)';
        CustomLayoutDescription: Text;
        IsInitialized: Boolean;
        CouldNotFindCustomReportLayoutErr: Label 'There is no custom report layout with %1 in the description.', Comment = '%1 Description of custom report layout';
        CouldNotFindBuiltInReportLayoutErr: Label 'There is no built-in report layout with %1 in the description.', Comment = '%1 Description of custom report layout';

    procedure UpdateRec()
    begin
        if ReportLayoutSelection.Get(Rec."Report ID", SelectedCompany) then begin
            ReportLayoutSelection := Rec;
            ReportLayoutSelection."Report Name" := Rec."Report Name";
            ReportLayoutSelection."Company Name" := SelectedCompany;
            OnUpdateRecOnBeforeModify(ReportLayoutSelection, Rec, SelectedCompany);
            ReportLayoutSelection.Modify();
        end else begin
            Clear(ReportLayoutSelection);
            ReportLayoutSelection := Rec;
            ReportLayoutSelection."Report Name" := Rec."Report Name";
            ReportLayoutSelection."Company Name" := SelectedCompany;
            OnUpdateRecOnBeforeInsert(ReportLayoutSelection, Rec, SelectedCompany);
            ReportLayoutSelection.Insert(true);
        end;
    end;

    local procedure GetRec()
    begin
        if not Rec.Get(Rec."Report ID", '') then
            exit;

        UpdateTempRec();

        OnGetRecOnBeforeModify(Rec, SelectedCompany);
        Rec.Modify();
    end;

    local procedure UpdateTempRec()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportMetadata: Record "Report Metadata";
    begin
        // Update the temporary record's field with the values from the actual record

        if not ReportLayoutSelection.Get(Rec."Report ID", SelectedCompany) then begin
            ReportLayoutSelection.Init();
            ReportLayoutSelection.Type := Rec.GetDefaultType(Rec."Report ID");
        end;

        Rec.Type := ReportLayoutSelection.Type;
        Rec."Custom Report Layout Code" := ReportLayoutSelection."Custom Report Layout Code";
        case Rec.Type of
            Rec.Type::"Custom Layout":
                Rec.CalcFields("Report Layout Description");
            else
                if TenantReportLayoutSelection.Get(Rec."Report ID", SelectedCompany) then
                    Rec."Report Layout Description" := TenantReportLayoutSelection."Layout Name"
                else
                    if ReportMetadata.Get(Rec."Report ID") then
                        Rec."Report Layout Description" := ReportMetadata.DefaultLayoutName
                    else
                        Rec."Report Layout Description" := DefaultLbl;
        end;

        CustomLayoutDescription := Rec."Report Layout Description";
    end;

    local procedure LookupLayout()
    begin
        case Rec.Type of
            Rec.Type::"Custom Layout":
                if not SelectReportLayout() then
                    exit;
            else
                if not SelectBuiltInReportLayout() then
                    exit;
        end;

        GetRec();
        if (Rec.Type = Rec.Type::"Custom Layout") and
           (Rec."Custom Report Layout Code" = '')
        then begin
            Rec.Validate(Type, Rec.GetDefaultType(Rec."Report ID"));
            UpdateRec();
        end;
        CurrPage.Update(false);
    end;

    local procedure SelectBuiltInReportLayout(): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        IsReportLayoutSelected: Boolean;
    begin
        ReportLayoutList.FilterGroup(4);
        ApplyFilterToReportLayoutList(ReportLayoutList);
        ReportLayoutList.FilterGroup(0);
        OnSelectReportLayout(ReportLayoutList, IsReportLayoutSelected);
        if IsReportLayoutSelected then begin
            UpdateTenantLayoutSelection(ReportLayoutList);
            UpdateRec();
            exit(true);
        end
        else
            RestoreDefaultSelection();

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectReportLayout(var ReportLayoutList: Record "Report Layout List"; var Handled: Boolean)
    begin
    end;

    local procedure RestoreDefaultSelection()
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        if (TenantReportLayoutSelection.Get(Rec."Report ID", SelectedCompany, EmptyGuid)) then begin
            ReportLayoutList.SetRange("Report ID", TenantReportLayoutSelection."Report ID");
            ReportLayoutList.SetRange("Name", TenantReportLayoutSelection."Layout Name");
            ReportLayoutList.SetRange("Application ID", TenantReportLayoutSelection."App ID");

            if (ReportLayoutList.FindFirst()) then
                SetDefaultSelectionFromReportLayoutList(ReportLayoutList, TenantReportLayoutSelection."Layout Name");
        end
        else
            Rec.Validate(Type, Rec.GetDefaultType(Rec."Report ID"));

        UpdateRec();
    end;

    local procedure SetDefaultSelectionFromReportLayoutList(var ReportLayoutList: Record "Report Layout List"; LayoutName: Text[250])
    begin
        Rec.Validate(Type, LayoutFormatToType(ReportLayoutList."Layout Format"));
        Rec."Report Layout Description" := LayoutName;
        CustomLayoutDescription := LayoutName;
    end;

    local procedure LayoutFormatToType(LayoutFormat: Integer): Integer
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        case LayoutFormat of
            ReportLayoutList."Layout Format"::RDLC:
                exit(Rec.Type::"RDLC (built-in)");
            ReportLayoutList."Layout Format"::Word:
                exit(Rec.Type::"Word (built-in)");
            ReportLayoutList."Layout Format"::Excel:
                exit(Rec.Type::"Excel Layout");
            ReportLayoutList."Layout Format"::Custom:
                exit(Rec.Type::"External Layout");
        end;

        exit(Rec.GetDefaultType(rec."Report ID"));
    end;

    local procedure ValidateBuiltInReportLayoutDescription()
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        if CustomLayoutDescription <> '' then begin
            ApplyFilterToReportLayoutList(ReportLayoutList);
            ReportLayoutList.SetFilter(Name, '%1', '@*' + CustomLayoutDescription + '*');
            if not ReportLayoutList.FindFirst() then
                Error(CouldNotFindBuiltInReportLayoutErr, CustomLayoutDescription);

            UpdateTenantLayoutSelection(ReportLayoutList);
        end else
            if TenantReportLayoutSelection.Get(Rec."Report ID", SelectedCompany) then
                TenantReportLayoutSelection.Delete(true);

        UpdateRec();
    end;

    local procedure SelectReportLayout(): Boolean
    var
        CustomReportLayout: Record "Custom Report Layout";
        OK: Boolean;
    begin
        CustomReportLayout.FilterGroup(4);
        CustomReportLayout.SetRange("Report ID", Rec."Report ID");
        CustomReportLayout.FilterGroup(0);
        CustomReportLayout.SetFilter("Company Name", '%1|%2', SelectedCompany, '');
        OK := PAGE.RunModal(PAGE::"Custom Report Layouts", CustomReportLayout) = ACTION::LookupOK;
        if OK then begin
            if not (CustomReportLayout."Company Name" in [SelectedCompany, '']) then
                Error(WrongCompanyErr);
            Rec."Custom Report Layout Code" := CustomReportLayout.Code;
            Rec.Type := Rec.Type::"Custom Layout";
            UpdateRec();
        end else
            if (Rec.Type = Rec.Type::"Custom Layout") and (Rec."Custom Report Layout Code" = '') then begin
                RestoreDefaultSelection();
                UpdateRec();
            end;
        exit(OK);
    end;

    local procedure InitializeData()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        ReportMetadata.SetRange(ProcessingOnly, false);
        if ReportMetadata.FindSet() then
            repeat
                Rec.Init();
                Rec."Report ID" := ReportMetadata.ID;
                Rec."Report Name" := ReportMetadata.Caption;
                UpdateTempRec();
                Rec.Insert();
            until ReportMetadata.Next() = 0;
        if Rec.FindFirst() then;
        IsInitialized := true;
    end;

    local procedure ApplyFilterToReportLayoutList(var ReportLayoutList: Record "Report Layout List")
    begin
        ReportLayoutList.SetRange("Report ID", Rec."Report ID");
        case Rec.Type of
            Rec.Type::"RDLC (built-in)":
                ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::RDLC);
            Rec.Type::"Word (built-in)":
                ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
            Rec.Type::"Excel Layout":
                ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Excel);
            Rec.Type::"External Layout":
                ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Custom);
        end;
    end;

    local procedure UpdateTenantLayoutSelection(ReportLayoutList: Record "Report Layout List")
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
        TenantReportLayoutSelection."Report ID" := ReportLayoutList."Report ID";
        TenantReportLayoutSelection."User ID" := EmptyGuid;
        if not TenantReportLayoutSelection.Insert(true) then
            TenantReportLayoutSelection.Modify(true);
    end;

    procedure GetSelectedCompanyName(): Text[30]
    begin
        exit(SelectedCompany);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRecOnBeforeModify(var ReportLayoutSelection: Record "Report Layout Selection"; SelectedCompany: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnBeforeInsert(var ToReportLayoutSelection: Record "Report Layout Selection"; FromReportLayoutSelection: Record "Report Layout Selection"; SelectedCompany: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnBeforeModify(var ToReportLayoutSelection: Record "Report Layout Selection"; FromReportLayoutSelection: Record "Report Layout Selection"; SelectedCompany: Text[30])
    begin
    end;
}

