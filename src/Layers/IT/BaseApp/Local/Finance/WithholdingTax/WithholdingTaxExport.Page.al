// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Foundation.Company;

page 12103 "Withholding Tax Export"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Withholding Tax Export';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    ShowFilter = false;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control1130004)
            {
                ShowCaption = false;
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    MaxValue = 2999;
                    MinValue = 2000;
                    NotBlank = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the withholding tax reporting period.';
                }
                field("Signing Company Officials"; SigningCompanyOfficialsNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Signing Company Officials';
                    ShowMandatory = true;
                    TableRelation = "Company Officials";
                    ToolTip = 'Specifies the signing company officials.';
                }
                field("Prepared by"; PreparedBy)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prepared by';
                    OptionCaption = 'Company,Tax Representative';
                    ToolTip = 'Specifies the person that the export was prepared by.';
                }
                field("Communication Number"; CommunicationNumber)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Communication Number';
                    ToolTip = 'Specifies the communication number.';
                }
                field("Exceptional Event"; ExceptionalEventCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exceptional Event';
                    ToolTip = 'Specifies the exception event to use for this withholding tax export.';
                    TableRelation = "Withholding Exceptional Event".Code;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ExportFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export File';
                Image = ExportElectronicDocument;
                ToolTip = 'Export the withholding tax.';

                trigger OnAction()
                var
                    WithholdingTaxExport: Codeunit "Withholding Tax Export";
                begin
                    WithholdingTaxExport.Export(Year, SigningCompanyOfficialsNo, PreparedBy, CommunicationNumber, ExceptionalEventCode);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ExportFile_Promoted; ExportFile)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Year := Date2DWY(WorkDate(), 3);
    end;

    var
        Year: Integer;
        SigningCompanyOfficialsNo: Code[20];
        PreparedBy: Option Company,"Tax Representative";
        CommunicationNumber: Integer;
        ExceptionalEventCode: Code[10];
}

