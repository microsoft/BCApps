// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6087 "Filed Serv. Contract Cm. Sheet"
{
    Caption = 'Filed Service Contract Comment Sheet';
    Editable = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Filed Serv. Contract Cmt. Line";

    layout
    {
        area(content)
        {
            repeater(Comments)
            {
                ShowCaption = false;
                field(Date; Rec."Comment Date")
                {
                    ApplicationArea = Service;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := Caption() + CaptionString;
    end;

    trigger OnOpenPage()
    begin
        CaptionString := CurrPage.Caption;
    end;

    var
        CaptionString: Text;

    procedure Caption(): Text
    var
        FiledServContractCmtLine: Record "Filed Serv. Contract Cmt. Line";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        FiledContractLine: Record "Filed Contract Line";
    begin
        if Rec.GetFilter("Entry No.") <> '' then
            Evaluate(FiledServContractCmtLine."Entry No.", Rec.GetFilter("Entry No."));

        if Rec.GetFilter("Table Name") <> '' then
            Evaluate(FiledServContractCmtLine."Table Name", Rec.GetFilter("Table Name"));

        if Rec.GetFilter("Table Subtype") <> '' then
            Evaluate(FiledServContractCmtLine."Table Subtype", Rec.GetFilter("Table Subtype"));

        if Rec.GetFilter("No.") <> '' then
            Evaluate(FiledServContractCmtLine."No.", Rec.GetFilter("No."));

        if Rec.GetFilter(Type) <> '' then
            Evaluate(FiledServContractCmtLine.Type, Rec.GetFilter(Type));

        if Rec.GetFilter("Table Line No.") <> '' then
            Evaluate(FiledServContractCmtLine."Table Line No.", Rec.GetFilter("Table Line No."));

        if (FiledServContractCmtLine."Table Name" <> FiledServContractCmtLine."Table Name"::"Service Contract") or (FiledServContractCmtLine."Entry No." = 0) then
            exit('');

        case Rec."Table Line No." of
            0:
                begin
                    FiledServiceContractHeader.SetLoadFields("Contract Type", "Contract No.", Description);
                    if FiledServiceContractHeader.Get(Rec."Entry No.") then
                        exit(
                          StrSubstNo('%1 %2 %3 - %4 ', FiledServiceContractHeader."Contract Type", FiledServiceContractHeader."Contract No.", FiledServiceContractHeader.Description, FiledServContractCmtLine.Type));
                end;
            else begin
                FiledContractLine.SetLoadFields("Contract Type", "Contract No.", Description);
                if FiledContractLine.Get(Rec."Entry No.", Rec."Table Line No.") then
                    exit(
                      StrSubstNo('%1 %2 %3 - %4 ', FiledContractLine."Contract Type", FiledContractLine."Contract No.", FiledContractLine.Description, FiledServContractCmtLine.Type));
            end;
        end;
    end;
}