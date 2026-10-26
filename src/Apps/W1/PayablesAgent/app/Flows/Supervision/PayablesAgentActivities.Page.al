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
                        Presentation.DrillDownByState("PA Task State"::"Pending Processing");
                    end;
                }
                field(NeedAttention; NeedAttention)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Need attention';
                    ToolTip = 'Specifies the number of vendor invoices that need attention from the user.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Task State"::"Needs Attention");
                    end;
                }
                field(ReadyForReview; ReadyForReview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ready for review';
                    ToolTip = 'Specifies the number of vendor invoices that are ready for review.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Task State"::"Ready For Review");
                    end;
                }
                field(ProcessedThisMonth; ProcessedThisMonth)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processed this month';
                    ToolTip = 'Specifies the number of vendor invoices that have been processed this month.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Task State"::Processed);
                    end;
                }
                field(Rejected; Rejected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rejected';
                    ToolTip = 'Specifies the number of received sources that intake rejected before creating an agent task.';

                    trigger OnDrillDown()
                    begin
                        Presentation.DrillDownByState("PA Task State"::Rejected);
                    end;
                }
            }

        }
    }
    trigger OnOpenPage()
    begin
        PendingProcessing := PATaskCollection.CountByState("PA Task State"::"Pending Processing");
        NeedAttention := PATaskCollection.CountByState("PA Task State"::"Needs Attention");
        ReadyForReview := PATaskCollection.CountByState("PA Task State"::"Ready For Review");
        ProcessedThisMonth := PATaskCollection.CountByState("PA Task State"::Processed);
        Rejected := PATaskCollection.CountByState("PA Task State"::Rejected);
    end;
    var
        PATaskCollection: Codeunit "PA Task Collection";
        Presentation: Codeunit "PA Task Presentation";
        PendingProcessing, NeedAttention, ReadyForReview, ProcessedThisMonth, Rejected : Integer;
}