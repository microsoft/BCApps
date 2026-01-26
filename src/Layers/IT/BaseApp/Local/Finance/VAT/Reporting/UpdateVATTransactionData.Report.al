// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;

report 12190 "Update VAT Transaction Data"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/UpdateVATTransactionData.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Update VAT Transaction Data';
    Permissions = TableData "VAT Entry" = rm;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting("Entry No.") where(Type = filter(<> Settlement));
            RequestFilterFields = "Entry No.", "Operation Occurred Date", "Document Type", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Identifier", Type, "Bill-to/Pay-to No.", "Include in VAT Transac. Rep.";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CompareAgainstThreshold; CompareAgainstThreshold)
            {
            }
            column(ShowListOnly; ShowListOnly)
            {
            }
            column(SetIncludeInDataTransmission; SetIncludeInDataTransmission)
            {
            }
            column(VAT_Entry_Base; Base)
            {
            }
            column(VAT_Entry_Amount; Amount)
            {
            }
            column(VAT_Entry__Entry_No__; "Entry No.")
            {
            }
            column(VAT_Entry__Operation_Occurred_Date_; Format("Operation Occurred Date"))
            {
            }
            column(VAT_Entry__Document_No__; "Document No.")
            {
            }
            column(VAT_Entry__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
            {
            }
            column(VAT_Entry__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
            {
            }
            column(VAT_Entry__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(VAT_Entry__Fiscal_Code_; "Fiscal Code")
            {
            }
            column(VAT_Entry__EU_Service_; "EU Service")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Update_VAT_Transaction_DataCaption; Update_VAT_Transaction_DataCaptionLbl)
            {
            }
            column(VAT_Entry__Entry_No__Caption; FieldCaption("Entry No."))
            {
            }
            column(VAT_Entry_BaseCaption; FieldCaption(Base))
            {
            }
            column(VAT_Entry_AmountCaption; FieldCaption(Amount))
            {
            }
            column(VAT_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(VAT_Entry__VAT_Prod__Posting_Group_Caption; FieldCaption("VAT Prod. Posting Group"))
            {
            }
            column(VAT_Entry__VAT_Bus__Posting_Group_Caption; FieldCaption("VAT Bus. Posting Group"))
            {
            }
            column(VAT_Entry__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
            {
            }
            column(VAT_Entry__Fiscal_Code_Caption; FieldCaption("Fiscal Code"))
            {
            }
            column(VAT_Entry__EU_Service_Caption; FieldCaption("EU Service"))
            {
            }
            column(VAT_Entry__Operation_Occurred_Date_Caption; VAT_Entry__Operation_Occurred_Date_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not CheckVATBase(Base, "Operation Occurred Date") then
                    CurrReport.Skip();

                if not ShowListOnly then begin
                    if SetIncludeInDataTransmission = SetIncludeInDataTransmission::"Set Fields" then
                        "Include in VAT Transac. Rep." := true
                    else
                        "Include in VAT Transac. Rep." := false;
                    Modify();
                    if not RecordFound then
                        RecordFound := true;
                end;
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
                    field(CompareAgainstThreshold; CompareAgainstThreshold)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Compare Against Threshold';
                        ToolTip = 'Specifies if you want to compare against the threshold.';
                    }
                    field(ShowListOnly; ShowListOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show List Only';
                        ToolTip = 'Specifies if you want to see show just the list.';
                    }
                    field(SetIncludeInVATTransReport; SetIncludeInDataTransmission)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set Include in VAT Transaction Report';
                        Editable = not ShowListOnly;
                        ToolTip = 'Specifies if you want to set the Include in VAT Transaction Report flag.';
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

    trigger OnPostReport()
    begin
        if (not ShowListOnly) and (not RecordFound) then
            Message(Text001);
    end;

    trigger OnPreReport()
    begin
        RecordFound := false;
        if not ShowListOnly then
            if not Confirm(Text000) then
                Error('');
    end;

    var
        CompareAgainstThreshold: Boolean;
        ShowListOnly: Boolean;
        SetIncludeInDataTransmission: Option "Set Fields"," Clear Fields";
        Text000: Label 'The report will change the value of the Include in VAT Transaction Report fields to Yes for those VAT entries that match the filters that you specified. Do you want to continue?';
        RecordFound: Boolean;
        Text001: Label 'Nothing to modify.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Update_VAT_Transaction_DataCaptionLbl: Label 'Update VAT Transaction Data';
        VAT_Entry__Operation_Occurred_Date_CaptionLbl: Label 'VAT Entry - Operation Occured Date';

    [Scope('OnPrem')]
    procedure CheckVATBase(BaseAmount: Decimal; OperationOccurredDate: Date): Boolean
    var
        DataTransmissionThreshold: Record "VAT Transaction Report Amount";
    begin
        DataTransmissionThreshold.Reset();
        DataTransmissionThreshold.SetFilter("Starting Date", '..%1', OperationOccurredDate);
        if DataTransmissionThreshold.FindLast() then
            if CompareAgainstThreshold then begin
                if Abs(BaseAmount) >= DataTransmissionThreshold."Threshold Amount Excl. VAT" then
                    exit(true);
            end else
                exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewCompareAgainstThreshhold: Boolean; NewShowListOnly: Boolean; NewSetIncludeInDataTransmission: Option "Set Fields"," Clear Fields")
    begin
        CompareAgainstThreshold := NewCompareAgainstThreshhold;
        ShowListOnly := NewShowListOnly;
        SetIncludeInDataTransmission := NewSetIncludeInDataTransmission;
    end;
}

