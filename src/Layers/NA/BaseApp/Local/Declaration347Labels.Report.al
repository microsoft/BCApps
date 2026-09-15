// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Foundation.Company;
using System.Utilities;

report 14022 "Declaration 347 Labels"
{
    DefaultLayout = RDLC;
    Caption = 'Declaration 347 Labels';

    dataset
    {
        dataitem(Amount349; "Integer")
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
            column(E; E)
            {
            }
            column(D; D)
            {
            }
            column(F; F)
            {
            }
            column(G; G)
            {
            }
            column(H; H)
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
            column(GG; GG)
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
            column(H_Control68; H)
            {
            }
            column(G_Control70; G)
            {
            }
            column(F_Control72; F)
            {
            }
            column(E_Control74; E)
            {
            }
            column(GG_Control75; GG)
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
            column(H_Control90; H)
            {
            }
            column(G_Control92; G)
            {
            }
            column(F_Control94; F)
            {
            }
            column(E_Control96; E)
            {
            }
            column(GG_Control97; GG)
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
            column(Amount349_Number; Number)
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
            column(ECaption; ECaptionLbl)
            {
            }
            column(DCaption; DCaptionLbl)
            {
            }
            column(FCaption; FCaptionLbl)
            {
            }
            column(GCaption; GCaptionLbl)
            {
            }
            column(HCaption; HCaptionLbl)
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
            column(GGCaption; GGCaptionLbl)
            {
            }
            column(CounterCaption; CounterCaptionLbl)
            {
            }
            column(Counter_1_Control38Caption; Counter_1_Control38CaptionLbl)
            {
            }
            column(H_Control68Caption; H_Control68CaptionLbl)
            {
            }
            column(G_Control70Caption; G_Control70CaptionLbl)
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
            column(H_Control90Caption; H_Control90CaptionLbl)
            {
            }
            column(G_Control92Caption; G_Control92CaptionLbl)
            {
            }
            column(F_Control94Caption; F_Control94CaptionLbl)
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
            end;

            trigger OnPreDataItem()
            begin
                H := StrSubstNo('#1##########', MediaDensity);

                Counter := 0;
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
                        ApplicationArea = BasicMX;
                        Caption = 'A) Deleg. A.E.A.T.';
                        ToolTip = 'Specifies the AEAT (Spanish tax) delegation code.';
                    }
                    field(A; A)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'B) Fiscal Year';
                        ToolTip = 'Specifies the fiscal year for the declaration.';
                    }
                    field(B; B)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'C) Model Layout';
                        ToolTip = 'Specifies the model layout. This must contain 347.';
                    }
                    field(DD; DD)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'D) Reg. Number';
                        ToolTip = 'Specifies the ID of the summary sheet that is associated with the declaration.';
                    }
                    field(C; C)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'E) VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number that is associated with the declaration.';
                    }
                    field(D; D)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'F) Company Name';
                        ToolTip = 'Specifies the name of the company that is making the declaration.';
                    }
                    field(GG; GG)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'G) Address';
                        ToolTip = 'Specifies the address of the company that is making the declaration.';
                    }
                    field(E; E)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'H) Contact';
                        ToolTip = 'Specifies the name of the contact that is making the declaration.';
                    }
                    field(F; F)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'I) Phone No.';
                        ToolTip = 'Specifies the company telephone number that is associated with the declaration.';
                    }
                    field(G; G)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'J) Total No. of Records';
                        ToolTip = 'Specifies the total number of records on the media.';
                    }
                    field(MediaDensity; MediaDensity)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'K) Media Density';
                        ToolTip = 'Specifies the density of the magnetic media.';
                    }
                    field(NoOfLabels; NoOfLabels)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'No. of labels';
                        ToolTip = 'Specifies how many declaration labels to print.';
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
        GG: Text[50];
        G: Integer;
        H: Text[15];
        MediaDensity: Option "360KB","720KB","1.2MB","1.44MB";
        Counter: Integer;
        NoOfLabels: Integer;
        ACaptionLbl: Label 'B)';
        BCaptionLbl: Label 'C)';
        CCaptionLbl: Label 'E)';
        ECaptionLbl: Label 'H)';
        DCaptionLbl: Label 'F)';
        FCaptionLbl: Label 'I)';
        GCaptionLbl: Label 'J)';
        HCaptionLbl: Label 'K)';
        Counter_1CaptionLbl: Label 'Number in sequence:';
        NoOfLabelsCaptionLbl: Label '/', Locked = true;
        AACaptionLbl: Label 'A)';
        DDCaptionLbl: Label 'D)';
        GGCaptionLbl: Label 'G)';
        CounterCaptionLbl: Label 'Number in sequence:';
        Counter_1_Control38CaptionLbl: Label 'Number in sequence:';
        H_Control68CaptionLbl: Label 'K)';
        G_Control70CaptionLbl: Label 'J)';
        F_Control72CaptionLbl: Label 'I)';
        E_Control74CaptionLbl: Label 'H)';
        GG_Control75CaptionLbl: Label 'G)';
        D_Control78CaptionLbl: Label 'F)';
        C_Control80CaptionLbl: Label 'E)';
        DD_Control81CaptionLbl: Label 'D)';
        B_Control84CaptionLbl: Label 'C)';
        A_Control86CaptionLbl: Label 'B)';
        AA_Control87CaptionLbl: Label 'A)';
        H_Control90CaptionLbl: Label 'K)';
        G_Control92CaptionLbl: Label 'J)';
        F_Control94CaptionLbl: Label 'I)';
        E_Control96CaptionLbl: Label 'H)';
        GG_Control97CaptionLbl: Label 'G)';
        D_Control100CaptionLbl: Label 'F)';
        C_Control102CaptionLbl: Label 'E)';
        DD_Control103CaptionLbl: Label 'D)';
        B_Control106CaptionLbl: Label 'C)';
        A_Control108CaptionLbl: Label 'B)';
        AA_Control109CaptionLbl: Label 'A)';
}

