// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

using Microsoft.CRM.BusinessRelation;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using System.Reflection;

page 9657 "Customer Report Selections"
{
    Caption = 'Document Layouts';
    DataCaptionFields = "Source No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Custom Report Selection";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                FreezeColumn = "Custom Report Description";
                field(Usage2; Usage2)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Usage';
                    ToolTip = 'Specifies which type of document the report is used for.';

                    trigger OnValidate()
                    begin
                        case Usage2 of
                            "Custom Report Selection Sales"::Quote:
                                Rec.Usage := "Report Selection Usage"::"S.Quote";
                            "Custom Report Selection Sales"::"Confirmation Order":
                                Rec.Usage := "Report Selection Usage"::"S.Order";
                            "Custom Report Selection Sales"::Invoice:
                                Rec.Usage := "Report Selection Usage"::"S.Invoice";
                            "Custom Report Selection Sales"::"Credit Memo":
                                Rec.Usage := "Report Selection Usage"::"S.Cr.Memo";
                            "Custom Report Selection Sales"::"Customer Statement":
                                Rec.Usage := "Report Selection Usage"::"C.Statement";
                            "Custom Report Selection Sales"::"Job Quote":
                                Rec.Usage := "Report Selection Usage"::JQ;
                            "Custom Report Selection Sales"::Reminder:
                                Rec.Usage := "Report Selection Usage"::Reminder;
                            "Custom Report Selection Sales"::Shipment:
                                Rec.Usage := "Report Selection Usage"::"S.Shipment";
                            "Custom Report Selection Sales"::"Pro Forma Invoice":
                                Rec.Usage := "Report Selection Usage"::"Pro Forma S. Invoice";
                            else
                                OnValidateUsage2OnCaseElse(Rec, Usage2.AsInteger());
                        end;
                    end;
                }
                field(ReportID; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report ID';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field(ReportCaption; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Name';
                }
                field("Custom Report Description"; Rec."Custom Report Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Custom Layout Description';
                    DrillDown = true;
                    Lookup = true;
                    Visible = false;
                    trigger OnDrillDown()
                    begin
                        Rec.LookupCustomReportDescription();
                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupCustomReportDescription();
                        CurrPage.Update(true);
                    end;

                    trigger OnValidate()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if Rec."Custom Report Description" = '' then begin
                            Rec.Validate("Custom Report Layout Code", '');
                            Rec.Modify(true);
                        end else begin
                            CustomReportLayout.SetRange("Report ID", Rec."Report ID");
                            CustomReportLayout.SetFilter(Description, StrSubstNo('@*%1*', Rec."Custom Report Description"));
                            if not CustomReportLayout.FindFirst() then
                                Error(CouldNotFindCustomReportLayoutErr, Rec."Custom Report Description");

                            Rec.Validate("Custom Report Layout Code", CustomReportLayout.Code);
                            Rec.Modify(true);
                        end;
                    end;
                }
                field(SendToEmail; Rec."Send To Email")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send To Email';

                    trigger OnAssistEdit()
                    begin
                        Rec.ShowSelectedContacts();
                    end;
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Lookup = true;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.LookupEmailBodyDescription();
                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupEmailBodyDescription();
                        CurrPage.Update(true);
                    end;
                }
                field("Email Body Layout"; ReportSelectionsImpl.GetReportLayoutCaption(Rec."Report ID", Rec."Email Body Layout Name", Rec."Email Body Layout AppID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Email Body Layout';
                    ToolTip = 'Specifies the report layout used as email body.';

                    trigger OnDrillDown()
                    var
                        ReportLayoutListSelection: Record "Report Layout List";
                        ReportManagementCodeunit: Codeunit ReportManagement;
                        IsReportLayoutSelected: Boolean;
                    begin
                        if Rec.Sequence = 0 then begin
                            Rec.Insert(true);
                            Commit();
                        end;
                        ReportLayoutListSelection.SetRange("Report ID", Rec."Report ID");
                        ReportManagementCodeunit.OnSelectReportLayout(ReportLayoutListSelection, IsReportLayoutSelected);
                        if IsReportLayoutSelected then begin
                            Rec."Email Body Layout Name" := ReportLayoutListSelection."Name";
                            Rec."Email Body Layout AppID" := ReportLayoutListSelection."Application ID";
                            Rec.Modify();
                        end;
                    end;
                }
                field("Email Attachment Layout"; ReportSelectionsImpl.GetReportLayoutCaption(Rec."Report ID", Rec."Email Attachment Layout Name", Rec."Email Attachment Layout AppID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Email Attachment Layout';
                    ToolTip = 'Specifies the report layout used as email attachment.';

                    trigger OnDrillDown()
                    var
                        ReportLayoutListSelection: Record "Report Layout List";
                        ReportManagementCodeunit: Codeunit ReportManagement;
                        IsReportLayoutSelected: Boolean;
                    begin
                        ReportLayoutListSelection.SetRange("Report ID", Rec."Report ID");
                        ReportManagementCodeunit.OnSelectReportLayout(ReportLayoutListSelection, IsReportLayoutSelected);
                        if IsReportLayoutSelected then begin
                            Rec."Email Attachment Layout Name" := ReportLayoutListSelection."Name";
                            Rec."Email Attachment Layout AppID" := ReportLayoutListSelection."Application ID";
                            Rec.Modify();
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyFromReportSelectionsAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy from Report Selection';
                Image = Copy;
                ToolTip = 'Copy reports that are set up on the Report Selection page.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    CustomReportSelection: Record "Custom Report Selection";
                    Customer: Record Customer;
                begin
                    CustomReportSelection := Rec;
                    FilterCustomerUsageReportSelections(ReportSelections);
                    Customer.Get(Rec."Source No.");
                    Rec.CopyFromReportSelections(ReportSelections, Database::Customer, Customer."No.");
                    CurrPage.SetRecord(CustomReportSelection);
                end;
            }

            action(SelectFromContactsAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Email from Contacts';
                Image = ContactFilter;
                ToolTip = 'Select an email address from the list of contacts.';

                trigger OnAction()
                var
                    ContBusRel: Record "Contact Business Relation";
                begin
                    Rec.GetSendToEmailFromContactsSelection(ContBusRel."Link to Table"::Customer.AsInteger(), Rec.GetFilter("Source No."));
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyFromReportSelectionsAction_Promoted; CopyFromReportSelectionsAction)
                {
                }
                actionref(SelectFromContactsAction_Promoted; SelectFromContactsAction)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        MapTableUsageValueToPageValue();
        Rec.GetSendToEmail(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.InitUsage();
        MapTableUsageValueToPageValue();
    end;

    var
        ReportSelectionsImpl: Codeunit "Report Selections Impl";
        CouldNotFindCustomReportLayoutErr: Label 'There is no custom report layout with %1 in the description.', Comment = '%1 Description of custom report layout';

    protected var
        Usage2: Enum "Custom Report Selection Sales";

    local procedure MapTableUsageValueToPageValue()
    begin
        case Rec.Usage of
            "Report Selection Usage"::"S.Quote":
                Usage2 := "Custom Report Selection Sales"::Quote;
            "Report Selection Usage"::"S.Order":
                Usage2 := "Custom Report Selection Sales"::"Confirmation Order";
            "Report Selection Usage"::"S.Invoice":
                Usage2 := "Custom Report Selection Sales"::Invoice;
            "Report Selection Usage"::"S.Cr.Memo":
                Usage2 := "Custom Report Selection Sales"::"Credit Memo";
            "Report Selection Usage"::"C.Statement":
                Usage2 := "Custom Report Selection Sales"::"Customer Statement";
            "Report Selection Usage"::JQ:
                Usage2 := "Custom Report Selection Sales"::"Job Quote";
            "Report Selection Usage"::Reminder:
                Usage2 := "Custom Report Selection Sales"::Reminder;
            "Report Selection Usage"::"S.Shipment":
                Usage2 := "Custom Report Selection Sales"::Shipment;
            "Report Selection Usage"::"Pro Forma S. Invoice":
                Usage2 := "Custom Report Selection Sales"::"Pro Forma Invoice";
        end;

        OnAfterOnMapTableUsageValueToPageValue(Rec, Usage2);
    end;

    local procedure FilterCustomerUsageReportSelections(var ReportSelections: Record "Report Selections")
    begin
        ReportSelections.SetFilter(
            Usage, '%1|%2|%3|%4|%5|%6|%7|%8|%9',
            "Report Selection Usage"::"S.Quote",
            "Report Selection Usage"::"S.Order",
            "Report Selection Usage"::"S.Invoice",
            "Report Selection Usage"::"S.Cr.Memo",
            "Report Selection Usage"::"C.Statement",
            "Report Selection Usage"::JQ,
            "Report Selection Usage"::Reminder,
            "Report Selection Usage"::"S.Shipment",
            "Report Selection Usage"::"Pro Forma S. Invoice");

        OnAfterFilterCustomerUsageReportSelections(ReportSelections);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnMapTableUsageValueToPageValue(CustomReportSelection: Record "Custom Report Selection"; var Usage2: Enum "Custom Report Selection Sales")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUsage2OnCaseElse(var CustomReportSelection: Record "Custom Report Selection"; ReportUsage: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterCustomerUsageReportSelections(var ReportSelections: Record "Report Selections")
    begin
    end;
}
