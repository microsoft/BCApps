// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

page 691 "Payment Period List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Templates';
    CardPageId = "Payment Period Card";
    Editable = false;
    PageType = List;
    SourceTable = "Payment Period Header";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Reporting Scheme"; Rec."Reporting Scheme")
                {
                }
                field(Default; Rec.Default)
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateDefaultTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate Default Template';
                ToolTip = 'Creates the default payment period template for the auto-detected reporting scheme.';
                Image = Template;

                trigger OnAction()
                var
                    PaymentPeriodHeader: Record "Payment Period Header";
                    PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
                    PeriodHeaderCode: Code[20];
                begin
                    PeriodHeaderCode := PaymentPeriodMgt.GetDefaultTemplateCode();
                    if PaymentPeriodHeader.Get(PeriodHeaderCode) then
                        Error(TemplateAlreadyExistsErr, PeriodHeaderCode);

                    PaymentPeriodMgt.InsertDefaultTemplate();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(GenerateDefaultTemplate_Promoted; GenerateDefaultTemplate)
                {
                }
            }
        }
    }

    var
        TemplateAlreadyExistsErr: Label 'A payment period template with code %1 already exists.', Comment = '%1 = Payment Period Header Code';
}
