// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.History;
using System.Search;

page 6157 "E-Doc Purch. Search History"
{
    PageType = List;
    ApplicationArea = All;
    SourceTableTemporary = true;
    SourceTable = "Purch. Inv. Line";
    SourceTableView = sorting("Search Similarity Score") order(descending);
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(SearchFields)
            {
                ShowCaption = false;
                field(DescriptionText; DescriptionText)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the e-document purchase line history record.';
                    Editable = true;

                    trigger OnValidate()
                    begin
                        SearchAndFillPart();
                    end;

                }
            }
            repeater(Lines)
            {
                Editable = false;
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the document number of the purchase invoice line.';
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the type of the purchase invoice line.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the purchase invoice line.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the purchase invoice line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the quantity of the purchase invoice line.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ToolTip = 'Specifies the unit of measure of the purchase invoice line.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ToolTip = 'Specifies the direct unit cost of the purchase invoice line.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the amount of the purchase invoice line.';
                }
                field("Search Similarity Score"; Rec."Search Similarity Score")
                {
                    ToolTip = 'Specifies the similarity score of the e-document purchase line search result.';
                    StyleExpr = StyleTxt;
                }
            }
        }
    }

    var
        DescriptionText: Text;
        StyleTxt: Text;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.GetStyle();
    end;

    trigger OnOpenPage()
    begin
        if DescriptionText <> '' then
            SearchAndFillPart();
    end;

    internal procedure SetDescription(Text: Text)
    begin
        DescriptionText := Text;
    end;

    local procedure SearchAndFillPart()
    var
        TempPurchInvLine: Record "Purch. Inv. Line" temporary;
        PurchInvLine: Record "Purch. Inv. Line";
        TempResultTable: Record "Data Similarity Result" temporary;
        SemanticDataSearch: Codeunit "Semantic Data Search";
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(PurchInvLine);
        SemanticDataSearch.SetSearchTarget(RecordRef);
        if not SemanticDataSearch.FindSimilar(DescriptionText, TempResultTable) then
            exit;

        TempPurchInvLine.DeleteAll();
        if TempResultTable.FindSet() then
            repeat
                PurchInvLine.GetBySystemId(TempResultTable."System ID");
                TempPurchInvLine := PurchInvLine;
                TempPurchInvLine."Search Similarity Score" := TempResultTable.Similarity;
                Rec := TempPurchInvLine;
                if Rec.Insert() then;
            until TempResultTable.Next() = 0;

    end;

}