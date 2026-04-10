// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

report 6007 "Insert Fault/Resol. Relations"
{
    ApplicationArea = Service;
    Caption = 'Insert Fault/Resolution Codes Relationships';
    ProcessingOnly = true;
    ShowPrintStatus = false;
    UsageCategory = Tasks;

    dataset
    {
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
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the earliest service order posting date that you want to include in the batch job.';
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'To Date';
                        ToolTip = 'Specifies the last service order posting date that you want to include in the batch job.';
                    }
                    field(BasedOnServItemGr; BasedOnServItemGr)
                    {
                        ApplicationArea = Service;
                        Caption = 'Relation Based on Service Item Group';
                        ToolTip = 'Specifies if you want the batch job to find fault/resolution codes relationships per service item group.';
                    }
                    field(RetainManuallyInserted; RetainManuallyInserted)
                    {
                        ApplicationArea = Service;
                        Caption = 'Retain Manually Inserted Rec.';
                        ToolTip = 'Specifies if you want the batch job to delete existing system inserted records only before it inserts new records.';
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
        RetainManuallyInserted := true;
    end;

    trigger OnPostReport()
    begin
        Clear(CalcFaultResolutionRelation);
        CalcFaultResolutionRelation.CopyResolutionRelationToTable(FromDate, ToDate, BasedOnServItemGr, RetainManuallyInserted);
    end;

    trigger OnPreReport()
    begin
        if FromDate = 0D then
            Error(Text000);
        if ToDate = 0D then
            Error(Text001);
    end;

    var
        CalcFaultResolutionRelation: Codeunit "FaultResolRelation-Calculate";
        FromDate: Date;
        ToDate: Date;
        BasedOnServItemGr: Boolean;
        RetainManuallyInserted: Boolean;

#pragma warning disable AA0074
        Text000: Label 'You must fill in the From Date field.';
        Text001: Label 'You must fill in the To Date field.';
#pragma warning restore AA0074

    procedure InitializeRequest(DateFrom: Date; ToDateFrom: Date; BasedOnServItemGrFrom: Boolean; RetainManuallyInsertedFrom: Boolean)
    begin
        FromDate := DateFrom;
        ToDate := ToDateFrom;
        BasedOnServItemGr := BasedOnServItemGrFrom;
        RetainManuallyInserted := RetainManuallyInsertedFrom;
    end;
}

