// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Foundation.Company;
using System.Utilities;

report 14023 "Declaration 349 Labels"
{
    DefaultLayout = RDLC;
    Caption = 'Declaration 349 Labels';

    dataset
    {
        dataitem("Integer"; "Integer")
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
            column(D; D)
            {
            }
            column(E; E)
            {
            }
            column(B1; B1)
            {
            }
            column(F; F)
            {
            }
            column(G; G)
            {
            }
            column(G1; G1)
            {
            }
            column(G2; G2)
            {
            }
            column(H; H)
            {
            }
            column(I; I)
            {
            }
            column(J; J)
            {
            }
            column(K; K)
            {
            }
            column(Counter_1; Counter - 1)
            {
            }
            column(NoOfLabels; NoOfLabels)
            {
            }
            column(L; L)
            {
            }
            column(M; M)
            {
            }
            column(A_Control1; A)
            {
            }
            column(B_Control6; B)
            {
            }
            column(C_Control8; C)
            {
            }
            column(D_Control10; D)
            {
            }
            column(E_Control12; E)
            {
            }
            column(F_Control14; F)
            {
            }
            column(G_Control16; G)
            {
            }
            column(G1_Control18; G1)
            {
            }
            column(G2_Control20; G2)
            {
            }
            column(H_Control22; H)
            {
            }
            column(I_Control24; I)
            {
            }
            column(J_Control26; J)
            {
            }
            column(K_Control28; K)
            {
            }
            column(B1_Control34; B1)
            {
            }
            column(Counter; Counter)
            {
            }
            column(NoOfLabels_Control5; NoOfLabels)
            {
            }
            column(A_Control31; A)
            {
            }
            column(B_Control32; B)
            {
            }
            column(C_Control33; C)
            {
            }
            column(D_Control37; D)
            {
            }
            column(E_Control39; E)
            {
            }
            column(B1_Control42; B1)
            {
            }
            column(F_Control43; F)
            {
            }
            column(G_Control45; G)
            {
            }
            column(G1_Control47; G1)
            {
            }
            column(G2_Control48; G2)
            {
            }
            column(H_Control49; H)
            {
            }
            column(I_Control51; I)
            {
            }
            column(J_Control53; J)
            {
            }
            column(K_Control55; K)
            {
            }
            column(Counter_1_Control57; Counter - 1)
            {
            }
            column(NoOfLabels_Control59; NoOfLabels)
            {
            }
            column(M_Control96; M)
            {
            }
            column(L_Control97; L)
            {
            }
            column(M_Control105; M)
            {
            }
            column(L_Control106; L)
            {
            }
            column(Integer_Number; Number)
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
            column(DCaption; DCaptionLbl)
            {
            }
            column(ECaption; ECaptionLbl)
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
            column(ICaption; ICaptionLbl)
            {
            }
            column(JCaption; JCaptionLbl)
            {
            }
            column(KCaption; KCaptionLbl)
            {
            }
            column(Counter_1Caption; Counter_1CaptionLbl)
            {
            }
            column(NoOfLabelsCaption; NoOfLabelsCaptionLbl)
            {
            }
            column(M_Caption; M_CaptionLbl)
            {
            }
            column(L_Caption; L_CaptionLbl)
            {
            }
            column(A_Control1Caption; A_Control1CaptionLbl)
            {
            }
            column(B_Control6Caption; B_Control6CaptionLbl)
            {
            }
            column(C_Control8Caption; C_Control8CaptionLbl)
            {
            }
            column(D_Control10Caption; D_Control10CaptionLbl)
            {
            }
            column(E_Control12Caption; E_Control12CaptionLbl)
            {
            }
            column(F_Control14Caption; F_Control14CaptionLbl)
            {
            }
            column(G_Control16Caption; G_Control16CaptionLbl)
            {
            }
            column(H_Control22Caption; H_Control22CaptionLbl)
            {
            }
            column(I_Control24Caption; I_Control24CaptionLbl)
            {
            }
            column(J_Control26Caption; J_Control26CaptionLbl)
            {
            }
            column(K_Control28Caption; K_Control28CaptionLbl)
            {
            }
            column(CounterCaption; CounterCaptionLbl)
            {
            }
            column(A_Control31Caption; A_Control31CaptionLbl)
            {
            }
            column(B_Control32Caption; B_Control32CaptionLbl)
            {
            }
            column(C_Control33Caption; C_Control33CaptionLbl)
            {
            }
            column(D_Control37Caption; D_Control37CaptionLbl)
            {
            }
            column(E_Control39Caption; E_Control39CaptionLbl)
            {
            }
            column(F_Control43Caption; F_Control43CaptionLbl)
            {
            }
            column(G_Control45Caption; G_Control45CaptionLbl)
            {
            }
            column(H_Control49Caption; H_Control49CaptionLbl)
            {
            }
            column(I_Control51Caption; I_Control51CaptionLbl)
            {
            }
            column(J_Control53Caption; J_Control53CaptionLbl)
            {
            }
            column(K_Control55Caption; K_Control55CaptionLbl)
            {
            }
            column(Counter_1_Control57Caption; Counter_1_Control57CaptionLbl)
            {
            }
            column(M_Control96Caption; M_Control96CaptionLbl)
            {
            }
            column(L_Control97Caption; L_Control97CaptionLbl)
            {
            }
            column(M_Caption_Control103; M_Caption_Control103Lbl)
            {
            }
            column(L_Caption_Control104; L_Caption_Control104Lbl)
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
                K := StrSubstNo('#1##########', MediaDensity);

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
                    field(A; A)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'A) AEAT Delegation';
                        ToolTip = 'Specifies the AEAT (Spanish tax) delegation code.';
                    }
                    group("B)")
                    {
                        Caption = 'B)';
                        field(B; B)
                        {
                            ApplicationArea = BasicMX;
                            Caption = 'Fiscal Year';
                            ToolTip = 'Specifies the fiscal year for the declaration.';
                        }
                        field(B1; B1)
                        {
                            ApplicationArea = BasicMX;
                            Caption = 'Period';
                            ToolTip = 'Specifies the period for the declaration.';
                        }
                    }
                    field(C; C)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'C) Model Layout';
                        ToolTip = 'Specifies the model layout. This must contain 349.';
                    }
                    field(D; D)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'D) No. of Just. 1st Page';
                        ToolTip = 'Specifies the control number for the first summary page of the declaration.';
                    }
                    field(E; E)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'E) VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number that is associated with the declaration.';
                    }
                    field(F; F)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'F) Company Name';
                        ToolTip = 'Specifies the name of the company that is making the declaration.';
                    }
                    group("G)")
                    {
                        Caption = 'G)';
                        field(G; G)
                        {
                            ApplicationArea = BasicMX;
                            Caption = 'Address';
                            ToolTip = 'Specifies the address of the company that is making the declaration.';
                        }
                        field(G2; G2)
                        {
                            ApplicationArea = BasicMX;
                            Caption = 'Post Code';
                            ToolTip = 'Specifies the post code of the company that is making the declaration.';
                        }
                        field(G1; G1)
                        {
                            ApplicationArea = BasicMX;
                            Caption = 'City';
                            ToolTip = 'Specifies the city of the company that is making the declaration.';
                        }
                    }
                    field(H; H)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'H) Contact';
                        ToolTip = 'Specifies the name of the contact that is making the declaration.';
                    }
                    field(I; I)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'I) Phone No.';
                        ToolTip = 'Specifies the company telephone number that is associated with the declaration.';
                    }
                    field(J; J)
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
                    field(L; L)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'L) Total No. of pasive declarants declared';
                        ToolTip = 'Specifies the total number of passive subjects that are associated with the declaration.';
                    }
                    field(M; M)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'M) Total No. of related people on companies';
                        ToolTip = 'Specifies the total number of related persons and entities that are associated with the declaration.';
                    }
                    field(NoOfLabels; NoOfLabels)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'No. of Labels';
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
        C := '349';
        if E = '' then
            E := CompanyInfo."VAT Registration No.";
        if F = '' then
            F := CompanyInfo.Name;
        if G = '' then
            G := CompanyInfo.Address;
        if G1 = '' then
            G1 := CompanyInfo.City;
        if G2 = '' then
            G2 := CompanyInfo."Post Code";
        if I = '' then
            I := CompanyInfo."Phone No.";
        if K = '' then
            K := '720KB';
        if NoOfLabels = 0 then
            NoOfLabels := 1;
    end;

    var
        CompanyInfo: Record "Company Information";
        A: Code[4];
        B: Code[2];
        B1: Code[2];
        C: Code[3];
        D: Text[15];
        E: Text[15];
        F: Text[100];
        G: Text[100];
        G1: Text[30];
        G2: Text[20];
        H: Text[40];
        I: Text[20];
        J: Integer;
        K: Text[15];
        L: Integer;
        M: Integer;
        MediaDensity: Option "360KB","720KB","1.2MB","1.44MB";
        NoOfLabels: Integer;
        Counter: Integer;
        ACaptionLbl: Label 'A)';
        BCaptionLbl: Label 'B)';
        CCaptionLbl: Label 'C)';
        DCaptionLbl: Label 'D)';
        ECaptionLbl: Label 'E)';
        FCaptionLbl: Label 'F)';
        GCaptionLbl: Label 'G)';
        HCaptionLbl: Label 'H)';
        ICaptionLbl: Label 'I)';
        JCaptionLbl: Label 'J)';
        KCaptionLbl: Label 'K)';
        Counter_1CaptionLbl: Label 'Number in sequence';
        NoOfLabelsCaptionLbl: Label '/', Locked = true;
        M_CaptionLbl: Label 'M)';
        L_CaptionLbl: Label 'L)';
        A_Control1CaptionLbl: Label 'A)';
        B_Control6CaptionLbl: Label 'B)';
        C_Control8CaptionLbl: Label 'C)';
        D_Control10CaptionLbl: Label 'D)';
        E_Control12CaptionLbl: Label 'E)';
        F_Control14CaptionLbl: Label 'F)';
        G_Control16CaptionLbl: Label 'G)';
        H_Control22CaptionLbl: Label 'H)';
        I_Control24CaptionLbl: Label 'I)';
        J_Control26CaptionLbl: Label 'J)';
        K_Control28CaptionLbl: Label 'K)';
        CounterCaptionLbl: Label 'Number in sequence';
        A_Control31CaptionLbl: Label 'A)';
        B_Control32CaptionLbl: Label 'B)';
        C_Control33CaptionLbl: Label 'C)';
        D_Control37CaptionLbl: Label 'D)';
        E_Control39CaptionLbl: Label 'E)';
        F_Control43CaptionLbl: Label 'F)';
        G_Control45CaptionLbl: Label 'G)';
        H_Control49CaptionLbl: Label 'H)';
        I_Control51CaptionLbl: Label 'I)';
        J_Control53CaptionLbl: Label 'J)';
        K_Control55CaptionLbl: Label 'K)';
        Counter_1_Control57CaptionLbl: Label 'Number in sequence';
        M_Control96CaptionLbl: Label 'M)';
        L_Control97CaptionLbl: Label 'L)';
        M_Caption_Control103Lbl: Label 'M)';
        L_Caption_Control104Lbl: Label 'L)';
}

