// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Setup;
using System.Text;
using System.Utilities;

page 6010 "Res.Gr. Availability (Service)"
{
    Caption = 'Res.Gr. Availability (Service)';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Resource Group";

    layout
    {
        area(content)
        {
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        DateControl();
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        DateControl();
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                        DateFilterOnAfterValidate();
                    end;
                }
                field(ColumnsSet; ColumnsSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Res. Gr. Avail. (Serv.) Matrix";
                begin
                    MatrixForm.SetData(
                      CurrentDocumentType, CurrentDocumentNo, CurrentEntryNo,
                      MatrixColumnCaptions, MatrixRecords, PeriodType);
                    MatrixForm.SetTableView(Rec);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Next);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ServMgtSetup.Get();
        SetMatrixColumns("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        ResRec2: Record Resource;
        ServMgtSetup: Record "Service Mgt. Setup";
        FilterTokens: Codeunit "Filter Tokens";
        CurrentDocumentType: Integer;
        CurrentDocumentNo: Code[20];
        CurrentEntryNo: Integer;
        PeriodType: Enum "Analysis Period Type";
        DateFilter: Text;
        PKFirstRecInCurrSet: Text[1024];
        MatrixColumnCaptions: array[32] of Text[100];
        ColumnsSet: Text[1024];
        CurrSetLength: Integer;

    procedure SetData(DocumentType: Integer; DocumentNo: Code[20]; EntryNo: Integer)
    begin
        CurrentDocumentType := DocumentType;
        CurrentDocumentNo := DocumentNo;
        CurrentEntryNo := EntryNo;
    end;

    local procedure DateControl()
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        ResRec2.SetFilter("Date Filter", DateFilter);
        DateFilter := ResRec2.GetFilter("Date Filter");
    end;

    procedure SetMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), 32, false, PeriodType, DateFilter,
            PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnsSet, CurrSetLength, MatrixRecords);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

