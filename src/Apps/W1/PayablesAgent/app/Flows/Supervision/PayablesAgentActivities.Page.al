// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.PayablesAgent;

// Shows task-state counts and drill-downs to human supervisors rather than reporting historical agent-performance KPIs.
page 3310 "Payables Agent Activities"
{
    PageType = CardPart;
    RefreshOnActivate = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Caption = 'Payables Agent', Locked = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            cuegroup(PurchaseDocuments)
            {
                Caption = 'Purchase documents';

                field(PendingProcessing; PendingProcessing)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending processing';
                    ToolTip = 'Specifies the number of vendor invoices that are pending processing.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Work Item State"::"Pending Processing");
                    end;
                }
                field(NeedAttention; NeedAttention)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Need attention';
                    ToolTip = 'Specifies the number of vendor invoices that need attention from the user.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Work Item State"::"Needs Attention");
                    end;
                }
                field(ReadyForReview; ReadyForReview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ready for review';
                    ToolTip = 'Specifies the number of vendor invoices that are ready for review.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Work Item State"::"Ready For Review");
                    end;
                }
                field(ProcessedThisMonth; ProcessedThisMonth)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processed this month';
                    ToolTip = 'Specifies the number of vendor invoices that have been processed this month.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Work Item State"::Processed);
                    end;
                }
                field(Rejected; Rejected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rejected';
                    ToolTip = 'Specifies the number of received sources that intake rejected before creating an agent task.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Work Item State"::Rejected);
                    end;
                }
            }

        }
    }
    trigger OnOpenPage()
    var
        Counts: Dictionary of [Enum "PA Work Item State", Integer];
    begin
        WorkItems.GetCountsByState(Counts);
        PendingProcessing := Counts.Get("PA Work Item State"::"Pending Processing");
        NeedAttention := Counts.Get("PA Work Item State"::"Needs Attention");
        ReadyForReview := Counts.Get("PA Work Item State"::"Ready For Review");
        ProcessedThisMonth := Counts.Get("PA Work Item State"::Processed);
        Rejected := Counts.Get("PA Work Item State"::Rejected);
    end;

    var
        WorkItems: Codeunit "PA Work Item Collection";
        Presentation: Codeunit "PA Work Item Presentation";
        PendingProcessing, NeedAttention, ReadyForReview, ProcessedThisMonth, Rejected : Integer;
}