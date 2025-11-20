// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Integration.Graph;
using System.IO;
using System.Reflection;
using Microsoft.API.Upgrade;
using System.Telemetry;

page 5469 "API Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'API Setup';
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Config. Tmpl. Selection Rules";
    SourceTableView = sorting(Order)
                      order(ascending);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Order"; Rec.Order)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the order of the entry.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table that the template applies to.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = All;
                    TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page),
                                                                         "Object Subtype" = const('API'));
                    ToolTip = 'Specifies the API web service page that the template applies to.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = All;
                    TableRelation = "Config. Template Header".Code where("Table ID" = field("Table ID"));
                    ToolTip = 'Specifies the config template that should be applied';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the API template selection.';
                }
                field("<Template Code>"; ConditionsText)
                {
                    ApplicationArea = All;
                    Caption = 'Conditions';
                    Editable = false;
                    ToolTip = 'Specifies the condition for when the config template should be applied.';

                    trigger OnAssistEdit()
                    begin
                        Rec.SetSelectionCriteria();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(FixPurchOrder)
            {
                ApplicationArea = All;
                Caption = 'Fix Purchase Order API Records';
                Image = Setup;
                ToolTip = 'Updates records that are used by the purchaseOrders API';
                Visible = false;

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Purchase Order");
                end;
            }

            action(FixItemCategoryCode)
            {
                ApplicationArea = All;
                Caption = 'Fix Item Category Codes of Items';
                Image = Setup;
                ToolTip = 'Updates the item category codes of the item records';

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Item Cat. Code");
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ConditionsText := Rec.GetFiltersAsTextDisplay();
    end;

    trigger OnAfterGetRecord()
    begin
        ConditionsText := Rec.GetFiltersAsTextDisplay();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Selection Criteria");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        AuditLog: Codeunit "Audit Log";
        APISetupRecordCreatedLbl: Label 'A new API Setup record Table ID %1, Template Code %2, Page ID %3 is created by the UserSecurityId %4.', Locked = true;
    begin
        AuditLog.LogAuditMessage(StrSubstNo(APISetupRecordCreatedLbl, Rec."Table ID", Rec."Template Code", Rec."Page ID", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
    end;

    var
        ConditionsText: Text;
}

