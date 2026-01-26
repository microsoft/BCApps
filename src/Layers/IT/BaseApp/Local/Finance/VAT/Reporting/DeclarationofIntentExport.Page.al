// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;

page 12161 "Declaration of Intent Export"
{
    Caption = 'Declaration of Intent Export';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Description Of Goods"; DescriptionOfGoods)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description Of Goods';
                    ToolTip = 'Specifies a description of the transaction.';
                }
                field("Signing Company Officials"; SigningCompanyOfficialsNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Signing Company Officials';
                    TableRelation = "Company Officials";
                    ToolTip = 'Specifies the company official that signs the declaration.';
                }
                field("Amount To Declare"; AmountToDeclare)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount To Declare';
                    MinValue = 0;
                    NotBlank = true;
                    ToolTip = 'Specifies the amount which is being declared through the declaration of intent.';
                }
            }
            group("Plafond Operations")
            {
                Caption = 'Plafond Operations';
                field("Ceiling Type"; CeilingType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ceiling Type';
                    OptionCaption = 'Fixed,Mobile';
                    ToolTip = 'Specifies if the ceiling is fixed or mobile.';
                }
                field("Annual VAT Decl. Submitted"; ExportFlags[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Annual VAT Decl. Submitted';
                    ToolTip = 'Specifies if the annual VAT declaration has been submitted.';
                }
                field(Exports; ExportFlags[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exports';
                    ToolTip = 'Specifies if the declaration includes exports.';
                }
                field("Intra-Community Disposals"; ExportFlags[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Intra-Community Disposals';
                    ToolTip = 'Specifies if the declaration includes disposals to other EU countries.';
                }
                field("Disposals to San Marino"; ExportFlags[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Disposals to San Marino';
                    ToolTip = 'Specifies if the declaration includes disposals to San Marino.';
                }
                field("Assimilated Operations"; ExportFlags[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assimilated Operations';
                    ToolTip = 'Specifies if the declaration includes assimilated operations.';
                }
                field("Extraordinary Operations"; ExportFlags[6])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extraordinary Operations';
                    ToolTip = 'Specifies if the declaration includes extraordinary operations.';
                }
            }
            group(Supplementary)
            {
                Caption = 'Supplementary';
                field("Supplementary Return"; SupplementaryReturn)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Supplementary Return';
                    ToolTip = 'Specifies if the declaration is supplementary.';
                }
                field("Tax Authority Receipts No."; TaxAuthorityReceiptsNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Authority Receipts No.';
                    Editable = SupplementaryReturn;
                    ToolTip = 'Specifies the receipt number that was provided by the tax authority for the original declaration.';
                }
                field("Tax Authority Doc. No."; TaxAuthorityDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Authority Doc. No.';
                    Editable = SupplementaryReturn;
                    ToolTip = 'Specifies the document number that was provided by the tax authority for the original declaration.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ExportFileAndPrintReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export File & Print Report';
                Image = ExportElectronicDocument;
                RunPageOnRec = true;
                ToolTip = 'Generate the declaration and print the report.';

                trigger OnAction()
                var
                    DeclarationOfIntentReport: Report "Declaration of Intent Report";
                    DeclarationOfIntentExport: Codeunit "Declaration of Intent Export";
                begin
                    if DeclarationOfIntentExport.Export(
                         VATExemption, DescriptionOfGoods, SigningCompanyOfficialsNo, AmountToDeclare,
                         CeilingType, ExportFlags, SupplementaryReturn, TaxAuthorityReceiptsNo, TaxAuthorityDocNo)
                    then begin
                        DeclarationOfIntentReport.Initialize(DescriptionOfGoods, SigningCompanyOfficialsNo, AmountToDeclare,
                          CeilingType, ExportFlags, SupplementaryReturn, TaxAuthorityReceiptsNo, TaxAuthorityDocNo);

                        VATExemption.SetRecFilter();
                        DeclarationOfIntentReport.SetTableView(VATExemption);
                        DeclarationOfIntentReport.Run();

                        VATExemption."Declared Operations Up To Amt." += AmountToDeclare;
                        VATExemption.Modify();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ExportFileAndPrintReport_Promoted; ExportFileAndPrintReport)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        ExportFlags[1] := false;
        ExportFlags[2] := false;
        ExportFlags[3] := false;
        ExportFlags[4] := false;
        ExportFlags[5] := false;
        ExportFlags[6] := false;
    end;

    protected var
        VATExemption: Record "VAT Exemption";
        AmountToDeclare: Decimal;
        CeilingType: Option "Fixed",Mobile;
        SigningCompanyOfficialsNo: Code[20];
        ExportFlags: array[6] of Boolean;
        SupplementaryReturn: Boolean;
        DescriptionOfGoods: Text[100];
        TaxAuthorityReceiptsNo: Text[17];
        TaxAuthorityDocNo: Text[6];

    procedure Initialize(var VATExemption2: Record "VAT Exemption")
    begin
        VATExemption := VATExemption2;
        AmountToDeclare := VATExemption.GetSuggestedAmountToDeclare();
    end;
}

