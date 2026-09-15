// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.CRM.BusinessRelation;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using System.Reflection;

page 9658 "Vendor Report Selections"
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
                            Usage2::"Purchase Order":
                                Rec.Usage := Rec.Usage::"P.Order";
                            Usage2::"Vendor Remittance":
                                Rec.Usage := Rec.Usage::"V.Remittance";
                            Usage2::"Vendor Remittance - Posted Entries":
                                Rec.Usage := Rec.Usage::"P.V.Remit.";
                            Usage2::"Posted Return Shipment":
                                Rec.Usage := Rec.Usage::"P.Ret.Shpt.";
                            else
                                OnValidateUsage2OnCaseElse(Rec, Usage2);
                        end;
                    end;
                }
                field(ReportID; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report ID';
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
                    Vendor: Record Vendor;
                begin
                    CustomReportSelection := Rec;
                    FilterVendorUsageReportSelections(ReportSelections);
                    Vendor.Get(Rec."Source No.");
                    Rec.CopyFromReportSelections(ReportSelections, Database::Vendor, Vendor."No.");
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
                    Rec.GetSendToEmailFromContactsSelection(ContBusRel."Link to Table"::Vendor.AsInteger(), Rec.GetFilter("Source No."));
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
        // Set the default usage to the same as the page default.
        if Rec.Usage = Rec.Usage::"S.Quote" then
            Rec.Usage := Rec.Usage::"P.Order";

        MapTableUsageValueToPageValue();
    end;

    var
        ReportSelectionsImpl: Codeunit "Report Selections Impl";
        CouldNotFindCustomReportLayoutErr: Label 'There is no custom report layout with %1 in the description.', Comment = '%1 Description of custom report layout';

    protected var
        Usage2: Enum "Report Selection Usage Vendor";

    local procedure MapTableUsageValueToPageValue()
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        case Rec.Usage of
            CustomReportSelection.Usage::"P.Order":
                Usage2 := Usage2::"Purchase Order";
            CustomReportSelection.Usage::"V.Remittance":
                Usage2 := Usage2::"Vendor Remittance";
            CustomReportSelection.Usage::"P.V.Remit.":
                Usage2 := Usage2::"Vendor Remittance - Posted Entries";
            CustomReportSelection.Usage::"P.Ret.Shpt.":
                Usage2 := Usage2::"Posted Return Shipment";
            else
                OnMapTableUsageValueToPageValueOnCaseElse(CustomReportSelection, Usage2, Rec);
        end;
    end;

    local procedure FilterVendorUsageReportSelections(var ReportSelections: Record "Report Selections")
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        ReportSelections.SetFilter(
            Usage, '%1|%2|%3|%4',
            CustomReportSelection.Usage::"P.Order",
            CustomReportSelection.Usage::"V.Remittance",
            CustomReportSelection.Usage::"P.V.Remit.",
            CustomReportSelection.Usage::"P.Ret.Shpt.");

        OnAfterFilterVendorUsageReportSelections(ReportSelections);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterVendorUsageReportSelections(var ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMapTableUsageValueToPageValueOnCaseElse(CustomReportSelection: Record "Custom Report Selection"; var ReportUsage: Enum "Report Selection Usage Vendor"; Rec: Record "Custom Report Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUsage2OnCaseElse(var CustomReportSelection: Record "Custom Report Selection"; ReportUsage: Enum "Report Selection Usage Vendor")
    begin
    end;
}

