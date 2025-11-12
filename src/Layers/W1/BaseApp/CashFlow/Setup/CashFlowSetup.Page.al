// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

using System.AI;
using System.Privacy;
using System.Telemetry;

page 846 "Cash Flow Setup"
{
    // HYPERLINK('https://go.microsoft.com/fwlink/?linkid=828352');

    ApplicationArea = Basic, Suite;
    Caption = 'Cash Flow Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Cash Flow Setup";
    UsageCategory = Administration;
    Permissions = tabledata "Cash Flow Setup" = I;
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Automatic Update Frequency"; Rec."Automatic Update Frequency")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the automatic update frequency of the cash flow forecast. The Cash Flow Forecast with "Show in Chart on Role Center" set will be used for the automatic update.';
                }
            }
            group(Accounts)
            {
                Caption = 'Accounts';
                field("Receivables CF Account No."; Rec."Receivables CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receivables account number that is used in cash flow forecasts.';
                }
                field("Payables CF Account No."; Rec."Payables CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payables account number that is used in cash flow forecasts.';
                }
                field("Sales Order CF Account No."; Rec."Sales Order CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales order account number that is used in cash flow forecasts.';
                }
                field("Purch. Order CF Account No."; Rec."Purch. Order CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase order account number that is used in cash flow forecasts.';
                }
                field("FA Budget CF Account No."; Rec."FA Budget CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset budget account number that is used in cash flow forecasts.';
                }
                field("FA Disposal CF Account No."; Rec."FA Disposal CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset disposal account number that is used in cash flow forecasts.';
                }
                field("Job CF Account No."; Rec."Job CF Account No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project account number that is used in cash flow forecasts.';
                }
                field("Tax CF Account No."; Rec."Tax CF Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax account number that is used in cash flow forecasts.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Cash Flow Forecast No. Series"; Rec."Cash Flow Forecast No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that is used in cash flow forecasts.';
                }
            }
            group(Tax)
            {
                Caption = 'Tax';
                field("Taxable Period"; Rec."Taxable Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how often tax payment is registered.';
                }
                field("Tax Payment Window"; Rec."Tax Payment Window")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a date formula for calculating how soon after the previous tax period finished, the tax payment is registered.';
                }
                field("Tax Bal. Account Type"; Rec."Tax Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the balancing account that your taxes are paid to.';

                    trigger OnValidate()
                    begin
                        TaxAccountTypeValid := Rec.HasValidTaxAccountInfo();
                        CurrPage.Update();
                    end;
                }
                field("Tax Bal. Account No."; Rec."Tax Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = TaxAccountTypeValid;
                    ToolTip = 'Specifies the balancing account that your taxes are paid to.';
                }
            }
            group("Azure AI")
            {
                Caption = 'Azure AI';
                field("Period Type"; Rec."Period Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of period that you want to see the forecast by.';
                }
                field("Historical Periods"; Rec."Historical Periods")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of historical periods to include in the forecast.';
                }
                field(Horizon; Rec.Horizon)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many periods you want the forecast to cover.';
                }
                field("API URL"; Rec."API URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the API URI to the AzureML instance.';
                }
                field("API Key"; APIKey)
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the API Key to the AzureML time series experiment.';

                    trigger OnValidate()
                    begin
                        if not IsNullGuid(Rec."Service Pass API Key ID") then
                            Rec.EnableEncryption();
                        if APIKey <> DummyApiKeyTok then
                            Rec.SaveUserDefinedAPIKey(APIKey);
                    end;
                }
                field("Time Series Model"; Rec."Time Series Model")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time series model to be used for the cash flow forecast.';
                }
                field("Variance %"; Rec."Variance %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the range of deviation, plus or minus, that you''ll accept in the forecast. Lower percentages represent more accurate forecasts, and are typically between 20 and 40. Forecasts outside the range are considered inaccurate, and do not display.';
                }
                field(Enabled; Rec."Azure AI Enabled")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies status of Azure AI forecast.';
                    trigger OnValidate();
                    var
                        AuditLog: Codeunit "Audit Log";
                        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                        CashFlowForecastConsentProvidedLbl: Label 'Cash Flow Forecast feature, Azure AI - consent provided by UserSecurityId %1.', Locked = true;
                    begin
                        if not xRec."Azure AI Enabled" and Rec."Azure AI Enabled" then
                            Rec."Azure AI Enabled" := CustomerConsentMgt.ConsentToMicrosoftServiceWithAI();
                        if Rec."Azure AI Enabled" then
                            AuditLog.LogAuditMessage(StrSubstNo(CashFlowForecastConsentProvidedLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);

                    end;
                }
                field("Total Proc. Time"; Format(AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning")))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Processing Time';
                    ToolTip = 'Specifies total processing time of the Azure Machine Learning Service.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Chart Options")
            {
                Caption = 'Chart Options';
#if not CLEAN26
                action("Open Azure AI Gallery")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Azure AI Gallery';
                    Gesture = None;
                    Image = LinkWeb;
                    ObsoleteReason = 'Webpage does not exist';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                    ToolTip = 'Explore models for Azure Machine Learning, and use Azure Machine Learning Studio to build, test, and deploy the Forecasting Model for Dynamics 365 Business Central.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        HyperLink('https://go.microsoft.com/fwlink/?linkid=828352');
                    end;
                }
#endif                
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
#if not CLEAN26
                actionref("Open Azure AI Gallery_Promoted"; "Open Azure AI Gallery")
                {
                    ObsoleteReason = 'Webpage does not exist';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                    Visible = false;
                }
#endif
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TaxAccountTypeValid := Rec.HasValidTaxAccountInfo();
        SetApiKey();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
        TaxAccountTypeValid: Boolean;
        [NonDebuggable]
        APIKey: Text[200];
        DummyApiKeyTok: Label '*', Locked = true;

    local procedure SetApiKey()
    begin
        if not Rec.GetUserDefinedAPIKeySecret().IsEmpty() then
            APIKey := DummyApiKeyTok;
    end;
}

