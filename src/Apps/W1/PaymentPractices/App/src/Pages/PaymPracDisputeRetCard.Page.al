// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

page 693 "Paym. Prac. Dispute Ret. Card"
{
    ApplicationArea = All;
    Caption = 'Dispute & Retention Details';
    PageType = Card;
    SourceTable = "Paym. Prac. Dispute Ret. Data";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group("Qualifying Contracts")
            {
                Caption = 'Qualifying Contracts';
                grid(QualifyingContractsGrid)
                {
                    group(QualifyingContractsInner)
                    {
                        ShowCaption = false;
                        field("Qualifying Contracts in Period"; Rec."Qualifying Contracts in Period")
                        {
                        }
                        field("Payments Made in Period"; Rec."Payments Made in Period")
                        {
                        }
                        field("Qual. Constr. Contr. in Period"; Rec."Qual. Constr. Contr. in Period")
                        {
                            Caption = 'Qual. Construction Contracts in Period';
                        }
                    }
                }
            }
            group("Payment Terms")
            {
                Caption = 'Payment Terms';
                grid(PaymentTermsGrid)
                {
                    group(PaymentTermsInner)
                    {
                        ShowCaption = false;
                        field("Shortest Standard Pmt. Period"; Rec."Shortest Standard Pmt. Period")
                        {
                        }
                        field("Longest Standard Pmt. Period"; Rec."Longest Standard Pmt. Period")
                        {
                        }
                        field("Standard Payment Terms Desc."; Rec."Standard Payment Terms Desc.")
                        {
                            Caption = 'Standard Payment Terms Description';
                            MultiLine = true;
                        }
                        field("Payment Terms Have Changed"; Rec."Payment Terms Have Changed")
                        {
                        }
                        field("Suppliers Notified of Changes"; Rec."Suppliers Notified of Changes")
                        {
                            Editable = Rec."Payment Terms Have Changed";
                        }
                        field("Max Contractual Pmt. Period"; Rec."Max Contractual Pmt. Period")
                        {
                        }
                        field("Max Contr. Pmt. Period Info"; Rec."Max Contr. Pmt. Period Info")
                        {
                            Caption = 'Max Contractual Pmt. Period Info';
                            MultiLine = true;
                        }
                        field("Other Pmt. Terms Information"; Rec."Other Pmt. Terms Information")
                        {
                            MultiLine = true;
                        }
                    }
                }
            }
            group("Construction Contract Retention")
            {
                Caption = 'Construction Contract Retention';
                grid(RetentionGrid)
                {
                    group(RetentionInner)
                    {
                        ShowCaption = false;
                        field("Has Constr. Contract Retention"; Rec."Has Constr. Contract Retention")
                        {
                            Caption = 'Has Construction Contract Retention';
                        }
                        field("Ret. Clause Used in Contracts"; Rec."Ret. Clause Used in Contracts")
                        {
                            Caption = 'Retention Clause Used in Contracts';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Retention in Std Pmt. Terms"; Rec."Retention in Std Pmt. Terms")
                        {
                            Caption = 'Retention in Standard Pmt. Terms';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Retention in Specific Circs."; Rec."Retention in Specific Circs.")
                        {
                            Caption = 'Retention in Specific Circumstances';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Retention Circs. Desc."; Rec."Retention Circs. Desc.")
                        {
                            Caption = 'Retention Circumstances Description';
                            Editable = Rec."Has Constr. Contract Retention" and Rec."Retention in Specific Circs.";
                            MultiLine = true;
                        }
                        field("Withholds Retent. from Subcon"; Rec."Withholds Retent. from Subcon")
                        {
                            Caption = 'Withholds Retention from Subcontractors';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Contract Sum Threshold"; Rec."Contract Sum Threshold")
                        {
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Std Retention Pct Used"; Rec."Std Retention Pct Used")
                        {
                            Caption = 'Standard Retention Pct. Used';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Standard Retention Pct"; Rec."Standard Retention Pct")
                        {
                            Caption = 'Standard Retention %';
                            Editable = Rec."Has Constr. Contract Retention" and Rec."Std Retention Pct Used";
                        }
                        field("Terms Fairness Practice"; Rec."Terms Fairness Practice")
                        {
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Terms Fairness Desc."; Rec."Terms Fairness Desc.")
                        {
                            Caption = 'Terms Fairness Description';
                            Editable = Rec."Has Constr. Contract Retention" and Rec."Terms Fairness Practice";
                            MultiLine = true;
                        }
                        field("Release Mechanism Desc."; Rec."Release Mechanism Desc.")
                        {
                            Caption = 'Release Mechanism Description';
                            Editable = Rec."Has Constr. Contract Retention";
                            MultiLine = true;
                        }
                        field("Release Within Prescribed Days"; Rec."Release Within Prescribed Days")
                        {
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Prescribed Days Desc."; Rec."Prescribed Days Desc.")
                        {
                            Caption = 'Prescribed Days Description';
                            Editable = Rec."Has Constr. Contract Retention" and Rec."Release Within Prescribed Days";
                            MultiLine = true;
                        }
                        field("Retent. Withheld from Suppls."; Rec."Retent. Withheld from Suppls.")
                        {
                            Caption = 'Retention Withheld from Suppliers';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Retention Withheld by Clients"; Rec."Retention Withheld by Clients")
                        {
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Gross Payments Constr. Contr."; Rec."Gross Payments Constr. Contr.")
                        {
                            Caption = 'Gross Construction Contract Payments';
                            Editable = Rec."Has Constr. Contract Retention";
                        }
                        field("Pct Retention vs Client Ret."; Rec."Pct Retention vs Client Ret.")
                        {
                            Caption = '% Retention vs Client Retention';
                        }
                        field("Pct Retent. vs Gross Payments"; Rec."Pct Retent. vs Gross Payments")
                        {
                            Caption = '% Retention vs Gross Payments';
                        }
                    }
                }
            }
            group("Dispute Resolution")
            {
                Caption = 'Dispute Resolution';
                field("Dispute Resolution Process"; Rec."Dispute Resolution Process")
                {
                    MultiLine = true;
                }
            }
            group("Payment Policies")
            {
                Caption = 'Payment Policies';
                grid(PaymentPoliciesGrid)
                {
                    group(PaymentPoliciesInner)
                    {
                        ShowCaption = false;
                        field("Is Payment Code Member"; Rec."Is Payment Code Member")
                        {
                        }
                        field("Offers E-Invoicing"; Rec."Offers E-Invoicing")
                        {
                        }
                        field("Offers Supply Chain Finance"; Rec."Offers Supply Chain Finance")
                        {
                        }
                        field("Policy Covers Deduct. Charges"; Rec."Policy Covers Deduct. Charges")
                        {
                            Caption = 'Policy Covers Deduction Charges';
                        }
                        field("Has Deducted Charges in Period"; Rec."Has Deducted Charges in Period")
                        {
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyFromPreviousPeriod)
            {
                Caption = 'Copy from Previous Period';
                ToolTip = 'Copies standing-policy fields from the most recent previous period, clearing period-specific fields.';
                Image = Copy;

                trigger OnAction()
                begin
                    Rec.CopyFromPrevious();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(CopyFromPreviousPeriod_Promoted; CopyFromPreviousPeriod)
            {
            }
        }
    }
}
