// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.BatchProcessing;
using System.Utilities;

codeunit 7092 "Expense Report Batch Post Mgt."
{
    Access = Internal;
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    TableNo = "Expense Report Header";

    trigger OnRun()
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        ExpenseReportHeader.Copy(Rec);
        Code(ExpenseReportHeader);
        Rec := ExpenseReportHeader;
    end;

    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingCodeunitId: Integer;
        BatchPostingMsg: Label 'Batch posting of expense reports.';

    /// <summary>
    /// Runs batch posting of expense reports with a confirmation dialog and error handling UI.
    /// </summary>
    /// <param name="ExpenseReportHeader">Specifies the expense report records to be batch posted.</param>
    /// <param name="TotalCount">Specifies the total number of expense reports selected for batch posting.</param>
    /// <param name="Question">Specifies the confirmation question to display to the user.</param>
    procedure RunWithUI(var ExpenseReportHeader: Record "Expense Report Header"; TotalCount: Integer; Question: Text)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ExpenseReportBatchPostMgt: Codeunit "Expense Report Batch Post Mgt.";
    begin
        if not Confirm(StrSubstNo(Question, ExpenseReportHeader.Count, TotalCount), true) then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, Database::"Expense Report Header", 0, BatchPostingMsg);
        ExpenseReportBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if ExpenseReportBatchPostMgt.Run(ExpenseReportHeader) then;
        BatchProcessingMgt.ResetBatchID();

        if ErrorMessageMgt.GetLastErrorID() > 0 then
            ErrorMessageHandler.ShowErrors();
    end;

    /// <summary>
    /// Gets the batch processing management codeunit instance used for batch posting.
    /// </summary>
    /// <param name="ResultBatchProcessingMgt">Returns the batch processing management codeunit instance.</param>
    procedure GetBatchProcessor(var ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        ResultBatchProcessingMgt := BatchProcessingMgt;
    end;

    /// <summary>
    /// Sets the batch processing management codeunit instance to be used for batch posting.
    /// </summary>
    /// <param name="NewBatchProcessingMgt">Specifies the batch processing management codeunit instance to set.</param>
    procedure SetBatchProcessor(NewBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        BatchProcessingMgt := NewBatchProcessingMgt;
    end;

    /// <summary>
    /// Sets the posting codeunit ID to use when posting each expense report.
    /// </summary>
    /// <param name="NewPostingCodeunitId">Specifies the posting codeunit ID.</param>
    procedure SetPostingCodeunitId(NewPostingCodeunitId: Integer)
    begin
        PostingCodeunitId := NewPostingCodeunitId;
    end;

    /// <summary>
    /// Executes the batch posting of expense reports using the configured batch processor.
    /// </summary>
    /// <param name="ExpenseReportHeader">Specifies the expense report records to be batch posted.</param>
    procedure "Code"(var ExpenseReportHeader: Record "Expense Report Header")
    var
        RecRef: RecordRef;
    begin
        if PostingCodeunitId = 0 then
            PostingCodeunitId := Codeunit::"Expense Report-Post";

        RecRef.GetTable(ExpenseReportHeader);

        BatchProcessingMgt.SetProcessingCodeunit(PostingCodeunitId);
        BatchProcessingMgt.BatchProcess(RecRef);

        RecRef.SetTable(ExpenseReportHeader);
    end;
}