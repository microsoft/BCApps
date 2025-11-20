// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Comment;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;

page 5911 "Service Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Service Comment Sheet';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Service Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you entered the service comment.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the service comment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := Caption() + CaptionString;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    trigger OnOpenPage()
    begin
        CaptionString := CurrPage.Caption;
    end;

    var
        CaptionString: Text;

    procedure Caption(): Text
    var
        ServiceCommentLine: Record "Service Comment Line";
        ServiceHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItem: Record "Service Item";
        Loaner: Record Loaner;
    begin
        if Rec.GetFilter("Table Name") <> '' then
            Evaluate(ServiceCommentLine."Table Name", Rec.GetFilter("Table Name"));

        if Rec.GetFilter("Table Subtype") <> '' then
            Evaluate(ServiceCommentLine."Table Subtype", Rec.GetFilter("Table Subtype"));

        if Rec.GetFilter("No.") <> '' then
            Evaluate(ServiceCommentLine."No.", Rec.GetFilter("No."));

        if Rec.GetFilter(Type) <> '' then
            Evaluate(ServiceCommentLine.Type, Rec.GetFilter(Type));

        if Rec.GetFilter("Table Line No.") <> '' then
            Evaluate(ServiceCommentLine."Table Line No.", Rec.GetFilter("Table Line No."));

        if ServiceCommentLine."Table Line No." > 0 then
            if ServItemLine.Get(ServiceCommentLine."Table Subtype", ServiceCommentLine."No.", ServiceCommentLine."Table Line No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServItemLine."Document Type", ServItemLine."Document No.",
                    ServItemLine.Description, ServiceCommentLine.Type));

        if ServiceCommentLine."Table Name" = ServiceCommentLine."Table Name"::"Service Header" then
            if ServiceHeader.Get(ServiceCommentLine."Table Subtype", ServiceCommentLine."No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServiceHeader."Document Type", ServiceHeader."No.",
                    ServiceHeader.Description, ServiceCommentLine.Type));

        if ServiceCommentLine."Table Name" = ServiceCommentLine."Table Name"::"Service Contract" then
            if ServiceContractLine.Get(ServiceCommentLine."Table Subtype",
                 ServiceCommentLine."No.", ServiceCommentLine."Table Line No.")
            then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServiceContractLine."Contract Type", ServiceContractLine."Contract No.",
                    ServiceContractLine.Description, ServiceCommentLine.Type));

        if ServiceCommentLine."Table Name" = ServiceCommentLine."Table Name"::"Service Contract" then
            if ServiceContractHeader.Get(ServiceCommentLine."Table Subtype", ServiceCommentLine."No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServiceContractHeader."Contract Type",
                    ServiceContractHeader."Contract No.", ServiceContractHeader.Description, ServiceCommentLine.Type));

        if ServiceCommentLine."Table Name" = ServiceCommentLine."Table Name"::"Service Item" then
            if ServiceItem.Get(ServiceCommentLine."No.") then
                exit(StrSubstNo('%1 %2 - %3 ', ServiceItem."No.", ServiceItem.Description, ServiceCommentLine.Type));

        if ServiceCommentLine."Table Name" = ServiceCommentLine."Table Name"::Loaner then
            if Loaner.Get(ServiceCommentLine."No.") then
                exit(StrSubstNo('%1 %2 - %3 ', Loaner."No.", Loaner.Description, ServiceCommentLine.Type));
    end;
}

