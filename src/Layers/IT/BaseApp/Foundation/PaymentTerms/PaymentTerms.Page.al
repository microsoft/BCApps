// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Integration.Dataverse;

page 4 "Payment Terms"
{
    AdditionalSearchTerms = 'Payment Conditions, Settlement Terms, Due Conditions, Billing Terms, Invoice Conditions, Trade Terms, Financial Conditions';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Terms';
    PageType = List;
    SourceTable = "Payment Terms";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this set of payment terms.';
                }
                field("Payment Nos."; Rec."Payment Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of installments allowed for this payment term.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an explanation of the payment terms.';
                }
                field("Fattura Payment Terms Code"; Rec."Fattura Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment terms for Fattura payments.';
                }
                field("Coupled to Dataverse"; CDSIsCoupledToRecord)
                {
                    ApplicationArea = All;
                    Caption = 'Coupled to Dataverse';
                    ToolTip = 'Specifies that the payment term is coupled to a payment term in Dataverse.';
                    Visible = CDSIntegrationEnabled;
                    Editable = false;
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
            action("&Calculation")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Calculation';
                Image = Calculate;
                RunObject = Page "Payment Terms Lines";
                RunPageLink = Type = const("Payment Terms"),
                              Code = field(Code);
                ToolTip = 'View or edit the conditions of the current payment term.';
            }
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                RunObject = Page "Payment Term Translations";
                RunPageLink = "Payment Term" = field(Code);
                ToolTip = 'View or edit descriptions for each payment method in different languages.';
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Image = Administration;
                Visible = CDSIntegrationEnabled;
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        PaymentTerms: Record "Payment Terms";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        PaymentTermsRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(PaymentTerms);
                        PaymentTermsRecordRef.GetTable(PaymentTerms);
                        CRMIntegrationManagement.UpdateMultipleNow(PaymentTermsRecordRef, true);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse Payment Terms.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineOptionMapping(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledUnitOfMeasure;
                        ToolTip = 'Couple payment terms in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            PaymentTerms: Record "Payment Terms";
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(PaymentTerms);
                            RecRef.GetTable(PaymentTerms);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CDSIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse Payment Terms.';

                        trigger OnAction()
                        var
                            PaymentTerms: Record "Payment Terms";
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(PaymentTerms);
                            RecRef.GetTable(PaymentTerms);
                            CRMIntegrationManagement.RemoveOptionMapping(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the payment terms table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowOptionLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

            }
            group(Category_Payment_Terms)
            {
                Caption = 'Payment Terms';

                actionref("&Calculation_Promoted"; "&Calculation")
                {
                }
                actionref("T&ranslation_Promoted"; "T&ranslation")
                {
                }
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CDSIntegrationEnabled;

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                    actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CDSIsCoupledToRecord := CDSIntegrationEnabled;
        if CDSIsCoupledToRecord then begin
            CRMOptionMapping.SetRange("Record ID", Rec.RecordId);
            CDSIsCoupledToRecord := not CRMOptionMapping.IsEmpty();
        end;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;

    var
        CDSIntegrationEnabled: Boolean;
        CDSIsCoupledToRecord: Boolean;
}
