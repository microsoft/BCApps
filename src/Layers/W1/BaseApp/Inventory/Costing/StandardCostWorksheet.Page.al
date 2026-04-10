// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;

page 5841 "Standard Cost Worksheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Standard Cost Worksheet';
    DataCaptionFields = "Standard Cost Worksheet Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Standard Cost Worksheet";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrWkshName; CurrWkshName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the Standard Cost Worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    if PAGE.RunModal(0, StdCostWkshName) = ACTION::LookupOK then begin
                        CurrWkshName := StdCostWkshName.Name;
                        Rec.FilterGroup := 2;
                        Rec.SetRange("Standard Cost Worksheet Name", CurrWkshName);
                        Rec.FilterGroup := 0;
                        if Rec.Find('-') then;
                    end;
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    CurrWkshNameOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Standard Cost"; Rec."Standard Cost")
                {
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                }
                field("New Standard Cost"; Rec."New Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                }
                field("New Indirect Cost %"; Rec."New Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                }
                field("New Overhead Rate"; Rec."New Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                }
                field(Implemented; Rec.Implemented)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Single-Lvl Material Cost"; Rec."Single-Lvl Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Single-Lvl Material Cost"; Rec."New Single-Lvl Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Single-Lvl Cap. Cost"; Rec."Single-Lvl Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Single-Lvl Cap. Cost"; Rec."New Single-Lvl Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Single-Lvl Subcontrd Cost"; Rec."Single-Lvl Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Single-Lvl Subcontrd Cost"; Rec."New Single-Lvl Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Single-Lvl Cap. Ovhd Cost"; Rec."Single-Lvl Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Single-Lvl Cap. Ovhd Cost"; Rec."New Single-Lvl Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Single-Lvl Mfg. Ovhd Cost"; Rec."Single-Lvl Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Single-Lvl Mfg. Ovhd Cost"; Rec."New Single-Lvl Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Rolled-up Material Cost"; Rec."Rolled-up Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Rolled-up Material Cost"; Rec."New Rolled-up Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Rolled-up Cap. Cost"; Rec."Rolled-up Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Rolled-up Cap. Cost"; Rec."New Rolled-up Cap. Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Rolled-up Subcontrd Cost"; Rec."Rolled-up Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Rolled-up Subcontrd Cost"; Rec."New Rolled-up Subcontrd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Rolled-up Cap. Ovhd Cost"; Rec."Rolled-up Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Rolled-up Cap. Ovhd Cost"; Rec."New Rolled-up Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Rolled-up Mfg. Ovhd Cost"; Rec."Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("New Rolled-up Mfg. Ovhd Cost"; Rec."New Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the page to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Standard Cost Worksheet Name")), Enum::"Edit in Excel Filter Type"::Equal, CurrWkshName, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(CopyStr(CurrPage.Caption, 1, 240), Page::"Standard Cost Worksheet");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        StdCostWkshName.Get(Rec."Standard Cost Worksheet Name");
        Rec.Type := xRec.Type;
        Rec."Replenishment System" := Rec."Replenishment System"::Assembly;
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();

        if Rec."Standard Cost Worksheet Name" <> '' then // called from batch
            CurrWkshName := Rec."Standard Cost Worksheet Name";

        if not StdCostWkshName.Get(CurrWkshName) then
            if not StdCostWkshName.FindFirst() then begin
                StdCostWkshName.Name := DefaultNameTxt;
                StdCostWkshName.Description := DefaultNameTxt;
                StdCostWkshName.Insert();
            end;
        CurrWkshName := StdCostWkshName.Name;

        Rec.FilterGroup := 2;
        Rec.SetRange("Standard Cost Worksheet Name", CurrWkshName);
        Rec.FilterGroup := 0;
    end;

    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
        DefaultNameTxt: Label 'Default';
        IsSaaSExcelAddinEnabled: Boolean;

    protected var
        CurrWkshName: Code[10];

    local procedure CurrWkshNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        Commit();
        Rec.FilterGroup := 2;
        Rec.SetRange("Standard Cost Worksheet Name", CurrWkshName);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
        CurrPage.Update(false);
    end;
}

