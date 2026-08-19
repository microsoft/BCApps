// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Service.Reports;
using Microsoft.Service.Setup;

report 6034 "Remove Lines from Contract"
{
    ApplicationArea = Service;
    Caption = 'Remove Service Contract Lines';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Contract Line"; "Service Contract Line")
        {
            DataItemTableView = sorting("Contract Type", "Contract No.", Credited, "New Line") where("Contract Type" = const(Contract), "Contract Status" = const(Signed), "New Line" = const(false));
            RequestFilterFields = "Contract No.", "Service Item No.";

            trigger OnAfterGetRecord()
            var
                ServiceContractHeader: Record "Service Contract Header";
                FiledServiceContractHeader: Record "Filed Service Contract Header";
            begin
                j := j + 1;
                ProgressDialog.Update(1, Round(j / i * 10000, 1));

                if LastContractNo <> "Contract No." then begin
                    LastContractNo := "Contract No.";
                    ServiceContractHeader.Get("Contract Type", "Contract No.");
                    FiledServiceContractHeader.FileContract(ServiceContractHeader);
                    if ServiceContractHeader."Automatic Credit Memos" and
                       ("Credit Memo Date" > 0D) and
                       CreditMemoBaseExists()
                    then
                        CreditMemoCreated := CreditMemoCreated + 1;
                end;
                SuspendStatusCheck(true);
                Delete(true);

                LinesRemoved := LinesRemoved + 1;
            end;

            trigger OnPreDataItem()
            var
                ExpiredContractLinesTest: Report "Expired Contract Lines - Test";
            begin
                if DeleteLinesOption = DeleteLinesOption::"Print Only" then begin
                    Clear(ExpiredContractLinesTest);
                    ExpiredContractLinesTest.InitVariables(RemoveLinesToDate, ReasonCodeRec.Code);
                    ExpiredContractLinesTest.SetTableView("Service Contract Line");
                    ExpiredContractLinesTest.RunModal();
                    CurrReport.Break();
                end;

                if RemoveLinesToDate = 0D then
                    Error(RemoveLinesToDateNotDefinedErr);
                ServiceMgtSetup.Get();
                if ServiceMgtSetup."Use Contract Cancel Reason" then
                    if ReasonCodeRec.Code = '' then
                        Error(ReasonCodeNotDefinedErr);
                SetFilter("Contract Expiration Date", '<>%1&<=%2', 0D, RemoveLinesToDate);

                ProgressDialog.Open(
                  Text004 +
                  '@1@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                i := Count;
                j := 0;
                LinesRemoved := 0;
                LastContractNo := '';
                CreditMemoCreated := 0;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DelToDate; RemoveLinesToDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Remove Lines to';
                        ToolTip = 'Specifies the date up to which you want to remove contract lines. The batch job includes contract lines with contract expiration dates on or before this date.';
                    }
                    field(ReasonCode; ReasonCodeRec.Code)
                    {
                        ApplicationArea = Service;
                        Caption = 'Reason Code';
                        ToolTip = 'Specifies the reason code for the removal of lines from the contract. To see the existing reason codes, choose the Filter field.';
                        TableRelation = "Reason Code".Code;

                        trigger OnValidate()
                        begin
                            ReasonCodeRec.Get(ReasonCodeRec.Code);
                        end;
                    }
                    field("Reason Code"; ReasonCodeRec.Description)
                    {
                        ApplicationArea = Service;
                        Caption = 'Reason Code Description';
                        Editable = false;
                        ToolTip = 'Specifies a description of the Reason Code.';
                    }
                    field(DeleteLines; DeleteLinesOption)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Delete Lines,Print Only';
                        ToolTip = 'Specifies the desired action relating to removing expired contract lines from service contracts.';
                    }
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        RemoveLinesToDate := WorkDate();
        ServiceMgtSetup.Get();
    end;

    trigger OnPostReport()
    begin
        if DeleteLinesOption = DeleteLinesOption::"Delete Lines" then
            if LinesRemoved > 1 then
                Message(Text000, LinesRemoved)
            else
                Message(Text001, LinesRemoved);

        if CreditMemoCreated = 1 then
            Message(Text006);

        if CreditMemoCreated > 1 then
            Message(Text007);
        CreateCreditfromContractLines.InitVariables();
    end;

    trigger OnPreReport()
    begin
        CreateCreditfromContractLines.InitVariables();
    end;

    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ReasonCodeRec: Record "Reason Code";
        CreateCreditfromContractLines: Codeunit CreateCreditfromContractLines;
        RemoveLinesToDate: Date;
        DeleteLinesOption: Option "Delete Lines","Print Only";
        ProgressDialog: Dialog;
        i: Integer;
        j: Integer;
        LinesRemoved: Integer;
        LastContractNo: Code[20];
        CreditMemoCreated: Integer;
        RemoveLinesToDateNotDefinedErr: Label 'You must fill in the Remove Lines to field.';
        ReasonCodeNotDefinedErr: Label 'You must fill in the Reason Code field.';
#pragma warning disable AA0074
        Text006: Label 'A credit memo was created/updated.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'Credit memos were created/updated.';
#pragma warning disable AA0470
        Text000: Label '%1 contract lines were removed.';
        Text001: Label '%1 contract line was removed.';
#pragma warning restore AA0470
        Text004: Label 'Removing contract lines... \\';
#pragma warning restore AA0074
}

