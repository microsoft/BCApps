// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.Contract;
using System.Utilities;

report 5979 "Copy Service Document"
{
    Caption = 'Copy Service Document';
    ProcessingOnly = true;

    dataset
    {
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
                    field(DocType; FromContractType)
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Type';
                        ToolTip = 'Specifies the type of service contract that you want to copy.';

                        trigger OnValidate()
                        begin
                            FromContractNo := '';
                            ValidateContractNo();
                        end;
                    }
                    field(DocNo; FromContractNo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract No.';
                        ToolTip = 'Specifies the contract number that you want to copy from by choosing the field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupContractNo();
                        end;

                        trigger OnValidate()
                        begin
                            ValidateContractNo();
                        end;
                    }
                    field("FromServContractHeader.CustomerNo"; FromServContractHeader."Customer No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Customer No.';
                        Editable = false;
                        ToolTip = 'Specifies the number of the customer.';
                    }
                    field("FromServContractHeader.Name"; FromServContractHeader.Name)
                    {
                        ApplicationArea = Service;
                        Caption = 'Customer Name';
                        Editable = false;
                        ToolTip = 'Specifies the customer name from a document that you have selected to copy the information from.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FromContractNo <> '' then begin
                case FromContractType of
                    FromContractType::Quote:
                        if FromServContractHeader.Get(FromServContractHeader."Contract Type"::Quote, FromContractNo) then;
                    FromContractType::Contract:
                        if FromServContractHeader.Get(FromServContractHeader."Contract Type"::Contract, FromContractNo) then;
                end;
                if FromServContractHeader."Contract No." = '' then
                    FromContractNo := ''
                else
                    FromServContractHeader.CalcFields(Name);
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Commit();
        if not AllLinesCopied then
            if ConfirmManagement.GetResponse(ShowNotCopiedLinesQst, true) then begin
                OutServContractLine.MarkedOnly := true;
                PAGE.RunModal(PAGE::"Service Contract Line List", OutServContractLine);
            end;
    end;

    trigger OnPreReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if FromContractNo = '' then
            Error(MissingContractNoErr);
        ValidateContractNo();
        if FromServContractHeader."Ship-to Code" <> ServContractHeader."Ship-to Code" then
            if not ConfirmManagement.GetResponseOrDefault(ChangeShipToCodeQst, true) then
                CurrReport.Quit();
        AllLinesCopied := CopyServiceContractMgt.CopyServiceContractLines(ServContractHeader, FromContractType, FromContractNo, OutServContractLine);
    end;

    var
        OutServContractLine: Record "Service Contract Line";
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
        FromContractType: Enum "Service Contract Type From";
        AllLinesCopied: Boolean;

        ShowNotCopiedLinesQst: Label 'It was not possible to copy all of the service contract lines.\\Do you want to see these lines?';
        SameFieldValueErr: Label 'You can only copy the document with the same %1.', Comment = '%1 - field caption';
        ChangeShipToCodeQst: Label 'The document has a different ship-to code.\\Do you want to continue?';
        MissingContractNoErr: Label 'You must fill in the Contract No. field.';

    protected var
        ServContractHeader: Record "Service Contract Header";
        FromServContractHeader: Record "Service Contract Header";
        FromContractNo: Code[20];

    procedure SetServContractHeader(var NewServContractHeader: Record "Service Contract Header")
    begin
        ServContractHeader := NewServContractHeader;
    end;

    local procedure ValidateContractNo()
    begin
        if FromContractNo = '' then
            FromServContractHeader.Init()
        else begin
            FromServContractHeader.Init();
            FromServContractHeader.Get(FromContractType, FromContractNo);
            if FromServContractHeader."Customer No." <> ServContractHeader."Customer No." then
                Error(SameFieldValueErr, ServContractHeader.FieldCaption("Customer No."));
            if FromServContractHeader."Currency Code" <> ServContractHeader."Currency Code" then
                Error(SameFieldValueErr, ServContractHeader.FieldCaption("Currency Code"));
            FromServContractHeader.CalcFields(Name);
        end;
    end;

    local procedure LookupContractNo()
    var
        ContractType: Enum "Service Contract Type";
    begin
        ContractType := CopyServiceContractMgt.GetServiceContractType(FromContractType);

        FromServContractHeader.FilterGroup := 2;
        FromServContractHeader.SetRange("Contract Type", ContractType);
        if ServContractHeader."Contract Type" = ContractType then
            FromServContractHeader.SetFilter("Contract No.", '<>%1', ServContractHeader."Contract No.");
        FromServContractHeader."Contract Type" := ContractType;
        FromServContractHeader."Contract No." := FromContractNo;
        FromServContractHeader.SetCurrentKey("Customer No.", "Currency Code", "Ship-to Code");
        FromServContractHeader.SetRange("Customer No.", ServContractHeader."Customer No.");
        FromServContractHeader.SetRange("Currency Code", ServContractHeader."Currency Code");
        FromServContractHeader.FilterGroup := 0;
        FromServContractHeader.SetRange("Ship-to Code", ServContractHeader."Ship-to Code");
        if PAGE.RunModal(0, FromServContractHeader) = ACTION::LookupOK then
            FromContractNo := FromServContractHeader."Contract No.";
        ValidateContractNo();
    end;

    procedure SetParameters(ContractType: Enum "Service Contract Type From"; ContractNo: Code[20])
    begin
        FromContractType := ContractType;
        FromContractNo := ContractNo;
    end;

}
