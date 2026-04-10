namespace Microsoft.SubscriptionBilling.PowerBIReports;

using Microsoft.PowerBIReports;

pageextension 8011 "SubBill PBI Reports Setup" extends "PowerBI Reports Setup"
{
    layout
    {
        addbefore(Dimensions)
        {
            group(SubscriptionBillingReportSetup)
            {
                Caption = 'Subscription Billing Report';
                group(SubscriptionBillingGeneralSetup)
                {
                    ShowCaption = false;
#if not CLEAN28
#pragma warning disable AL0801
#endif
                    field("Subscription Bill. Report Name"; Format(Rec."Subs. Billing Report Name"))
                    {
                        ApplicationArea = All;
                        Caption = 'Power BI Subscription Billing App';
                        ToolTip = 'Specifies where you have installed the Power BI Subscription Billing App.';

                        trigger OnAssistEdit()
                        var
                            SetupHelper: Codeunit "Power BI Report Setup";
                        begin
                            SetupHelper.EnsureUserAcceptedPowerBITerms();
                            SetupHelper.LookupPowerBIReport(Rec."Subscription Billing Report ID", Rec."Subs. Billing Report Name");
                        end;
                    }
#if not CLEAN28
#pragma warning restore AL0801
#endif
                }
            }
        }
    }
}