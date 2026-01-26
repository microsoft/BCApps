// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Archive;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

codeunit 3010801 QuoteMgt
{
    Permissions = TableData "Purchase Line" = rm,
                  TableData "Sales Shipment Line" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Sales Cr.Memo Line" = rm,
                  TableData "Purch. Rcpt. Line" = rm,
                  TableData "Sales Header Archive" = rimd,
                  TableData "Sales Line Archive" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text008: Label 'Recalculate\\Quote line   #1### of #2###';
        Text010: Label 'There are more end-totals than begin-totals.';
        Text011: Label 'Total ';
        Text012: Label 'There must be the same number of being-totals as end-totals. \Missing: %1 end-total(s).';
        Text014: Label '%1 recalculated.';

    procedure ReCalc(SalesHeader: Record "Sales Header"; ShowMessage: Boolean)
    var
        SalesLine: Record "Sales Line";
        xSalesLine: Record "Sales Line";
        Window: Dialog;
        BeginTotalTxt: array[99] of Text[250];
        ActualLevel: Integer;
        ActualTitle: array[99] of Integer;
        ActualOutline: Code[20];
        ActualPosition: Integer;
        SubTotalNet: array[99] of Decimal;
        SubTotalGross: array[99] of Decimal;
        Counter: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReCalc(SalesHeader, ShowMessage, IsHandled);
        if IsHandled then
            exit;
        // Init
        ActualLevel := 1;
        Clear(ActualTitle);
        Clear(ActualOutline);
        ActualPosition := 0;
        // Open Dialog
        Window.Open(Text008);
        Counter := 0;
        // Increment levels
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        Window.Update(2, SalesLine.Count);

        if SalesLine.FindSet() then
            repeat
                // Update dialog
                Counter := Counter + 1;
                Window.Update(1, Counter);
                // Calc level, indent etc.
                case SalesLine.Type of
                    SalesLine.Type::"Begin-Total":
                        begin
                            // Description
                            ActualTitle[ActualLevel] := ActualTitle[ActualLevel] + 1;
                            BeginTotalTxt[ActualLevel] := SalesLine.Description;
                            // Outline
                            CalcOutline(ActualLevel, ActualTitle, ActualOutline);
                            // Level
                            SalesLine.Level := ActualLevel;
                            ActualLevel := ActualLevel + 1;
                            // Recalc title
                            if ActualLevel > 1 then
                                SalesLine."Title No." := ActualTitle[ActualLevel - 1];
                            // Maybe set position to zero
                            // ActualPos := 0;
                            // SubTotal
                            SubTotalNet[ActualLevel] := 0;
                            SubTotalGross[ActualLevel] := 0;
                        end;
                    SalesLine.Type::"End-Total":
                        begin
                            // SubTotal
                            SalesLine."Subtotal Net" := SubTotalNet[ActualLevel];
                            SalesLine."Subtotal Gross" := SubTotalGross[ActualLevel];
                            if ActualLevel > 1 then begin
                                SubTotalNet[ActualLevel - 1] :=
                                  SubTotalNet[ActualLevel - 1] + SubTotalNet[ActualLevel];
                                SubTotalGross[ActualLevel - 1] :=
                                  SubTotalGross[ActualLevel - 1] + SubTotalGross[ActualLevel];
                            end;
                            // Recalc title
                            CalcTitle(ActualLevel, ActualTitle, SalesLine."Title No.");

                            ActualTitle[ActualLevel] := 0;
                            // Level
                            ActualLevel := ActualLevel - 1;
                            SalesLine.Level := ActualLevel;
                            if ActualLevel = 0 then
                                Error(Text010);
                            // Outline
                            CalcOutline(ActualLevel, ActualTitle, ActualOutline);
                            // Description
                            SalesLine.Description := Format(Text011 + BeginTotalTxt[ActualLevel], -MaxStrLen(SalesLine.Description));
                        end;
                    else
                        // SubTotal
                        if SalesLine."Quote Variant" <> SalesLine."Quote Variant"::Variant then begin
                            SubTotalNet[ActualLevel] := SubTotalNet[ActualLevel] + SalesLine."Line Amount";
                            SubTotalGross[ActualLevel] := SubTotalGross[ActualLevel] + SalesLine."Amount Including VAT";
                        end;
                        // Position
                        if SalesLine.HasTypeToFillMandatoryFields() and (SalesLine."No." <> '') then begin
                            ActualPosition := ActualPosition + 10;
                            SalesLine.Position := ActualPosition;
                        end;
                        // Level
                        if xSalesLine.Type = xSalesLine.Type::"End-Total" then
                            CalcOutline(ActualLevel - 1, ActualTitle, ActualOutline);
                        SalesLine.Level := ActualLevel;
                        // Recalc title
                        if ActualLevel > 1 then
                            SalesLine."Title No." := ActualTitle[ActualLevel - 1];
                end;
                // Fields that do not depend of the type
                SalesLine.Classification := ActualOutline;
                // write
                SalesLine.Modify();
                xSalesLine := SalesLine;
            until SalesLine.Next() = 0;
        // CHeck no of begin/end levels
        if ActualLevel > 1 then
            Error(Text012, ActualLevel - 1);
        // Close dialog
        Window.Close();

        if ShowMessage then
            Message(Text014, SalesHeader."Document Type");
    end;

    [Scope('OnPrem')]
    procedure CalcOutline(Level: Integer; Title: array[99] of Integer; var Outline: Code[20])
    var
        i: Integer;
    begin
        Outline := '';
        for i := 1 to Level do
            Outline := Outline + StrSubstNo('%1.', Title[i]);

        if Level > 1 then
            Outline := DelChr(Outline, '>', '.');
    end;

    [Scope('OnPrem')]
    procedure CalcTitle(Level: Integer; Title: array[99] of Integer; var TitleNo: Integer)
    begin
        if Level > 1 then
            TitleNo := Title[Level - 1];
    end;

    procedure RecalcPostedInvoice(SalesInvHeader: Record "Sales Invoice Header")
    var
        PostedInvLine: Record "Sales Invoice Line";
        xPostedInvLine: Record "Sales Invoice Line";
        Window: Dialog;
        BeginTotalTxt: array[99] of Text[250];
        ActualLevel: Integer;
        ActualTitle: array[99] of Integer;
        ActualOutline: Code[20];
        ActualPosition: Integer;
        SubTotalNet: array[99] of Decimal;
        SubTotalGross: array[99] of Decimal;
        Counter: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalcPostedInvoice(SalesInvHeader, IsHandled);
        if IsHandled then
            exit;

        ActualLevel := 1;
        Clear(ActualTitle);
        Clear(ActualOutline);
        ActualPosition := 0;
        // Open Dialog
        Window.Open(Text008);
        Counter := 0;
        // Increment levels
        PostedInvLine.SetRange("Document No.", SalesInvHeader."No.");

        Window.Update(2, PostedInvLine.Count);

        if PostedInvLine.FindSet() then
            repeat
                // Update dialog
                Counter := Counter + 1;
                Window.Update(1, Counter);
                // Calc level, indent etc.
                case PostedInvLine.Type of
                    PostedInvLine.Type::"Begin-Total":
                        begin
                            // Description
                            ActualTitle[ActualLevel] := ActualTitle[ActualLevel] + 1;
                            BeginTotalTxt[ActualLevel] := PostedInvLine.Description;
                            // Outline
                            CalcOutline(ActualLevel, ActualTitle, ActualOutline);
                            // Level
                            PostedInvLine."Quote-Level" := ActualLevel;
                            ActualLevel := ActualLevel + 1;
                            // Recalc title
                            if ActualLevel > 1 then
                                PostedInvLine."Title No." := ActualTitle[ActualLevel - 1];
                            // Maybe set position to zero
                            // ActualPos := 0;
                            // SubTotal
                            SubTotalNet[ActualLevel] := 0;
                            SubTotalGross[ActualLevel] := 0;
                        end;
                    PostedInvLine.Type::"End-Total":
                        begin
                            // SubTotal
                            PostedInvLine."Subtotal net" := SubTotalNet[ActualLevel];
                            PostedInvLine."Subtotal gross" := SubTotalGross[ActualLevel];
                            if ActualLevel > 1 then begin
                                SubTotalNet[ActualLevel - 1] :=
                                  SubTotalNet[ActualLevel - 1] + SubTotalNet[ActualLevel];
                                SubTotalGross[ActualLevel - 1] :=
                                  SubTotalGross[ActualLevel - 1] + SubTotalGross[ActualLevel];
                            end;
                            // Recalc title
                            CalcTitle(ActualLevel, ActualTitle, PostedInvLine."Title No.");

                            ActualTitle[ActualLevel] := 0;
                            // Level
                            ActualLevel := ActualLevel - 1;
                            PostedInvLine."Quote-Level" := ActualLevel;
                            if ActualLevel = 0 then
                                Error(Text010);
                            // Outline
                            CalcOutline(ActualLevel, ActualTitle, ActualOutline);
                            // Description
                            PostedInvLine.Description := Format(Text011 + BeginTotalTxt[ActualLevel], -MaxStrLen(PostedInvLine.Description));
                        end;
                    else
                        // SubTotal
                        SubTotalNet[ActualLevel] := SubTotalNet[ActualLevel] + PostedInvLine."Line Amount";
                        SubTotalGross[ActualLevel] := SubTotalGross[ActualLevel] + PostedInvLine."Amount Including VAT";
                        // Position
                        if (PostedInvLine.Type in [PostedInvLine.Type::"G/L Account", PostedInvLine.Type::Resource, PostedInvLine.Type::"Fixed Asset", PostedInvLine.Type::"Charge (Item)"]) and
                           (PostedInvLine."No." <> '')
                        then begin
                            ActualPosition := ActualPosition + 10;
                            PostedInvLine.Position := ActualPosition;
                        end;
                        // Level
                        if xPostedInvLine.Type = xPostedInvLine.Type::"End-Total" then
                            CalcOutline(ActualLevel - 1, ActualTitle, ActualOutline);
                        PostedInvLine."Quote-Level" := ActualLevel;
                        // Recalc title
                        if ActualLevel > 1 then
                            PostedInvLine."Title No." := ActualTitle[ActualLevel - 1];
                end;
                // Fields that do not depend of the type
                PostedInvLine.Classification := ActualOutline;
                // write
                PostedInvLine.Modify();
                xPostedInvLine := PostedInvLine;
            until PostedInvLine.Next() = 0;
        // CHeck no of begin/end levels
        if ActualLevel > 1 then
            Error(Text012, ActualLevel - 1);
        // Close dialog
        Window.Close();
    end;

    procedure RecalcPostedCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        PostedCredMemoLine: Record "Sales Cr.Memo Line";
        xPostedCredMemoLine: Record "Sales Cr.Memo Line";
        Window: Dialog;
        BeginTotalTxt: array[99] of Text[250];
        ActualLevel: Integer;
        ActualTitle: array[99] of Integer;
        ActualOutline: Code[20];
        ActualPosition: Integer;
        SubTotalNet: array[99] of Decimal;
        SubTotalGross: array[99] of Decimal;
        Counter: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalcPostedCreditMemo(SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        ActualLevel := 1;
        Clear(ActualTitle);
        Clear(ActualOutline);
        ActualPosition := 0;
        // Open Dialog
        Window.Open(Text008);
        Counter := 0;
        // Increment levels
        PostedCredMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");

        Window.Update(2, PostedCredMemoLine.Count);
        // Increment levels
        PostedCredMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if PostedCredMemoLine.FindSet() then
            repeat
                // Update dialog
                Counter := Counter + 1;
                Window.Update(1, Counter);
                // Calc level, indent etc.
                case PostedCredMemoLine.Type of
                    PostedCredMemoLine.Type::"Begin-Total":
                        begin
                            // Description
                            ActualTitle[ActualLevel] := ActualTitle[ActualLevel] + 1;
                            BeginTotalTxt[ActualLevel] := PostedCredMemoLine.Description;
                            // Outline
                            CalcOutline(ActualLevel, ActualTitle, ActualOutline);
                            // Level
                            PostedCredMemoLine."Quote-Level" := ActualLevel;
                            ActualLevel := ActualLevel + 1;
                            // Recalc title
                            if ActualLevel > 1 then
                                PostedCredMemoLine."Title No." := ActualTitle[ActualLevel - 1];
                            // SubTotal
                            SubTotalNet[ActualLevel] := 0;
                            SubTotalGross[ActualLevel] := 0;
                        end;
                    PostedCredMemoLine.Type::"End-Total":
                        begin
                            // SubTotal
                            PostedCredMemoLine."Subtotal net" := SubTotalNet[ActualLevel];
                            PostedCredMemoLine."Subtotal gross" := SubTotalGross[ActualLevel];
                            if ActualLevel > 1 then begin
                                SubTotalNet[ActualLevel - 1] :=
                                  SubTotalNet[ActualLevel - 1] + SubTotalNet[ActualLevel];
                                SubTotalGross[ActualLevel - 1] :=
                                  SubTotalGross[ActualLevel - 1] + SubTotalGross[ActualLevel];
                            end;
                            // Recalc title
                            CalcTitle(ActualLevel, ActualTitle, PostedCredMemoLine."Title No.");

                            ActualTitle[ActualLevel] := 0;
                            // Level
                            ActualLevel := ActualLevel - 1;
                            PostedCredMemoLine."Quote-Level" := ActualLevel;
                            if ActualLevel = 0 then
                                Error(Text010);
                            // Outline
                            CalcOutline(ActualLevel, ActualTitle, ActualOutline);
                            // Description
                            PostedCredMemoLine.Description := Format(Text011 + BeginTotalTxt[ActualLevel], -MaxStrLen(PostedCredMemoLine.Description));
                        end;
                    else
                        // SubTotal
                        SubTotalNet[ActualLevel] := SubTotalNet[ActualLevel] + PostedCredMemoLine.Amount;
                        SubTotalGross[ActualLevel] := SubTotalGross[ActualLevel] + PostedCredMemoLine."Amount Including VAT";
                        // Position
                        if (PostedCredMemoLine.Type in [PostedCredMemoLine.Type::"G/L Account", PostedCredMemoLine.Type::Resource, PostedCredMemoLine.Type::"Fixed Asset", PostedCredMemoLine.Type::"Charge (Item)"]) and
                           (PostedCredMemoLine."No." <> '')
                        then begin
                            ActualPosition := ActualPosition + 10;
                            PostedCredMemoLine.Position := ActualPosition;
                        end;
                        // Level
                        if xPostedCredMemoLine.Type = xPostedCredMemoLine.Type::"End-Total" then
                            CalcOutline(ActualLevel - 1, ActualTitle, ActualOutline);
                        PostedCredMemoLine."Quote-Level" := ActualLevel;
                        // Recalc title
                        if ActualLevel > 1 then
                            PostedCredMemoLine."Title No." := ActualTitle[ActualLevel - 1];
                end;
                // Fields that do not depend of the type
                PostedCredMemoLine.Classification := ActualOutline;
                // write
                PostedCredMemoLine.Modify();
                xPostedCredMemoLine := PostedCredMemoLine;
            until PostedCredMemoLine.Next() = 0;
        // CHeck no of begin/end levels
        if ActualLevel > 1 then
            Error(Text012, ActualLevel - 1);
        // Close dialog
        Window.Close();
    end;

    procedure RecalcDocOnPrinting(SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalcDocOnPrinting(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if (SalesHeader."Document Type" in [SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order]) and
           SalesSetup."Automatic recalculate Quotes"
        then begin
            ReCalc(SalesHeader, false);
            Commit();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReCalc(var SalesHeader: Record "Sales Header"; ShowMessage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalcPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalcPostedCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalcDocOnPrinting(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

