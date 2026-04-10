namespace Microsoft.SubscriptionBilling.PowerBIReports;

using Microsoft.PowerBIReports;

pageextension 8014 "SubBill PBI Assisted Setup" extends "PowerBI Assisted Setup"
{
    layout
    {
        addlast(Step5)
        {
            group(SubscriptionBillingReport)
            {
                Caption = 'Subscription Billing';
                InstructionalText = 'Configure the Power BI Subscription Billing App.';
#if not CLEAN28
#pragma warning disable AL0801
#endif
                field("Subscription Bill. Report Name"; Rec."Subs. Billing Report Name")
                {
                    Caption = 'Power BI Subscription Billing Report';
                    ToolTip = 'Specifies the Power BI Subscription Billing Report.';
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        SetupHelper: Codeunit "Power BI Report Setup";
                    begin
                        SetupHelper.EnsureUserAcceptedPowerBITerms();
                        SetupHelper.LookupPowerBIReport(Rec."Subscription Billing Report ID", Rec."Subs. Billing Report Name");
                    end;
                }
#if not CLEAN28
#pragma warning disable AL0801
#endif
            }
        }
    }
}