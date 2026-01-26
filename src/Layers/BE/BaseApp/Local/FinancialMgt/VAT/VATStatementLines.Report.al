// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

report 11310 "VAT Statement Lines"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/VATStatementLines.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement Report';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Line"; "VAT Statement Line")
        {
            DataItemTableView = sorting("Statement Template Name", "Statement Name", "Line No.");
            RequestFilterFields = "Statement Template Name";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(StmtTempName_VATStmtLine; "Statement Template Name")
            {
            }
            column(RowNo_VATStmtLine; "Row No.")
            {
            }
            column(Desc_VATStmtLine; Description)
            {
            }
            column(GenPostingType_VATStmtLine; "Gen. Posting Type")
            {
            }
            column(AmtType_VATStmtLine; "Amount Type")
            {
            }
            column(Calculatewith_VATStmtLine; "Calculate with")
            {
                OptionMembers = "+","-";
            }
            column(DocType_VATStmtLine; "Document Type")
            {
            }
            column(VATBusPostingGroup_VATStmtLine; "VAT Bus. Posting Group")
            {
            }
            column(VATProdPostingGroup_VATStmtLine; "VAT Prod. Posting Group")
            {
            }
            column(Printwith_VATStmtLine; "Print with")
            {
                OptionMembers = "+","-";
            }
            column(vTotal1; vTotal[1])
            {
            }
            column(Type_VATStmtLine; Type)
            {
            }
            column(Print; "VAT Statement Line".Print)
            {
            }
            column(PrintWith2; PrintWith2)
            {
            }
            column(CalculateWith2; CalculateWith2)
            {
            }
            column(vTotal2; vTotal[2])
            {
            }
            column(VATStmtLineCaption; VAT_Statement_LineCaptionLbl)
            {
            }
            column(PageNoCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(RowNoCaption_VATStmtLine; FieldCaption("Row No."))
            {
            }
            column(DescriptionCaption_VATStmtLine; FieldCaption(Description))
            {
            }
            column(GenPostingTypeCaption_VATStmtLine; FieldCaption("Gen. Posting Type"))
            {
            }
            column(VATBusPostingGroupCaption_VATStmtLine; FieldCaption("VAT Bus. Posting Group"))
            {
            }
            column(VATProdPostingGroupCaption_VATStmtLine; FieldCaption("VAT Prod. Posting Group"))
            {
            }
            column(AmtTypeCaption_VATStmtLine; FieldCaption("Amount Type"))
            {
            }
            column(V1Caption; V1_CaptionLbl)
            {
            }
            column(DocCaption; Doc_CaptionLbl)
            {
            }
            column(V2Caption; V2_CaptionLbl)
            {
            }
            column(vTotal1Caption; vTotal_1_CaptionLbl)
            {
            }
            column(TypeCaption_VATStmtLine; FieldCaption(Type))
            {
            }
            column(StmtTempNameCaption_VATStmtLine; FieldCaption("Statement Template Name"))
            {
            }
            column(V1CalculatewithCaption; V1__Calculate_withCaptionLbl)
            {
            }
            column(V2PrintwithCaption; V2__Print_withCaptionLbl)
            {
            }
            column(StmtName_VATStmtLine; "Statement Name")
            {
            }
            column(LineNo_VATStmtLine; "Line No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalculateWith2 := "Calculate with";
                PrintWith2 := "Print with";
                Pos := 0;
                vTotaling := CopyStr("VAT Statement Line"."Row Totaling", 26);
                if vTotaling <> '' then begin
                    Pos := 25 + StrPos(vTotaling, '|');
                    vTotal[1] := CopyStr("VAT Statement Line"."Row Totaling", 1, Pos);
                    vTotal[2] := CopyStr("VAT Statement Line"."Row Totaling", Pos + 1);
                end else begin
                    vTotal[1] := "VAT Statement Line"."Row Totaling";
                    vTotal[2] := '';
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        vTotaling: Text[30];
        vTotal: array[2] of Text[30];
        Pos: Integer;
        PrintWith2: Integer;
        CalculateWith2: Integer;
        VAT_Statement_LineCaptionLbl: Label 'VAT Statement Line';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        V1_CaptionLbl: Label '(1)';
        Doc_CaptionLbl: Label 'Doc.';
        V2_CaptionLbl: Label '(2)';
        vTotal_1_CaptionLbl: Label 'Totaling';
        V1__Calculate_withCaptionLbl: Label '(1) Calculate with';
        V2__Print_withCaptionLbl: Label '(2) Print with';
}

