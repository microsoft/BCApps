// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Utilities;

report 10708 "Make 347 Declaration Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/Make347DeclarationLabels.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = '347 Declaration Labels';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Bucle; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(A; A)
            {
            }
            column(B; B)
            {
            }
            column(C; C)
            {
            }
            column(F; F)
            {
            }
            column(D; D)
            {
            }
            column(G; G)
            {
            }
            column(Counter_1; Counter - 1)
            {
            }
            column(NoOfLabels; NoOfLabels)
            {
            }
            column(AA; AA)
            {
            }
            column(DD; DD)
            {
            }
            column(E; E)
            {
            }
            column(IsBody1; Counter = NoOfLabels + 1)
            {
            }
            column(PageCounter; PageCounter)
            {
            }
            column(Counter; Counter)
            {
            }
            column(NoOfLabels_Control26; NoOfLabels)
            {
            }
            column(Counter_1_Control38; Counter - 1)
            {
            }
            column(NoOfLabels_Control40; NoOfLabels)
            {
            }
            column(G_Control72; G)
            {
            }
            column(F_Control74; F)
            {
            }
            column(E_Control75; E)
            {
            }
            column(D_Control78; D)
            {
            }
            column(C_Control80; C)
            {
            }
            column(DD_Control81; DD)
            {
            }
            column(B_Control84; B)
            {
            }
            column(A_Control86; A)
            {
            }
            column(AA_Control87; AA)
            {
            }
            column(G_Control94; G)
            {
            }
            column(F_Control96; F)
            {
            }
            column(E_Control97; E)
            {
            }
            column(D_Control100; D)
            {
            }
            column(C_Control102; C)
            {
            }
            column(DD_Control103; DD)
            {
            }
            column(B_Control106; B)
            {
            }
            column(A_Control108; A)
            {
            }
            column(AA_Control109; AA)
            {
            }
            column(IsBody2; Counter <= NoOfLabels)
            {
            }
            column(Bucle_Number; Number)
            {
            }
            column(ACaption; ACaptionLbl)
            {
            }
            column(BCaption; BCaptionLbl)
            {
            }
            column(CCaption; CCaptionLbl)
            {
            }
            column(FCaption; FCaptionLbl)
            {
            }
            column(DCaption; DCaptionLbl)
            {
            }
            column(GCaption; GCaptionLbl)
            {
            }
            column(Counter_1Caption; Counter_1CaptionLbl)
            {
            }
            column(NoOfLabelsCaption; NoOfLabelsCaptionLbl)
            {
            }
            column(AACaption; AACaptionLbl)
            {
            }
            column(DDCaption; DDCaptionLbl)
            {
            }
            column(ECaption; ECaptionLbl)
            {
            }
            column(CounterCaption; CounterCaptionLbl)
            {
            }
            column(NoOfLabels_Control26Caption; NoOfLabels_Control26CaptionLbl)
            {
            }
            column(Counter_1_Control38Caption; Counter_1_Control38CaptionLbl)
            {
            }
            column(NoOfLabels_Control40Caption; NoOfLabels_Control40CaptionLbl)
            {
            }
            column(F_Control72Caption; F_Control72CaptionLbl)
            {
            }
            column(E_Control74Caption; E_Control74CaptionLbl)
            {
            }
            column(GG_Control75Caption; GG_Control75CaptionLbl)
            {
            }
            column(D_Control78Caption; D_Control78CaptionLbl)
            {
            }
            column(C_Control80Caption; C_Control80CaptionLbl)
            {
            }
            column(DD_Control81Caption; DD_Control81CaptionLbl)
            {
            }
            column(B_Control84Caption; B_Control84CaptionLbl)
            {
            }
            column(A_Control86Caption; A_Control86CaptionLbl)
            {
            }
            column(AA_Control87Caption; AA_Control87CaptionLbl)
            {
            }
            column(G_Control94Caption; G_Control94CaptionLbl)
            {
            }
            column(E_Control96Caption; E_Control96CaptionLbl)
            {
            }
            column(GG_Control97Caption; GG_Control97CaptionLbl)
            {
            }
            column(D_Control100Caption; D_Control100CaptionLbl)
            {
            }
            column(C_Control102Caption; C_Control102CaptionLbl)
            {
            }
            column(DD_Control103Caption; DD_Control103CaptionLbl)
            {
            }
            column(B_Control106Caption; B_Control106CaptionLbl)
            {
            }
            column(A_Control108Caption; A_Control108CaptionLbl)
            {
            }
            column(AA_Control109Caption; AA_Control109CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Counter := Counter + 2;
                if Counter > NoOfLabels + 1 then
                    CurrReport.Break();

                if Counter <> 2 then
                    SectionCounter := SectionCounter + 1;

                if SectionCounter = PageSections then begin
                    PageCounter := PageCounter + 1;
                    SectionCounter := 0;
                end
            end;

            trigger OnPreDataItem()
            begin
                Counter := 0;
                SectionCounter := 0;
                PageSections := 3;
                PageCounter := 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AA; AA)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'A) Deleg. A.E.A.T.';
                        ToolTip = 'Specifies the Spanish tax delegation code.';
                    }
                    field(A; A)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'B) Fiscal Year';
                        ToolTip = 'Specifies the fiscal year for the declaration.';
                    }
                    field(B; B)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'C) Model Layout';
                        ToolTip = 'Specifies 347 as the model layout.';
                    }
                    field(DD; DD)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'D) Summary Sheet ID';
                        ToolTip = 'Specifies the ID of the summary sheet that is associated with the declaration.';
                    }
                    field(C; C)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'E) VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number that is associated with the declaration.';
                    }
                    field(D; D)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'F) Company Name';
                        ToolTip = 'Specifies the name of the company that is making the declaration.';
                    }
                    field(E; E)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G) Contact Name';
                        ToolTip = 'Specifies the name of the contact that is making the declaration.';
                    }
                    field(F; F)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'H) Phone No.';
                        ToolTip = 'Specifies the company telephone number that is associated with the declaration.';
                    }
                    field(G; G)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'I) Total No. of Records';
                        ToolTip = 'Specifies the total number of records on the media.';
                    }
                    field(NoOfLabels; NoOfLabels)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of labels';
                        ToolTip = 'Specifies the number of labels to print.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        if A = '' then
            A := '0000';
        B := '347';
        if C = '' then
            C := CompanyInfo."VAT Registration No.";
        if D = '' then
            D := CompanyInfo.Name;
        if F = '' then
            F := CompanyInfo."Phone No.";
        if NoOfLabels = 0 then
            NoOfLabels := 1;
    end;

    var
        CompanyInfo: Record "Company Information";
        AA: Text[50];
        A: Code[4];
        B: Code[3];
        C: Code[20];
        DD: Text[20];
        D: Text[100];
        E: Text[30];
        F: Text[20];
        G: Integer;
        Counter: Integer;
        NoOfLabels: Integer;
        SectionCounter: Integer;
        PageCounter: Integer;
        PageSections: Integer;
        ACaptionLbl: Label 'B)';
        BCaptionLbl: Label 'C)';
        CCaptionLbl: Label 'E)';
        FCaptionLbl: Label 'H)';
        DCaptionLbl: Label 'F)';
        GCaptionLbl: Label 'I)';
        Counter_1CaptionLbl: Label 'Number in sequence:';
        NoOfLabelsCaptionLbl: Label '/', Locked = true;
        AACaptionLbl: Label 'A)';
        DDCaptionLbl: Label 'D)';
        ECaptionLbl: Label 'G)';
        CounterCaptionLbl: Label 'Number in sequence:';
        NoOfLabels_Control26CaptionLbl: Label '/', Locked = true;
        Counter_1_Control38CaptionLbl: Label 'Number in sequence:';
        NoOfLabels_Control40CaptionLbl: Label '/', Locked = true;
        F_Control72CaptionLbl: Label 'I)';
        E_Control74CaptionLbl: Label 'H)';
        GG_Control75CaptionLbl: Label 'G)';
        D_Control78CaptionLbl: Label 'F)';
        C_Control80CaptionLbl: Label 'E)';
        DD_Control81CaptionLbl: Label 'D)';
        B_Control84CaptionLbl: Label 'C)';
        A_Control86CaptionLbl: Label 'B)';
        AA_Control87CaptionLbl: Label 'A)';
        G_Control94CaptionLbl: Label 'I)';
        E_Control96CaptionLbl: Label 'H)';
        GG_Control97CaptionLbl: Label 'G)';
        D_Control100CaptionLbl: Label 'F)';
        C_Control102CaptionLbl: Label 'E)';
        DD_Control103CaptionLbl: Label 'D)';
        B_Control106CaptionLbl: Label 'C)';
        A_Control108CaptionLbl: Label 'B)';
        AA_Control109CaptionLbl: Label 'A)';
}

